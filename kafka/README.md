# kafka

kafka单实例+zookeeper单实例+kafka-ui

https://hub.docker.com/r/bitnami/kafka


kafka-ui: http://127.0.0.1:8080

zookeeper: http://127.0.0.1:18080/commands

## zkui
> zookeeper可视化UI

启动
1. 进入zkui目录
2. 确认config.cfg中的zkServer配置
3. 启动：`java -jar zkui-2.0-SNAPSHOT-jar-with-dependencies.jar`
4. 访问zkui: http://127.0.0.1:9090
  1. admin/manager


[zookeeper 3.5 AdminServer](https://blog.csdn.net/fenglllle/article/details/107966591)
[Kafka之server.properties配置文件详解](https://dgrt.cn/a/1482489.html?action=onClick)

## 创建主题
docker exec -it kafka-kafka0-1 /opt/bitnami/kafka/bin/kafka-topics.sh \
--create --bootstrap-server kafka-kafka0-1:9092 \
--topic my-topic \
--partitions 3 --replication-factor 2

## 控制台生产者
docker exec -it kafka-kafka0-1 /opt/bitnami/kafka/bin/kafka-console-producer.sh \
--bootstrap-server kafka-kafka0-1:9092 \
--topic my-topic

## 控制台消费者
docker exec -it kafka-kafka0-1 /opt/bitnami/kafka/bin/kafka-console-consumer.sh \
--bootstrap-server kafka-kafka0-1:9092 \
--topic my-topic
