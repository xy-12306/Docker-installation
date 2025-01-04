## 使用方法

#### 1. 下载脚本
下载install_docker.sh脚本:
```bash
curl -O https://github.com/xy-12306/Docker-installation/releases/download/1.5/install_docker.sh  # 替换为实际下载链接
```

#### 2. 赋予脚本执行权限
运行以下命令，赋予脚本可执行权限：
```bash
chmod +x install_docker.sh
```

#### 3. 执行脚本
运行以下命令，执行脚本：
```bash
./install_docker.sh
```

---

### 执行过程

脚本会依次执行以下操作：
1. **切换 yum 源为阿里云**：加快软件包下载速度。
2. **安装 Docker**：
   - 安装必要的工具。
   - 添加 Docker 官方源（阿里云镜像）。
   - 安装 Docker 及相关组件。
   - 启动 Docker 服务并设置开机自启。
3. **配置 Docker 镜像加速**：
   - 使用多个国内镜像加速地址。
   - 重启 Docker 服务使配置生效。
4. **检查镜像加速是否生效**：
   - 输出 `docker info` 信息，并检查是否包含镜像加速地址。

---

### 注意事项

1. **系统要求**：
   - 脚本适用于 **CentOS 7** 系统。
   - 如果使用其他 Linux 发行版（如 Ubuntu），需要调整部分命令。

2. **网络连接**：
   - 确保服务器可以正常访问外网，以下载必要的软件包。

3. **权限问题**：
   - 脚本中部分命令需要 root 权限，请使用 `sudo` 或以 root 用户运行。

4. **镜像加速地址**：
   - 脚本中配置了多个镜像加速地址，如果某个地址不可用，可以手动修改 `/etc/docker/daemon.json` 文件。