---
title: "Azkaban 설치"
date: 2019-10-31T18:11:20+09:00
draft: true
toc: false
images:
tags: 
  - azkaban
---

### 준비 1. OpenJDK 설치
```bash
$ sudo yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel
$ readlink /etc/alternatives/java ##java 위치 확인
/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-1.el7_7.x86_64/jre/bin/java

## 위 경로중 jre까지의 경로로 JAVA_HOME 환경변수를 잡아준다.
$ echo 'export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-1.el7_7.x86_64/jre"' >> ~/.bash_profile
$ echo 'export PATH=$PATH:$JAVA_HOME/bin:' >> ~/.bash_profile
$ source ~/.bash_profile

```

### 준비 2. JavaFX 설치
Azkaban은 JavaFX 모듈의 클래스를 일부를 사용한다. 그렇기 때문에 JavaFX를 설치해 주어야 하는데, Oralce JDK는 JavaFX가 기본적으로 포함이 되어서 JavaFX를 설치 하지 않아도 되지만, OpenJDK는 JavaFX 모듈이 빠져있어, 추가적으로 설치해줘야 한다.

1. https://gluonhq.com/products/javafx/ 에서 JavaFX Linux SDK LTS 버전 다운로드(현재 11.0.4 버전)
2. 아래의 커맨드를 이용하여 JavaFX모듈 복사
```bash
$ unzip openjfx-11.0.2_linux-x64_bin-sdk.zip
$ cd javafx-sdk-11.0.1
$ sudo cp -arf lib/* ${JAVA_HOME}/lib/
```

## Azkaban 설치
```bash
$ git clone https://github.com/azkaban/azkaban.git
$ cd azkaban

##외부 네트웍이 차단되어있다면 gradle.properties를 수정하여 외부 접근 가능하도록 proxy 설정
$ vi gradle.properitese
systemProp.http.proxyHost=proxy.proxy.com
systemProp.http.proxyPort=8888
systemProp.https.proxyHost=proxy.proxy.com
systemProp.https.proxyPort=8888

$ ./gradlew clean
$ ./gradlew build installDist -x test
```
