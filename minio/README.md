# minio对象存储服务器

https://github.com/minio/minio


注：    
1、minio容器默认使用两个端口，9000和9001 9000端口主要适用于数据传输，9001端口主要是用于管理界面，上述文件中我为了好记且避免端口冲突，将9000端口映射到了服务器的9010端口，将9001端口改成了9011并映射到了服务器的9011端口
2、数据卷映射： 默认将数据卷映射到了docker-compose.yml同文件目录下的data文件夹
3、command: server --console-address ‘:9011’ /data 这行一定要加，否则端口号是随机的，你压根映射不出去
4、新版本中用户名和密码改用成了 “MINIO_ROOT_USER” 和 “MINIO_ROOT_PASSWORD” 旧版本是 “MINIO_ACCESS_KEY” 和 “MINIO_SECRET_KEY” 可以自己按照版本进行设置。
5、4中分别对应的是管理界面的用户名和密码

在编辑docker-compose.yml并保存后，通过下述命令创建并启动minio容器

```bash
#如果你的docker-compose.yml文件中有好几个容器，你并不想启动其他容器，只想启动minio
docker-compose up -d minio
#如果你的docker-compose.yml文件中只有目前的minio
docker-compose up -d 
```

访问minio的控制面板:
http://127.0.0.1:9011

- 用户名：minio
- 密码：minio123

## 集成
spring-boot集成参考：
https://blog.csdn.net/Jerrylau213/article/details/140105731

