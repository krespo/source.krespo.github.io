---
title: "[Kafka Manager] 1.Installation"
date: 2019-12-10T14:31:31+09:00
draft: false
toc: false
images:
tags:
  - kafka
  - kafka-manager
---

yahoo에서 만든 [kafka-manager](https://github.com/yahoo/kafka-manager)를 이용하면 카프카 운영을 위한 다양한 일들을 Web UI기반으로 처리할 수 있다.

## 설치

```bash
## https://github.com/yahoo/kafka-manager/releases 에서 원하는 버전을 확인하고 -b 파라미터로 버전을 넘겨준다.
## 실제 실행파일은 해당 소스를 빌드한 후 생성이 됨으로 아래의 git clone은 아무 위치에서 실행해도 상관없다.
$ git clone -b 2.0.0.2 https://github.com/yahoo/kafka-manager.git
$ cd kafka-manager
## 아래의 명령어로 빌드를 하면 target/universal 하위에 zip파일로 빌드파일이 생성된다.
$ ./sbt clean dist

$ mv ./target/universal/kafka-manager-2.0.0.2.zip {설치하고자 하는 디렉토리}
$ cd {설치하고자 하는 디렉토리}
$ unzip kafka-manager-2.0.0.2.zip
```

## 설정
```bash
$ vi conf/application.conf

### zookeeper 호스트를 지정해줌
### 아래와 같이 설정하면 zk_host:2181/kafka-manager 라는 노드가 생성되고, 해당 노드에 kafka manager 사용에 따른 각종 state가 저장된다.
### 이때 kafka-manager 노드는 자동생성이 된다.
### 만약 zk_host:2181/kafka-manager-2.0.0.2와 같이 depth가 추가가 되면 kafka manager는 해당 노드를 생성해 주지 않기 때문에 kafka-manager-2.0.0.2 노드는 직접 수동으로 만들어 줘야 한다.
### ex) zkCli.sh create /kafka-manager-2.0.0.2 ''
kafka-manager.zkhosts=“zk_host:2181”
```

## 실행
```bash
## foreground
bin/kafka-manager

## background
background nohup ./bin/kafka-manager > /dev/null 2>&1 &
```
