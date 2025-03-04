#!/bin/bash

# 1. 切换yum源为阿里
echo "一、切换yum源为阿里源..."
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum makecache

# 2. 安装Docker
echo "二、开始安装Docker..."
# Step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils

# Step 2: 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# Step 3: 安装Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 4: 开启Docker服务并设置开机自启动
sudo service docker start
sudo systemctl enable docker

# 3. 配置镜像加速地址
echo "三、配置镜像加速地址..."
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
# 检查加速是否生效
echo "四、检查相关配置..."
docker_info=$(docker info 2>&1)
echo "$docker_info"

# 获取 Docker 版本号
docker_version=$(docker --version 2>&1)

# 检查是否成功获取版本号
if [[ $docker_version == Docker* ]]; then
    echo "Docker 已安装完成! Docker 版本号: $docker_version"
else
    echo "Docker 安装失败。可能的原因如下："
    
    # 检查 Docker 是否安装
    if ! command -v docker &> /dev/null; then
        echo "1. Docker 未正确安装，请检查安装步骤是否完整。"
    fi

    # 检查 Docker 服务是否运行
    if ! systemctl is-active --quiet docker; then
        echo "2. Docker 服务未启动，请尝试运行 'systemctl start docker' 启动服务。"
    fi

    # 检查用户权限
    if [[ $docker_info == *"permission denied"* ]]; then
        echo "3. 当前用户没有权限访问 Docker，请将用户加入 'docker' 组，或使用 sudo 运行。"
    fi

    # 检查网络配置
    if [[ $docker_info == *"Cannot connect to the Docker daemon"* ]]; then
        echo "4. 无法连接到 Docker 守护进程，请检查 Docker 是否已安装并启动。"
    fi

    # 其他未知错误
    echo "5. 未知错误，请检查安装日志或重新运行安装脚本。"
    echo "6. 未知错误，请检查前面步骤是否运行正常。"
fi
