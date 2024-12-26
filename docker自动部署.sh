#!/bin/sh

# 切换 yum 源为阿里
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum makecache

# 安装 docker
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils

# Step 2: 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# Step 3: 安装 Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 4: 开启 Docker 服务并设置开机自启动
sudo service docker start
sudo systemctl enable docker

# 配置镜像加速地址
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

# 检查加速是否生效
docker_info=$(docker info)
echo "$docker_info"


# 显示 Docker 版本号
docker_version=$(docker --version)
echo "Docker 版本号: $docker_version"
echo "Docker已经安装成功!"