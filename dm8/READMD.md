# DM8达梦数据库

官网：https://www.dameng.com/DM8.html

1. https://hub.docker.com/r/sizx/dm8

## 账户
- 默认账户：SYSDBA
- 密码：123abc!@#

# X86架构
## 官方镜像
```bash
docker run -d -p 5236:5236 --name dm8 \
--restart=always --privileged=true \
-e PAGE_SIZE=16 \
-e UNICODE_FLAG=1 \
-e LENGTH_IN_CHAR=1 \
-e CASE_SENSITIVE=0 \
-e SYSDBA_PWD='123abc!@#' \
-e LD_LIBRARY_PATH=/opt/dmdbms/bin \
-e INSTANCE_NAME=dm8_instance \
-v /opt/dm8:/opt/dmdbms/data \
sizx/dm8:1-2-128-22.08.04-166351-20005-CTM && docker logs -f dm8
```

自构建镜像
```bash
docker run -d -p 5233:5236 --name dm8 \
--restart=always --privileged=true \
-e PAGE_SIZE=16 \
-e CHARSET=1 \
-e LENGTH_IN_CHAR=1 \
-e CASE_SENSITIVE=0 \
-e SYSDBA_PWD='123abc!@#' \
-v /opt/dm8:/home/dmdba/data \
sizx/dm8 && docker logs -f dm8
```

## ARM架构
```bash
docker run -d -p 5236:5236 --name dm8 \
--restart=always --privileged=true \
-v /opt/dm8:/home/dmdba/data \
sizx/dm8:ft-yhqlv4.0-v1-3-12-2023.04.17-187846-20040-ENT
```
