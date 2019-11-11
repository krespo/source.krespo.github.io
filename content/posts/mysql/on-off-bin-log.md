---
title: "Mysql 바이너리로그 끄고 켜기"
date: 2019-11-07T13:50:51+09:00
draft: false
tags: ["mysql", "bin-log"]
---

바이너리 로그는 master-slave 구성을 하거나, [CDC](https://en.wikipedia.org/wiki/Change_data_capture)를 할 때 사용하는데, 상황에 따라서 enable/disable 해야할 이슈가 있어 기록차원에서 남겨본다.

## 1.bin-log on
```bash
$ vi /etc/my.cfg

[mysqld]
log-data=/data1/mysql/,ysql-bin

$ sudo service mysql restart
```

## 2.bin-log off

```bash
$ vi /etc/my.cfg

##주석처리
[mysqld]
#log-data=/data1/mysql/,ysql-bin
$ sudo service mysql restart
```
