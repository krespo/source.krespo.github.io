---
title: "[Sqoop] Parameter 'directory' is not a directory 에러 해결하기"
date: 2020-02-10T17:33:42+09:00
draft: false
toc: false
images:
tags:
  - sqoop
  - hadoop
---

`.bash_profile` 이나 `${SQOOP_HOME}/conf/sqoop_env.sh`에 `HADOOP_MAPRED_HOME` 환경변수를 지정했음에도 계속 아래와 같이 HADOOP_MAPRED_HOME을 /usr/lib/hadoop-mapreduce의 경로에서 읽어 에러가 발생한다.

```
20/02/10 17:41:18 INFO orm.CompilationManager: HADOOP_MAPRED_HOME is /usr/lib/hadoop-mapreduce
20/02/10 17:41:18 ERROR tool.ImportTool: Import failed: Parameter 'directory' is not a directory
```

# 해결 1 : hadoop-mapred-home 파라미터 설정

```bash
sqoop import \
--hadoop-mapred-home ${HADOOP_HOME}/share/hadoop/mapreduce \  ##파라미터 추가
--connect "jdbc:mysql://111.111.111.111:3306/dev" \
--username xx \
--password xx \
--table log \
--target-dir "hdfs://xxx/sample" \
-m 1
```

# 해결 2 : /usr/lib/hadoop-mapreduce 심볼릭 링크 생성
```bash
## 심볼릭링크 생성
sudo ln -s /usr/lib/hadoop-mapreduce ${HADOOP_HOME}/share/hadoop/mapreduce

## SQOOP 실행
sqoop import \
--connect "jdbc:mysql://111.111.111.111:3306/dev" \
--username xx \
--password xx \
--table log \
--target-dir "hdfs://xxx/sample" \
-m 1
```
