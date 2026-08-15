# Log Viewer Docker Compose

本项目提供了一个基于 [sevdokimov/log-viewer](https://github.com/sevdokimov/log-viewer) 的 Docker 化部署方案，用于在浏览器中实时监控和查看服务器日志文件。

## 特性

- **实时监控**：无需刷新页面，实时流式查看日志更新。
- **高性能**：只读取用户当前查看的日志片段，不进行预先索引，占用资源极小。
- **高亮与过滤**：支持自定义高亮规则、按日志级别、线程或自定义条件进行过滤。
- **日志合并**：支持将多个日志文件合并在同一个页面中展示。
- **本地构建**：直接使用预先下载的包构建，无需依赖不稳定的外部网络源。

## 目录结构

```text
log-viewer/
├── Dockerfile                  # 构建 log-viewer 镜像的 Dockerfile，使用本地压缩包构建
├── docker-compose.yml          # Docker Compose 配置文件，定义服务启动参数和端口映射
├── config.conf                 # log-viewer 的核心配置文件（基于 HOCON 格式）
├── log-viewer-1.0.10.tar.gz    # log-viewer 官方发行的离线压缩包
└── README.md                   # 本说明文档
```

## 快速开始

### 1. 配置日志目录 (必填)

在启动服务前，你需要修改 `docker-compose.yml` 中的 `volumes` 映射，将你宿主机的日志目录挂载到容器内：

```yaml
    volumes:
      # 【需要修改的部分】将 /Users/.../log 替换为你自己实际的日志存放目录绝对路径
      - /Users/test/code/my/fa-admin/fa-antd-admin-submodule/log:/logs:ro
      - ./config.conf:/opt/logviewer/config.conf
```
> **注意**：容器内的挂载点强制为 `/logs`，因为我们在 `config.conf` 中也配置了读取 `/logs/**/*.log`。由于只是查看日志，所以添加了 `:ro` (只读) 权限以保证宿主机文件的安全。

### 2. 构建并启动服务

在当前目录（`log-viewer`）下，执行以下命令：

```bash
# 构建镜像并后台启动容器
docker compose up -d --build
```

### 3. 访问 Web 页面

当容器成功启动后，在你的浏览器中打开：

📦 [http://localhost:8111](http://localhost:8111)

### 4. 账号登录

为了防止未经授权的访问，默认在 `config.conf` 中开启了基础的身份验证（Basic Auth）。

默认登录账号：
- **用户名**：`admin`
- **密　码**：`123456`

## 常见操作说明

### 修改登录密码

如果你需要修改密码或添加新账号，打开 `config.conf` 文件，找到 `users` 节点进行修改：

```hocon
users = [
  { 
      name: "admin", 
      password: "123456" 
  },
  {
      name: "guest",
      password: "guest"
  }
]
```
> 改完配置后，需要重启容器才能生效：`docker compose restart logviewer`

### 停止与删除容器

当你不需要查看日志并希望停止服务时：

```bash
# 停止容器运行
docker compose stop

# 或者停止并删除容器及网络（但不删除镜像和你的数据）
docker compose down
```

## 参考资料
- 如果需要更复杂的配置文件，例如接入 LDAP 或者过滤规则等高级用法，请参阅[官方文档 Configuration](https://github.com/sevdokimov/log-viewer/blob/master/_docs/configuration.md)。