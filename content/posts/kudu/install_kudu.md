---
title: "[Kudu] 3. Source Build를 이용한 설치"
date: 2019-12-04T16:52:07+09:00
draft: false
toc: false
images:
tags: [kudu]
---

kudu를 설치하는 방법은 cloudera repository를 이용하여 설치하는 방법이 있고, source build를 통해 설치하는 방법이 있는데, cloudera 버전은 라이센스 관련 이슈가 있어서, 사용에 문제가 없는 source build 버전을 통해 설치해보려고 한다.

## 설치환경
* CentOS 7.6

### 1. 필수 라이브러리 설치
```bash
$ sudo yum install -y autoconf automake cyrus-sasl-devel cyrus-sasl-gssapi \
  cyrus-sasl-plain flex gcc gcc-c++ gdb git java-1.8.0-openjdk-devel \
  krb5-server krb5-workstation libtool make openssl-devel patch \
  pkgconfig redhat-lsb-core rsync unzip vim-common which
```

### 2. (Optional) Kudu NVM 사용을 위한 라이브러리 설치
Kudu의 [NVM(비휘발성 메모리)](https://ko.wikipedia.org/wiki/%EB%B9%84%ED%9C%98%EB%B0%9C%EC%84%B1_%EB%A9%94%EB%AA%A8%EB%A6%AC) 블록 캐시를 지원하려면 memkind 라이브러리를 설치해야한다.

```bash
$ sudo yum install -y memkind
```

### 3. Kudu Source Clone
[Kudu Release](https://github.com/apache/kudu/releases)에서 버전을 확인한 후, git clone시 버전을 지정하여 clone 한다.

```bash
$ git clone -b 1.11.1 https://github.com/apache/kudu kudu-1.11.1
$ cd kudu-1.11.1
```

### 4. build-if-necessary.sh를 이용한 third-party requirements 빌드
```bash
$ build-support/enable_devtoolset.sh thirdparty/build-if-necessary.sh
```

### 5. Kudu Build And Install
```bash
$ mkdir -p build/release

$ cd build/release

$ ../../thirdparty/installed/common/bin/cmake \
  -DNO_TESTS=1 \
  -DCMAKE_BUILD_TYPE=release ../..

$ make -j4
$ sudo make install
```

### 6-1. Kudu Master 실행
```bash
## 공통
$ sudo mkdir /etc/kudu
$ sudo vi /etc/kudu/master.gflagfile

## 추가 설정은 https://kudu.apache.org/docs/configuration_reference.html#kudu-master_supported 에서 확인
--rpc_bind_addresses=0.0.0.0:7051
--fs_wal_dir=/var/lib/kudu/master
--fs_data_dirs=/var/lib/kudu/master
--log_dir=/var/log/kudu
--webserver_doc_root={KUDU git clone path}/www

##wal dir, data dir, log dir에 권한이 필요하면 chown으로 권한 변경

## kudu master 실행후 http://master-host:8051로 접속
$ nohup kudu-master --flagfile=/etc/kudu/master.gflagfile > /dev/null 2>&1 &
```
### 6-2. Kudu Tablet Server 실행
```bash
## 공통
$ sudo mkdir /etc/kudu
$ sudo vi /etc/kudu/tserver.gflagfile

## 추가 설정은 https://kudu.apache.org/docs/configuration_reference.html#kudu-tserver_supported 에서 확인
--rpc_bind_addresses=0.0.0.0:7051
--fs_wal_dir=/var/lib/kudu/tserver
--fs_data_dirs=/var/lib/kudu/tserver
--log_dir=/var/log/kudu
--tserver_master_addrs=${kudu master}:7051

##wal dir, data dir, log dir에 권한이 필요하면 chown으로 권한 변경

$ nohup kudu-tserver --flagfile=/etc/kudu/tserver.gflagfile> /dev/null 2>&1 &
```
