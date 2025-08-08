好，我直接帮你生成一个 **可直接部署的 AFFiNE 完整成品 docker-compose + `.env`**，
支持 **Traefik + Let’s Encrypt** 自动 HTTPS，带 PostgreSQL、Redis、MinIO（S3 兼容），你只要改域名和密码就能用。

---

## **docker-compose.yml**

```yaml
version: "3.8"

networks:
  traefik-network:
    external: true
  affine-network:
    driver: bridge

services:
  postgres:
    image: postgres:15
    container_name: affine_postgres
    restart: always
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - ./data/db:/var/lib/postgresql/data
    networks:
      - affine-network

  redis:
    image: redis:7
    container_name: affine_redis
    restart: always
    volumes:
      - ./data/redis:/data
    networks:
      - affine-network

  minio:
    image: minio/minio:latest
    container_name: affine_minio
    restart: always
    environment:
      MINIO_ROOT_USER: ${S3_ACCESS_KEY}
      MINIO_ROOT_PASSWORD: ${S3_SECRET_KEY}
    command: server /data --console-address ":9001"
    volumes:
      - ./data/minio:/data
    networks:
      - affine-network
    ports:
      - "9001:9001" # MinIO 控制台

  affine:
    image: ghcr.io/toeverything/affine:stable
    container_name: affine_app
    restart: always
    depends_on:
      - postgres
      - redis
      - minio
    environment:
      DATABASE_URL: ${DATABASE_URL}
      REDIS_URL: ${REDIS_URL}
      S3_ENDPOINT: ${S3_ENDPOINT}
      S3_ACCESS_KEY: ${S3_ACCESS_KEY}
      S3_SECRET_KEY: ${S3_SECRET_KEY}
      S3_BUCKET: ${S3_BUCKET}
      SMTP_HOST: ${SMTP_HOST}
      SMTP_PORT: ${SMTP_PORT}
      SMTP_USER: ${SMTP_USER}
      SMTP_PASSWORD: ${SMTP_PASSWORD}
      APP_URL: https://${AFFINE_DOMAIN}
    volumes:
      - ./data/affine:/app/data
    networks:
      - affine-network
      - traefik-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.affine.rule=Host(`${AFFINE_DOMAIN}`)"
      - "traefik.http.routers.affine.entrypoints=websecure"
      - "traefik.http.routers.affine.tls.certresolver=myresolver"
      - "traefik.http.services.affine.loadbalancer.server.port=3010"
```

---

## **.env**（示例）

```
# 域名
AFFINE_DOMAIN=affine.example.com

# 数据库配置
POSTGRES_USER=affine
POSTGRES_PASSWORD=affine_password
POSTGRES_DB=affine
DATABASE_URL=postgresql://affine:affine_password@postgres:5432/affine?sslmode=disable

# Redis
REDIS_URL=redis://redis:6379

# MinIO / S3
S3_ENDPOINT=http://minio:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET=affine-storage

# SMTP（注册/通知邮件）
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=you@example.com
SMTP_PASSWORD=your-smtp-password
```

---

## **使用步骤**

1. **准备 Traefik 网络**（确保你已经有一个运行的 Traefik 容器，并启用了 `myresolver` 证书解析器）：

   ```bash
   docker network create traefik-network
   ```
2. **保存上面的 `docker-compose.yml` 和 `.env`** 到同一目录。
3. **启动 AFFiNE**：

   ```bash
   docker compose up -d
   ```
4. 打开浏览器访问：

   ```
   https://你的域名
   ```

   会自动申请 Let’s Encrypt 证书。

---

我建议我帮你**顺便给一个 Traefik 配置文件**，这样你就可以连 Traefik 一起部署 AFFiNE，一步到位。
你要我帮你把 Traefik 反向代理和 HTTPS 也一起配好放进同一个 compose 文件里吗？这样你不用分两步部署。
