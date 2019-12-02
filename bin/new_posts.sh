#!/bin/bash

if [ -z "$1" ]; then
    echo -e "파라미터로 포스트명 전달해주세요. ex) airflow/sample"
    exit 1
fi

BIN_PATH=$(cd "$(dirname "$0")" && pwd)

cd $BIN_PATH/..

hugo new posts/$1.md
