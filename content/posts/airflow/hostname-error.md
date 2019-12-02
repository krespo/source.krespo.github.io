---
title: "[Airflow] macOS catalina에서 hostname does not match this instance's hostname 해결하기"
date: 2019-11-11T16:34:10+09:00
draft: false
toc: false
images:
tags: [airflow, workflow]
---

얼마전 `macOS Catalina`버전으로 업그레이드 되면서 로컬에서 airflow가 정상적으로 동작하지 않는 문제가 생겼다.

> The recorded hostname [1m1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa[0m does not match this instance's hostname [1m1.0.0.127.in-addr.arpa

위의 에러 메세지를 기준으로 airflow 코드를 들여다 보기로 했다.

```python
##  airflow/jobs/local_task_job.py
def heartbeat_callback(self, session=None):
    """Self destruct task if state has been moved away from running externally"""

    if self.terminating:
        # ensure termination if processes are created later
        self.task_runner.terminate()
        return

    self.task_instance.refresh_from_db()
    ti = self.task_instance

    fqdn = get_hostname()
    same_hostname = fqdn == ti.get_hostname                               ## <==== 여기에서 문제 발생
    same_process = ti.pid == os.getpid()

    if ti.state == State.RUNNING:
        if not same_hostname:
            self.log.warning("The recorded hostname %s "
                             "does not match this instance's hostname "
                             "%s", ti.hostname, fqdn)
            raise AirflowException("Hostname of job runner does not match")
```

위의 코드에서 보면 `ti.get_hostname` 의 값과 `get_hostname()` 으로 얻어진 fqdn의 값이 달라 에러가 발생하는것으로 보였다.

get_hostname()을 따라가 보면 
```python
## airflow/utils/net.py

def get_hostname():
    """
    Fetch the hostname using the callable from the config or using
    `socket.getfqdn` as a fallback.
    """
    # First we attempt to fetch the callable path from the config.
    try:
        callable_path = conf.get('core', 'hostname_callable')			## <== airflow.cfg에서 hostname_callable 설정값을 읽는다.
    except AirflowConfigException:
        callable_path = None

    # Then we handle the case when the config is missing or empty. This is the
    # default behavior.
    if not callable_path:
        return socket.getfqdn()

    # Since we have a callable path, we try to import and run it next.
    module_path, attr_name = callable_path.split(':')
    module = importlib.import_module(module_path)
    callable = getattr(module, attr_name)
    return callable()
```
코드를 보면 airflow.cfg 파일에 `hostname_callable`이란 설정값을 읽어 모듈을 로드하여 호스트명을 얻는것으로 보인다.

airflow.cfg 파일을 엵어보면 기본으로 `socket.getfqdn`을 읽어 호스트명을 가져오는것을 볼수 있다.
```
# Hostname by providing a path to a callable, which will resolve the hostname
# The format is "package:function". For example,
# default value "socket:getfqdn" means that result from getfqdn() of "socket" package will be used as hostname
# No argument should be required in the function specified.
# If using IP address as hostname is preferred, use value "airflow.utils.net:get_host_ip_address"
hostname_callable = socket:getfqdn
```

즉 `socket.getfqdn`을 호출시 macOS 카탈리나 이전버전에서는 문제 없이 가져오던 부분이 os가 버전 업데이트 되면서 문제가 발생한것으로 보인다.
그래서 설정파일에서 예시로 보여준것처럼 `airflow.utils.net:get_host_ip_address`를 사용해 보려고 했지만 에러가 발생했다.

결론적으로

> ip나 hostname을 가져오는 커스텀 코드를 작성하여 hostname_callable에 등록

하는 식으로 처리하기로 했다.

### 1. ${AIRFLOW_HOME}/custom 디렉토리 생성 후 하위에 `net_utiles.py`를 생성
```python
'''
아래의 경로에 저장
${AIRFLOW_HOME}/custom/__init__.py
					  /net_utils.py

'''
import socket


def get_hostname():
    return socket.gethostbyname(socket.gethostname())

```

### 2. `setuptools`를 이용하여 모듈 등록

${AIRFLOW_HOME}/setup.py 생성
```python
from setuptools import setup, find_packages

setup(
    name='airflow',
    version='1.0',
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False
)
```
find_packages를 통해 1에서 생성한 custom 폴더를 접근할수 있도록 변경해 준다.

그후 
```python
$ python setup.py install
```
을 실행하여 커스텀 코드를 PYTHONPATH에 추가해준다.

### 3. airflow.cfg에 `hostname_callable` 수정
```
#hostname_callable = socket:getfqdn
hostname_callable = custom.net_utils:get_hostname
```

위와 같이 설정 후 webserver, scheduler를 재실행 하면 ip4 기반으로 작동시킬 수 있다.