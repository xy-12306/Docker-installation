### 1.切换yum源为阿里

 
```
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum makecache   #生成缓存
```

### 2.CentOS 7（使用 yum 安装docker）

 
```
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils

# Step 2: 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# Step 3: 安装Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 4: 开启Docker服务并设置开机自启动
sudo service docker start
sudo systemctl enable docker
```

### 3.配置镜像加速地址

 
```
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": [
        "https://docker.xuanyuan.me",
        "https://docker.1ms.run",
        "https://docker.udayun.com",
        "https://docker.m.daocloud.io",
        "https://atomhub.openatom.cn"
        
    ]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

* 检查加速是否生效：

> 查看docker系统信息 ,输入 ` docker info ` ，如果从输出结果中看到了 registry mirror 刚配置的内容地址，说明配置成功。

### 4.拉取镜像示例


```
docker pull [镜像名称:版本号]

docker pull mysql:8.0

docker pull nginx:1.27.0
```

---

参考网页：
* [CentOS （使用 yum 进行安装）-阿里云开发者社区](https://developer.aliyun.com/mirror/docker-ce?spm=a2c6h.13651102.0.0.57e31b11mZMLg4)

* [docker镜像加速地址（国内镜像源）](https://xuanyuan.me/blog/archives/1154?from=tencent)
