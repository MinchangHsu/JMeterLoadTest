#!/bin/bash

# 启动 SSH 服务
service ssh restart


# 保持容器运行
tail -f /dev/null
