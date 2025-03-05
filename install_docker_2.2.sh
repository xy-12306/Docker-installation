#!/bin/bash

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# 进度符号
SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# 打印带颜色的函数
print_status() {
    if [ $2 -eq 0 ]; then
        printf "${GREEN}✓${RESET} $1\n"
    else
        printf "${RED}✗${RESET} $1\n"
        FAILED=1
    fi
}

# 旋转进度指示
show_spinner() {
    local pid=$!
    local text=$1
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r${CYAN}${SPINNER[$i]}${RESET} ${text}..."
        sleep 0.1
    done
    printf "\r%-40s" " "
    printf "\r"
}

# 初始化失败标志
FAILED=0

# 检查root权限
if [ $(id -u) -ne 0 ]; then
    printf "${RED}错误：该脚本需要root权限执行！${RESET}\n"
    exit 1
fi

printf "${BLUE}
===============================================
 CentOS 7 Docker 自动化安装脚本（最新版）
===============================================
${RESET}"

# 步骤1：更换yum源
printf "\n${YELLOW}▶ 正在切换yum源到阿里云...${RESET}\n"
(curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo >/dev/null 2>&1) &
show_spinner "下载阿里云yum源"
curl_status=$?
if [ $curl_status -eq 0 ]; then
    (yum makecache >/dev/null 2>&1) &
    show_spinner "生成yum缓存"
    print_status "yum源配置完成" $?
else
    print_status "下载阿里云yum源失败 (错误码: $curl_status)" $curl_status
    exit 1
fi

# 步骤2：安装系统工具
printf "\n${YELLOW}▶ 正在安装必要系统工具...${RESET}\n"
(yum install -y yum-utils >/dev/null 2>&1) &
show_spinner "安装 yum-utils"
print_status "系统工具安装" $?

# 步骤3：添加Docker仓库
printf "\n${YELLOW}▶ 配置Docker阿里云镜像源...${RESET}\n"
(yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo >/dev/null 2>&1) &
show_spinner "添加仓库配置"
print_status "Docker仓库配置" $?

# 步骤4：安装Docker组件（优化后的进度显示）
printf "\n${YELLOW}▶ 开始安装Docker及其组件...${RESET}\n"
(yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1) &
show_spinner "安装Docker引擎"
print_status "Docker核心组件安装" $?

# 步骤5：启动Docker服务
printf "\n${YELLOW}▶ 启动Docker服务...${RESET}\n"
(systemctl start docker >/dev/null 2>&1) &
show_spinner "启动服务"
(systemctl enable docker >/dev/null 2>&1) &
show_spinner "设置开机启动"
print_status "服务启动配置" $?

# 步骤6：配置镜像加速
printf "\n${YELLOW}▶ 配置镜像加速器...${RESET}\n"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
    "registry-mirrors": [
        "https://docker.xuanyuan.me",
        "https://docker.1ms.run",
        "https://docker.m.daocloud.io",
        "https://atomhub.openatom.cn"
    ]
}
EOF
(systemctl daemon-reload >/dev/null 2>&1 && systemctl restart docker >/dev/null 2>&1) &
show_spinner "应用加速配置"
print_status "镜像加速配置" $?

# 最终验证
printf "\n${BLUE}✅ 安装结果验证${RESET}\n"

# 显示版本信息
docker_version=$(docker -v 2>/dev/null)
if [ $? -eq 0 ]; then
    printf "${GREEN}■ Docker版本: ${docker_version}${RESET}\n"
else
    printf "${RED}■ Docker未正确安装${RESET}\n"
    FAILED=1
fi

# 显示镜像加速信息（原生方式解析）
printf "\n${BLUE}镜像加速配置状态：${RESET}\n"
if [ -f /etc/docker/daemon.json ]; then
    grep -A 4 'registry-mirrors' /etc/docker/daemon.json | 
    grep -oE 'https?://[^"]+' | 
    while read -r line; do
        printf "${CYAN}▪ ${line}${RESET}\n"
    done
else
    printf "${RED}未检测到镜像加速配置文件${RESET}\n"
fi

# 最终状态判断
if [ $FAILED -eq 0 ]; then
    printf "\n${GREEN}
===============================================
 🎉 Docker 安装成功！
 ${CYAN}常用命令清单：
 ■ 镜像管理
   ${CYAN}docker pull <镜像名>     ${GREEN}# 下载镜像
   ${CYAN}docker images          ${GREEN}# 查看镜像列表
   ${CYAN}docker rmi <镜像ID>     ${GREEN}# 删除镜像

 ■ 容器操作
   ${CYAN}docker run -d <镜像名>  ${GREEN}# 启动容器
   ${CYAN}docker ps              ${GREEN}# 查看运行中的容器
   ${CYAN}docker ps -a           ${GREEN}# 查看所有容器
   ${CYAN}docker stop <容器ID>    ${GREEN}# 停止容器

 ■ 系统信息
   ${CYAN}docker version         ${GREEN}# 查看版本
   ${CYAN}docker info            ${GREEN}# 查看系统信息

===============================================
${RESET}"
else
    printf "\n${RED}
===============================================
 ❌ 安装失败！可能原因：
 1. 网络连接异常 (请检查curl/wget可用性)
 2. 软件源冲突 (尝试 yum clean all)
 3. 系统版本不兼容 (仅支持CentOS 7)
 4. 请检查日志并重试
 5. 请教老师或同学
===============================================
${RESET}"
    exit 1
fi