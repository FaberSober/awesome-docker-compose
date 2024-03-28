# kafka-cluster-zookeeper

kafka三实例+zookper

# 测试命令
## 创建主题
docker exec -it kafka-cluster-zookeeper-kafka0-1 /opt/bitnami/kafka/bin/kafka-topics.sh \
--create --bootstrap-server kafka-cluster-zookeeper-kafka0-1:9092,kafka-cluster-zookeeper-kafka1-1:9092,kafka-cluster-zookeeper-kafka2-1:9092 \
--topic my-topic \
--partitions 3 --replication-factor 2

## 控制台生产者
docker exec -it kafka-cluster-zookeeper-kafka0-1 /opt/bitnami/kafka/bin/kafka-console-producer.sh \
--bootstrap-server kafka-cluster-zookeeper-kafka0-1:9092,kafka-cluster-zookeeper-kafka1-1:9092,kafka-cluster-zookeeper-kafka2-1:9092 \
--topic my-topic

## 控制台消费者
docker exec -it kafka-cluster-zookeeper-kafka0-1 /opt/bitnami/kafka/bin/kafka-console-consumer.sh \
--bootstrap-server kafka-cluster-zookeeper-kafka0-1:9092,kafka-cluster-zookeeper-kafka1-1:9092,kafka-cluster-zookeeper-kafka2-1:9092 \
--topic my-topic
