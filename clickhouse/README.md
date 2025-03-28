# 创建目录
```
mkdir -p /usr/local/docker/clickhouse/conf /usr/local/docker/clickhouse/data /usr/lcoal/docker/clickhouse/log
```
# 启动临时容器获取配置文件
```
docker run --rm -d --name=temp-clickhouse-server clickhouse/clickhouse-server:latest
```
# 复制配置文件到宿主机
```
docker cp temp-clickhouse-server:/etc/clickhouse-server/users.xml /usr/local/docker/clickhouse/conf/users.xml
docker cp temp-clickhouse-server:/etc/clickhouse-server/config.xml /usr/local/docker/clickhouse/conf/config.xml
```
# 初始化密码
修改 users.xml 文件设置密码 标签：password

# 创建docker-compose文件
```
services:
  clickhouse:
    image: clickhouse/clickhouse-server:latest
    container_name: ck
    ports:
      - "8123:8123"
    volumes:
      - ./conf/config.xml:/etc/clickhouse-server/config.xml
      - ./conf/users.xml:/etc/clickhouse-server/users.xml
      - ./data:/var/lib/clickhouse
    networks:
      - clickhouse
    restart: always

networks:
  clickhouse:
    driver: bridge
```

# 在docker-compose.yaml文件部署ck
docker compose up -d

## 修改密码
路径：/etc/clickhouse-server/users.xml
```
<passwrod>123456</passwrod>
```

## 修改监听
路径：/etc/clickhouse-server/config.xml
```
<listen_host>::</listen_host>
```

## connect
```
./clickhouse client --host 127.0.0.1 \
--secure --port c \
--user default \
--password 123456

./clickhouse client --host 127.0.0.1 --port 9000 --password '123456'


./clickhouse client --host 192.168.5.7 --port 18759 --password '103tiger'
./clickhouse client --host 192.168.5.7 --port 18760 --user default --password '103tiger'

curl --user 'default:123456' \
  --data-binary 'SELECT 1' \
  http://127.0.0.1:8123
```

