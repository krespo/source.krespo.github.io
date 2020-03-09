---
title: "[Kudu]Kudu와 Presto 그리고 unix_timestamp에 대해 이해하기"
date: 2020-03-03T16:19:21+09:00
draft: false
tags: [kudu, presto]
---

Kudu 공식 문서에도 나와있지만 Kudu에서 주로 사용하는 쿼리엔진은 Impala나 Hive다. 
하지만 필자는 이미 사용하고 있는 Presto 클러스터가 있어 [Presto-Kudu Connector](https://prestodb.io/docs/current/connector/kudu.html) 를 이용하여 Kudu에 쿼리를 수행하고 있었는데, Kudu의 `unixtime_micros` 타입의 컬럼이 계속 헷갈려 여러가지 테스트를 수행해 보았다. 
이 포스팅은 그 테스트 과정 및 결과에 대한 이야기이다.

## Kudu에 데이터를 넣을때 KST(UTC+9) 시간을 UTC로 변경해서 넣어야 할까?
사실 많은 개발자들이 알고있듯, [유닉스_시간](https://ko.wikipedia.org/wiki/%EC%9C%A0%EB%8B%89%EC%8A%A4_%EC%8B%9C%EA%B0%84)은 1970년 1월1일 부터 현재까지의 시간을 정수형으로 나타낸 값이다. Kudu에도 시간을 나타내는 컬럼인 `unixtime_micros` 타입의 컬럼로 이 유닉스 타임을 저장하기 위한 컬럼이다.

유닉스 시간에 대한 별다른 이해 없이, KST 시간을 kudu의 unixtime_micros에 저장하려면 KST->UTC->epoch시간 으로 변경해야 한다고 생각했다.

```java
LocalDateTime currentTime = LocalDateTime.now();
ZonedDateTime utcTime = currentTime.atZone(ZoneId.of("Asia/Seoul")).withZoneSameInstant(ZoneId.of("UTC"));

System.out.println("KST Time : " + currentTime);
System.out.println("UTC Time : " + utcTime);
System.out.println("KST epoch Time : " + currentTime.toEpochSecond(ZoneOffset.of("+09:00")));
System.out.println("UTC epoch Time : " + utcTime.toEpochSecond());

//출력 결과
//KST Time : 2020-03-09T14:11:33.564
//UTC Time : 2020-03-09T05:11:33.564Z[UTC]
//KST epoch Time : 1583730693
//UTC epoch Time : 1583730693
```
그런데 위의 샘플 코드에서 보면 알겠지만, KST 시간을 UTC로 변경해도 epoch time은 값이 변하지 않았다. 

왜냐하면 유닉스 시간(epoch time)은 UTC 시간 기준이기 때문에 변경하고자 하는 시간의 timezone이 어찌되었던 항상 UTC 기준의 값을 돌려줌으로, *KST 시간을 kudu에 저장할때 굳이 UTC로 timezone을 변경할 필요가 없다.*

## Presto에서는 왜 저장한 시간의 +9시간이 추가되어 검색될까?

Presto를 이용하기 위한 방법으로는 presto-cli를 이용하는 방법과 Presto JDBC를 이용하여 쿼리를 수행하는 방법 두가지가 있다.
그런데 위 두가지의 경우 모두 `unixtime_micros` 컬럼을 UTC에서 KST로 자동으로 변경된 값으로 변경이 된다.

이는 presto-cli, jdbc 모두 로컬 환경의 기본 timezone을 따라가기 때문이다.

#### presto-cli
```
presto> select current_time();
   _col0
--------------
  Asia/Seoul
(1 row)
```

#### presto-jdbc 
```java
//https://github.com/prestosql/presto/blob/master/presto-jdbc/src/main/java/io/prestosql/jdbc/PrestoConnection.java
PrestoConnection(PrestoDriverUri uri, QueryExecutor queryExecutor)
            throws SQLException
    {
        requireNonNull(uri, "uri is null");
        this.jdbcUri = uri.getJdbcUri();
        this.httpUri = uri.getHttpUri();
        this.schema.set(uri.getSchema());
        this.catalog.set(uri.getCatalog());
        this.user = uri.getUser();
        this.applicationNamePrefix = uri.getApplicationNamePrefix();
        this.extraCredentials = uri.getExtraCredentials();
        this.queryExecutor = requireNonNull(queryExecutor, "queryExecutor is null");
        uri.getClientTags().ifPresent(tags -> clientInfo.put("ClientTags", tags));

        roles.putAll(uri.getRoles());
        timeZoneId.set(ZoneId.systemDefault());
        locale.set(Locale.getDefault());
        sessionProperties.putAll(uri.getSessionProperties());
    }
```

이렇게 로컬 시스템의 기본 timezone 설정을 통해 timezone이 세팅되기 때문에 유닉스 타임의 컬럼이더라도 자동으로 KST 시간으로 변경되어 검색이 된다.

## 어플리케이션에서 UTC 기준의 시간으로 나타내려면?

prest-jdbc 에서는 PrestoConnection.setTimezone 메소드를 호출하여 Timezone을 설정할 수 있다.







