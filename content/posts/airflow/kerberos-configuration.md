---
title: "2. airflow 커버로스 설정"
date: 2019-11-04T16:05:44+09:00
draft: false
toc: false
images:
tags: [airflow, workflow, kerberos]
---


airflow를 이용하여 kerberos 인증이 적용된 데이터소스(ex - hadoop)에 접근하려면 커버로스 설정을 airflow에 적용해야 한다.
아래의 예제는 kerberos 인증이 적용된 hive에 접근하는 방법을 작성해 보고자 한다. 

## 1. 커버로스 설정

커버로스 연동은 id/pw를 통해서 연동할 수도 있지만, 아래의 설정은 keytab 파일을 가지고 설정하는 방법을 다룬다.

```bash
$ cd $AIRFLOW_HOME
$ pip3 install apache-airflow[hive]==1.10.5
$ pip3 install thrift_sasl cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-md5 cyrus-sasl-plain

$ vi airflow.cfg
security = kerberos

## kerberos 항목에 principal, keytab을 설정한다.
[kerberos]
ccache = /tmp/airflow_krb5_ccache
# gets augmented with fqdn
principal = xxxx@DOMAIN
reinit_frequency = 3600
kinit_path = kinit
keytab = /{keytabfile위치}/xxxx.keytab


## 커버로스 인증을 하기위한 설정을 수정한다. 내용은 커버로스인증마다/회사마다 다르기 때문에 각자 알맞게 수정한다.
$ sudo vi /etc/krb5.conf


## 커버로스 인증을 계속 유지해야 하기 때문에 백그라운드에서 티켓을 갱신할 airflow 모듈을 실행한다.
$ nohup airflow kerberos > /dev/null 2>&1 &
```

## 2. airflow connection 설정

airflow에서는 데이터소스에 접근할때 직접 DAG나 파이선코드에 커넥션 정보를 넣어 동작시킬수 있지만, connection 정보를 웹에서 관리하고, 등록된 ID를 통해 DAG나 파이썬 파일에서 간단하게 접근이 가능하다.
설정은 airflow web -> admin -> connection -> Create 에서 가능하며 아래와 같이 등록한다.

![airflow connection](airflow-connection.png)

이때 `Conn Id`가 중요하며, DAG에서 해당 아이디로 커넥션 정보를 바로 가져올 수 있다.


## 3. airflow DAG 설정
아래의 코드는 [airflow hook](https://airflow.apache.org/concepts.html#hooks) 을 이용하여 hive에 쿼리를 날리는 예제이다.
Hook은 외부 플랫폼이나 DB에 접근하기 쉽도록 커넥션/릴리즈 같은 역할들을 대신해주는 것으로 해당 hook에 Connection ID만 전달하면 아무작업도 하지 않고 커넥션을 맺고 사용할수 있도록 도와준다.

```python 
from airflow import DAG
from datetime import datetime, timedelta
from airflow.hooks.hive_hooks import *
from airflow.operators.python_operator import PythonOperator


default_args = {
    'start_date': datetime(2015, 12, 1),
    'retries': 0,
    'catchup': False,
    'retry_delay': timedelta(minutes=5),
    # 'queue': 'bash_queue',
    # 'pool': 'backfill',
    # 'priority_weight': 10,
    # 'end_date': datetime(2016, 1, 1),
}

### hiveserver2_conn_id에 위에서 설정한 conn_id를 입력해 준다.
def simple_query():
    hm = HiveServer2Hook(hiveserver2_conn_id="###")
    print("=====================> connection")
    result = hm.get_records("select 1 ", "default")
    print(result)
    print("정상 종료!!")


dag = DAG('tutorial_hive', default_args=default_args, schedule_interval="@once")

# t1, t2 and t3 are examples of tasks created by instantiating operators
t1 = PythonOperator(
    task_id='execute_hive',
    provide_context=False,
    python_callable=simple_query,
    dag=dag,
)
```

위의 파이썬 파일을 dags에 복사하여 넣고 동작시켜보면 정상적으로 결과를 가져오는 것을 볼수 있다.
