好的，如果你要使用 **Timescale 官方推荐的高可用版本：`timescale/timescaledb-ha`**，并同时集成：

✔ TimescaleDB
✔ PostGIS
✔ 实例初始化（扩展自动安装）
✔ 自定义配置（shared_preload_libraries 等）

下面给你 **官方风格、可直接运行的生产级 compose 配置**。

---

# ✅ 一、镜像说明

`timescale/timescaledb-ha` 已经内置：

* PostgreSQL（建议 pg14/pg15/pg16）
* TimescaleDB
* PostGIS
* Patroni（用于 HA）
* HAProxy（负载均衡）

但如果你不需要 Patroni + 多节点，只想用它的 “单实例 + 扩展齐全 + 官方推荐” 特性，你也可以只用单节点部署。

下面我提供两个版本：

---

# ⭐ 版本 A：单节点（最常用、轻量、简单）

适合你现在的场景：
**仅需要 PostgreSQL + TimescaleDB + PostGIS，不需要真正的集群。**

---

# 📌 二、目录结构

```
project/
 ├── docker-compose.yml
 ├── initdb/
 │    └── init_extensions.sql
 └── conf/
      └── postgresql.conf   # 可选
```

---

# ⭐ 三、docker-compose.yml（TimescaleDB-HA 单实例）

```yaml
version: '3.8'

services:
  timescaledb:
    image: timescale/timescaledb-ha:pg16-latest
    container_name: timescaledb
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin123
      POSTGRES_DB: mydb
    ports:
      - "5432:5432"
    volumes:
      - ./data:/var/lib/postgresql/data
      - ./initdb:/docker-entrypoint-initdb.d
      - ./conf/postgresql.conf:/etc/postgresql/postgresql.conf
    command: >
      postgres -c config_file=/etc/postgresql/postgresql.conf
    restart: always
```

> timescaledb-ha 镜像内置 TimescaleDB、PostGIS、Timescale Toolkit、timescaledb_preload 等高级组件。

---

# ⭐ 四、postgresql.conf（官方推荐值）

重点是内置扩展需要 preload：

文件：`conf/postgresql.conf`

```
shared_preload_libraries = 'timescaledb,pg_stat_statements'
max_connections = 200
timezone = 'Asia/Shanghai'
```

> 如果你不挂载配置文件，也可以用环境变量方式（但 compose 不方便设置 preload），所以推荐挂载。

---

# ⭐ 五、初始化扩展 SQL

文件：`initdb/init_extensions.sql`

```sql
-- TimescaleDB 开启
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- 常用扩展（可选）
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

> 该文件只会在第一次启动 database 时自动运行。

---

# ⭐ 六、启动命令

```sh
docker compose up -d
```

验证：

```sh
docker exec -it timescaledb psql -U admin -d mydb
```

---

# ⭐ 七、验证扩展是否安装成功

```sql
SELECT extname, extversion FROM pg_extension;
```

你应该看到：

* **timescaledb**
* **postgis**
* **postgis_topology**
* **pg_stat_statements**
* **uuid-ossp**
* **hstore**

---

# ⭐ 八、TimescaleDB Hypertable 测试

```sql
CREATE TABLE metrics (
  time TIMESTAMPTZ NOT NULL,
  device_id TEXT,
  value DOUBLE PRECISION
);

SELECT create_hypertable('metrics', 'time');
```

---

# ⭐ 九、PostGIS 试用

```sql
SELECT PostGIS_Full_Version();

-- 创建简单点位表
CREATE TABLE places (
  id SERIAL PRIMARY KEY,
  name TEXT,
  geom GEOGRAPHY(Point, 4326)
);
```

---

# 🎯 十、如果你需要真正的 HA 集群（Patroni + 3 节点）

我也可以给你以下版本：

* **TimescaleDB-HA 3 节点（Leader + 2 Followers）**
* **HAProxy + VIP**
* **生产级 keepalived 版本**

告诉我即可，我可以生成完整的 `docker-compose.yml`（超过 300 行配置）+ 拓扑图 + 启动文档。

---

如果你现在的需求是单节点，那上面的方案已经是 **官方推荐、最轻量、扩展齐全** 的部署方式。
