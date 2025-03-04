#!/bin/bash
# Docker自动化安装脚本（CentOS 7专用） - 修复版
# 作者：你的名字 | 最后更新：2023-11-05

#---- 配色定义 ----
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
RESET='\033[0m'

#---- 进度动画函数 ----
function show_spinner() {
    local pid=$!
    local delay=0.25
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

#---- 强制退出函数 ----
function exit_script() {
    echo -e "\n${RED}[错误] $1${RESET}"
    exit 1
}

#---- 步骤计数器 ----
STEP=0
function next_step() {
    ((STEP++))
    echo -e "\n${YELLOW}[步骤 $STEP] $1${RESET}"
}

#---- 预检条件验证 ----
next_step "验证系统环境"
echo -n -e "${CYAN}► 检查系统架构...${RESET}"
[[ $(uname -m) == "x86_64" ]] || exit_script "仅支持64位系统"
echo -e " ${GREEN}通过${RESET}"

echo -n -e "${CYAN}► 检查系统版本...${RESET}"
grep -q 'CentOS Linux release 7' /etc/redhat-release || exit_script "仅支持CentOS 7系统"
echo -e " ${GREEN}通过${RESET}"

#---- 核心安装流程 ----
next_step "切换阿里云yum源"
echo -e "${CYAN}► 下载仓库文件...${RESET}"
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &
show_spinner
[[ $? -eq 0 ]] || exit_script "yum源下载失败，请检查网络连接"

echo -e "\n${CYAN}► 生成仓库缓存...${RESET}"
yum makecache >/dev/null 2>&1 &
show_spinner
[[ $? -eq 0 ]] || exit_script "yum缓存生成失败"

next_step "安装基础工具"
echo -e "${CYAN}► 正在安装yum-utils${RESET}"
yum install -y yum-utils >/dev/null 2>&1 &  
show_spinner
[[ $? -eq 0 ]] || exit_script "基础工具安装失败"

next_step "添加Docker仓库"
echo -e "${CYAN}► 配置Docker CE仓库...${RESET}"
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo >/dev/null 2>&1 &
show_spinner
[[ $? -eq 0 ]] || exit_script "Docker仓库添加失败"

#---- 步骤5：安装指定版本Docker ----
#---- 步骤5：安装指定版本Docker ----
next_step "安装指定版本Docker"
target_packages=(
    "docker-ce-20.10.24-3.el7.x86_64"
    "docker-ce-cli-20.10.24-3.el7.x86_64"
)
echo -e "${CYAN}► 正在安装以下软件包：${RESET}"
echo -e "----------------------------------------"
for pkg in "${target_packages[@]}"; do
    echo -e "   - ${YELLOW}${pkg}${RESET}"
done

# 安装过程
if yum install -y "${target_packages[@]}"; then
    echo -e "\n${GREEN}✔ 软件包安装完成${RESET}"
else
    echo -e "\n${RED}安装失败，可能原因如下：${RESET}"
    echo -e "   1. ${YELLOW}用户手动中断了安装过程${RESET}"
    echo -e "   2. ${YELLOW}yum 进程被挂起或睡眠中${RESET}"
    echo -e "   3. ${YELLOW}网络连接问题，请检查网络配置${RESET}"
    echo -e "   4. ${YELLOW}仓库中不存在指定版本${RESET}"

    # 提示用户查看可用版本
    echo -e "\n${CYAN}► 可用版本列表：${RESET}"
    echo -e "   运行以下命令查看："
    echo -e "   ${YELLOW}yum list docker-ce.x86_64 --showduplicates${RESET}"
    echo -e "   ${YELLOW}yum list docker-ce-cli.x86_64 --showduplicates${RESET}"

    # 提示查看错误日志
    echo -e "\n${CYAN}► 查看详细错误日志：${RESET}"
    echo -e "   运行以下命令查看："
    echo -e "   ${YELLOW}cat /var/log/yum.log | grep -i error${RESET}"
    echo -e "   ${YELLOW}journalctl -xe | grep yum${RESET}"

    exit_script "安装失败，请根据提示排查问题"
fi

#---- 服务配置部分 ----
next_step "启动Docker服务"
echo -e "${CYAN}► 启动Docker守护进程...${RESET}"
systemctl start docker &
show_spinner
[[ $? -eq 0 ]] || exit_script "Docker服务启动失败"

echo -e "\n${CYAN}► 设置开机自启...${RESET}"
systemctl enable docker >/dev/null 2>&1 &
show_spinner
[[ $? -eq 0 ]] || exit_script "开机自启设置失败"

next_step "配置镜像加速并重启服务"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.xuanyuan.me",
    "https://docker.1ms.run",
    "https://docker.m.daocloud.io",
    "https://atomhub.openatom.cn"
  ]
}
EOF

echo -e "${CYAN}► 重新加载服务配置...${RESET}"
systemctl daemon-reload >/dev/null 2>&1 &
show_spinner

echo -e "\n${CYAN}► 重启Docker服务...${RESET}"
systemctl restart docker >/dev/null 2>&1 &
show_spinner
[[ $? -eq 0 ]] || exit_script "Docker重启失败"

#---- 安装结果验证 ----
next_step "验证安装结果"
if docker_version=$(docker --version 2>/dev/null); then
    echo -e "${GREEN}✔ Docker已成功安装！${RESET}"
    echo -e "▷ 版本信息：${GREEN}$docker_version${RESET}"
    
    # 优雅的JSON输出方案
    echo -e "▷ 镜像加速配置状态："
    if [ -f /etc/docker/daemon.json ]; then
        # 尝试使用Python美化输出
        if python -m json.tool /etc/docker/daemon.json 2>/dev/null; then
            true # 正常执行即可
        else
            # 降级方案：原始输出+警告提示
            echo -e "${YELLOW}[提示]显示原始配置：${RESET}"
            cat /etc/docker/daemon.json
        fi
    else
        echo -e "${YELLOW}[警告] 配置文件/etc/docker/daemon.json不存在${RESET}"
    fi
else
    exit_script "Docker安装验证失败"
fi