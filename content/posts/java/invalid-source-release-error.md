---
title: "[Java] invalid source release 에러 해결"
date: 2020-01-02T10:21:11+09:00
draft: false
toc: false
images:
tags: ["Java", "Maven", "IntelliJ"]
---

> Error:java: invalid source release: 11

프로젝트를 진행하다보면 위와같은 에러를 보일때가 있는데, Intellij의 설정을 수정하여 해결할 수 있다.

## 1. Language Level 수정

Intellij에서 `File -> Project Structure -> Project Settings -> Project` 메뉴의 `Project Language Level` 을 수정한다

![error1](error1.png)

그리고 `File -> Project Structure -> Project Settings -> Modules` 메뉴의 `Source Language Level`을 수정한다.

![error2](error2.png)

## 2. Java Compiler 수정

Intellij에서 `Preference -> Build,Execution,Deployment -> Compiler -> Java Compiler`의 `Target bytescode version`을 수정해준다.

![error3](error3.png)


## 3. Maven 설정 추가

위와 같이 수정을 하면 동작을 하는데, 빌드를 수행하거나, 메이븐 설정이 변경되어 내부적으로 refresh가 되는경우 위의 모든 설정이 초기값으로 변경된다. 이때는 maven에 설정을 통해 버전을 지정해 줄 수 있다.

방법 1. properties 수정
```xml
<project>
  [...]
  <properties>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
  </properties>
  [...]
</project>
```

방법 2. maven-compiler-plugin에 버전 지정
```xml
<project>
  [...]
  <build>
    [...]
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.8.1</version>
        <configuration>
          <source>1.8</source>
          <target>1.8</target>
        </configuration>
      </plugin>
    </plugins>
    [...]
  </build>
  [...]
</project>
```
