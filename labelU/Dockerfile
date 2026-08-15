FROM python:3.11-slim

WORKDIR /labelu

# 安装编译依赖和 MySQL 客户端开发包
RUN apt-get update && apt-get install -y \
    gcc \
    pkg-config \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装 Python 依赖
RUN pip install --no-cache-dir labelu mysqlclient

ENV MEDIA_HOST http://localhost:8000

EXPOSE 8000

CMD ["sh", "-c", "labelu --host=0.0.0.0 --media-host=$MEDIA_HOST"]
