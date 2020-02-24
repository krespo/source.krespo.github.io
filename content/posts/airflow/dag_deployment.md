---
title: "[Airflow] Multi Server Cluster 환경에서 dag 파일은 모든 서버에 배포해야할까?"
date: 2020-02-24T16:47:18+09:00
draft: false
toc: false
images:
tags:
  - airflow
---

오늘은 Multi Server Cluster 환경에서 dag를 배포하는것에 대해 이야기를 해보려고한다.

얼마전에 블로그 댓글을 통해 이런 문의가 왔었다.

> Master 역할을 하는 서버에만 dag를 배포하고, 이를 통해 Worker에 dag 파일을 전달하는 방식으로 dag를 수행할수 있습니까?

답변으로 간단하게 `불가`함을 적었었는데, 오늘은 조금더 상세히 남겨보려고한다.

일단 좀더 상세한 로그를 확인하려면 `airflow.cfg`의 로그레벨 설정항목인 `logging_level = INFO` 로 설정을 한뒤, scheduler.log 파일을 훑어보면 아래와 같은 로그가 남겨진다.

```
[2020-02-12 15:12:17,513] {base_executor.py:59} INFO - Adding to queue: ['airflow', 'run', 'test_task', 'custom_opeartor', '2019-12-31T15:00:00+00:00', '--local', '--pool', 'default_pool', '-sd', '/.../TestSqoopOperator.py']
[2020-02-12 15:12:17,514] {celery_executor.py:45} INFO - Executing command in Celery: ['airflow', 'run', 'test_task', 'custom_opeartor', '2019-12-31T15:00:00+00:00', '--local', '--pool', 'default_pool', '-sd', '/.../TestSqoopOperator.py']
```

Adding to queue 로그는 레빗엠큐나 레디스 큐에 넣어주는 정보이고, Executing command 는 실제 worker가 잡을 할당받아 수행하게 되는 정보를 나타낸다.

한눈에 보면 알겠지만 -sd라는 파라미터로 실제 수행하고자 하는 dag파일의 위치가 문자형으로 넘어가게 된다.

이를 통해 수행되는 코드는 아래와 같다.

```python
## celery_executor.py

@app.task
def execute_command(command_to_exec):
    log = LoggingMixin().log
    log.info("Executing command in Celery: %s", command_to_exec)
    env = os.environ.copy()
    try:
        subprocess.check_call(command_to_exec, stderr=subprocess.STDOUT,
                              close_fds=True, env=env)
    except subprocess.CalledProcessError as e:
        log.exception('execute_command encountered a CalledProcessError')
        log.error(e.output)

        raise AirflowException('Celery command failed')
```

코드를 확인해보면 큐에서 전달받은 데이터를 통해 subprocess 모듈을 이용하여 파이썬 파일을 실행하는것을 볼수 있다.

즉 dag를 실행하려면 master에만 dag를 배포하면 안되고, airflow를 구성하고 있는 모든서버의 `동일한 위치, 동일한 이름`으로 dag 파일이 존재하여야 실행된다는것을 알수 있다.
