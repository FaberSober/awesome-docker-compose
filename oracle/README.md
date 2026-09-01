可以直接使用 `gvenzl/oracle-xe`，它目前仍提供 **Oracle XE 11.2.0.2** 镜像标签。Oracle 11g XE 的数据目录与 18c/21c 不同，需要挂载到 `/u01/app/oracle/oradata`。([Docker Hub][1])

### 启动

```bash
docker compose up -d
```

查看启动日志：

```bash
docker compose logs -f oracle11g
```

查看容器状态：

```bash
docker compose ps
```

数据库第一次初始化会比普通容器启动慢一些。

### 数据库连接信息

| 配置           | 值              |
| ------------ | -------------- |
| Host         | `localhost`    |
| Port         | `1521`         |
| SID          | `XE`           |
| Service Name | `XE`           |
| 用户名          | `SYSTEM`       |
| 密码           | `Oracle123456` |

JDBC：

```text
jdbc:oracle:thin:@localhost:1521:XE
```

Spring Boot：

```yaml
spring:
  datasource:
    url: jdbc:oracle:thin:@localhost:1521:XE
    username: SYSTEM
    password: Oracle123456
    driver-class-name: oracle.jdbc.OracleDriver
```

如果想进入数据库：

```bash
docker exec -it oracle11g sqlplus system/Oracle123456@XE
```

### 如果要自动初始化测试用户

可以增加一个初始化目录：

```yaml
services:
  oracle11g:
    image: gvenzl/oracle-xe:11.2.0.2-slim
    container_name: oracle11g
    restart: unless-stopped

    ports:
      - "1521:1521"

    environment:
      ORACLE_PASSWORD: Oracle123456

    volumes:
      - oracle11g-data:/u01/app/oracle/oradata
      - ./init:/container-entrypoint-initdb.d

    healthcheck:
      test: ["CMD", "healthcheck.sh"]
      interval: 10s
      timeout: 5s
      retries: 20
      start_period: 60s

volumes:
  oracle11g-data:
```

然后创建：

```text
.
├── docker-compose.yml
└── init
    └── 01-init.sql
```

`init/01-init.sql`：

```sql
CREATE USER test_user IDENTIFIED BY Test123456;

GRANT CONNECT, RESOURCE TO test_user;

ALTER USER test_user QUOTA UNLIMITED ON USERS;
```

这个镜像支持首次初始化时执行 `.sql` / `.sh` 脚本。([Docker Hub][1])

> ⚠️ **如果你是在 Apple Silicon（M1/M2/M3/M4/M5）Mac 上运行，需要特别注意：** Oracle 11g XE 镜像只有 `linux/amd64`，该镜像维护者明确说明 Oracle XE 11g 无 ARM 版本，在 Apple M 系列 Mac 的 Docker Desktop 上不属于可直接运行的方案。更稳妥的是放到 **x86_64 Linux/CentOS 测试机**运行。([Docker Hub][1])

如果你是在 **CentOS 7 x86_64** 上部署，上面这个 Compose 配置可以直接作为测试环境使用。

[1]: https://hub.docker.com/r/gvenzl/oracle-xe?utm_source=chatgpt.com "gvenzl/oracle-xe - Docker Image"
