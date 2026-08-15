# kafka-cluster-zookeeper

Kafka 4.x KRaft 三节点本地集群，使用官方 `apache/kafka` 镜像。目录名保留历史命名，当前配置不依赖 ZooKeeper。

## 启动

```bash
cd docker-env/kafka-cluster-zookeeper
docker compose up -d
```

默认对宿主机暴露：

- `kafka0`: `localhost:9093`
- `kafka1`: `localhost:9094`
- `kafka2`: `localhost:9095`
- Kafka UI: <http://localhost:8080>

如果需要局域网客户端访问，复制 `.env.example` 为 `.env`，把 `KAFKA_EXTERNAL_HOST` 改成宿主机局域网 IP。

## 测试命令

### 查看集群

```bash
docker exec -it kafka0 /opt/kafka/bin/kafka-broker-api-versions.sh \
  --bootstrap-server kafka0:9092,kafka1:9092,kafka2:9092
```

### 创建主题

```bash
docker exec -it kafka0 /opt/kafka/bin/kafka-topics.sh \
  --create \
  --bootstrap-server kafka0:9092,kafka1:9092,kafka2:9092 \
  --topic my-topic \
  --partitions 3 \
  --replication-factor 3
```

### 控制台生产者

```bash
docker exec -it kafka0 /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server kafka0:9092,kafka1:9092,kafka2:9092 \
  --topic my-topic
```

### 控制台消费者

```bash
docker exec -it kafka0 /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server kafka0:9092,kafka1:9092,kafka2:9092 \
  --topic my-topic \
  --from-beginning
```
