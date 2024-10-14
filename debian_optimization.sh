好的，让我们在脚本中加入设置静态 IP 地址的功能。这通常涉及到修改 `/etc/network/interfaces` 文件（对于 Debian 系统使用传统网络管理方式）或 `/etc/netplan/` 下的配置文件（对于使用 Netplan 的较新系统）。这里我们将展示如何使用 Netplan 进行配置，因为这是现代 Debian 发行版推荐的方法。

### 修改脚本以设置静态 IP 地址

假设你想要为 `eth0` 接口设置一个静态 IP 地址，以下是完整的脚本，包括网络配置优化和设置静态 IP 地址的部分：

```bash
#!/bin/bash

# 设置日志文件
# LOG_FILE 变量用于存储日志文件的路径
LOG_FILE="debian_optimization.log"

# 日志函数
# log 函数用于记录每一步的操作信息
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# 更新系统包
# update_system_packages 函数用于更新和升级系统包
update_system_packages() {
    log "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
}

# 更改 SSH 端口
# change_ssh_port 函数用于更改 SSH 默认端口为 2222
change_ssh_port() {
    log "Changing SSH port to 2222..."
    sudo sed -i 's/^#*Port .*/Port 2222/' /etc/ssh/sshd_config
    sudo systemctl restart ssh
}

# 禁用 root 登录
# disable_root_login 函数用于禁止 root 用户远程登录
disable_root_login() {
    log "Disabling root login..."
    sudo sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/ssdh_config
    sudo systemctl restart ssh
}

# 安装 UFW 并配置
# install_and_configure_ufw 函数用于安装并配置 UFW 防火墙
install_and_configure_ufw() {
    log "Installing and configuring UFW..."
    sudo apt install ufw -y
    sudo ufw enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 2222/tcp
    sudo ufw status
}

# 安装必要的工具
# install_common_tools 函数用于安装常用的工具软件
install_common_tools() {
    log "Installing common tools..."
    sudo apt install -y curl wget nano git screen htop glances
}

# 清理不必要的文件
# clean_up_files 函数用于清理不必要的系统文件
clean_up_files() {
    log "Cleaning up unnecessary files..."
    sudo apt autoremove --purge -y
    sudo apt autoclean -y
}

# 安装 `unattended-upgrades`
# install_unattended_upgrades 函数用于安装并配置自动安全更新
install_unattended_upgrades() {
    log "Installing unattended-upgrades..."
    sudo apt install unattended-upgrades -y
    # 配置自动更新策略
    sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
    sudo systemctl restart cron
}

# 安装 `logrotate`
# install_logrotate 函数用于安装并配置日志轮转工具
install_logrotate() {
    log "Installing logrotate..."
    sudo apt install logrotate -y
    # 配置日志轮转策略
    sudo tee /etc/logrotate.d/syslog <<EOF
/var/log/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
EOF
    sudo logrotate -d /etc/logrotate.conf
    sudo systemctl restart logrotate
}

# 创建并启用 swap 文件
# create_swap_file 函数用于创建并启用交换文件
create_swap_file() {
    log "Creating swap file..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    # 将交换文件添加到 fstab 中，以便下次启动时自动启用
    sudo tee -a /etc/fstab <<EOF
/swapfile none swap sw 0 0
EOF
}

# 调整内核参数
# adjust_kernel_parameters 函数用于调整内核参数以优化性能
adjust_kernel_parameters() {
    log "Adjusting kernel parameters..."
    sudo tee -a /etc/sysctl.conf <<EOF
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_syn_backlog = 2048
net.core.somaxconn = 65535
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF
    sudo sysctl -p
}

# 设置定时备份
# set_periodic_backup 函数用于设置定时备份任务
set_periodic_backup() {
    log "Setting periodic backup..."
    # 添加定时备份任务到 crontab 中
    (crontab -l ; echo "0 3 * * * tar -zcvf /backup/backup_$(date +%Y%m%d).tar.gz /path/to/important/directory") | crontab -
}

# 安装并配置 `monit`
# install_and_configure_monit 函数用于安装并配置 monit 服务监控工具
install_and_configure_monit() {
    log "Installing and configuring monit..."
    sudo apt install monit -y
    # 配置 monit 监控 SSH 服务
    sudo tee -a /etc/monit/monitrc <<EOF
check process sshd with pidfile /var/run/sshd.pid
    start program = "/etc/init.d/ssh start"
    stop program  = "/etc/init.d/ssh stop"
    if failed host 127.0.0.1 port 2222 then restart
EOF
    sudo systemctl enable monit
    sudo systemctl start monit
}

# 网络配置优化
# optimize_network_configuration 函数用于优化网络配置参数
optimize_network_configuration() {
    log "Optimizing network configuration..."
    sudo tee -a /etc/sysctl.conf <<EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.lo.send_redirects = 0
net.ipv4.conf.eth0.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.icmp_ratelimit = 2000
net.ipv4.icmp_ratemask = 15
net.ipv4.tcp_rmem = 4096 87380 6291456
net.ipv4.tcp_wmem = 4096 16384 4194304
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 7200
net.ipv4.tcp_keepalive_intvl = 75
net.ipv4.tcp_keepalive_probes = 9
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_syn_backlog = 2048
net.core.somaxconn = 65535
EOF
    sudo sysctl -p

    # 配置公共 DNS
    configure_public_dns

    # 设置静态 IP 地址
    set_static_ip_address
}

# 配置公共 DNS
# configure_public_dns 函数用于配置多个公共 DNS 服务器
configure_public_dns() {
    log "Configuring public DNS..."

    # 使用 systemd-resolved 配置多个 DNS 服务器
    sudo tee /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=1.1.1.1
FallbackDNS=8.8.8.8 8.8.4.4 9.9.9.9 1.0.0.1
EOF

    # 启动并启用 systemd-resolved
    sudo systemctl enable systemd-resolved
    sudo systemctl start systemd-resolved
}

# 设置静态 IP 地址
# set_static_ip_address 函数用于设置静态 IP 地址
set_static_ip_address() {
    log "Setting static IP address..."
    
    # 清空原有的 netplan 配置文件
    sudo tee /etc/netplan/01-netcfg.yaml > /dev/null <<EOF
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
EOF

    # 应用 netplan 配置
    sudo netplan apply
}

# 文件系统挂载选项
# optimize_file_system_mount_options 函数用于优化文件系统的挂载选项
optimize_file_system_mount_options() {
    log "Optimizing file system mount options..."
    sudo tee -a /etc/fstab <<EOF
/dev/sda1 / ext4 errors=remount-ro 0 1
EOF
}

# 系统服务管理
# disable_unnecessary_services 函数用于禁用不必要的系统服务
disable_unnecessary_services() {
    log "Disabling unnecessary services..."
    sudo systemctl disable --now avahi-daemon
    sudo systemctl disable --now bluetooth
    sudo systemctl disable --now cups
    sudo systemctl disable --now ntp
    sudo systemctl disable --now samba
    sudo systemctl disable --now systemd-timesyncd
}

# 内存优化
# optimize_memory_settings 函数用于优化内存相关参数
optimize_memory_settings() {
    log "Optimizing memory settings..."
    sudo tee -a /etc/sysctl.conf <<EOF
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.max_map_count = 262144
vm.min_free_kbytes = 8388608
vm.drop_caches = 3
EOF
    sudo sysctl -p
}

# 磁盘 I/O 调优
# optimize_disk_io 函数用于优化磁盘 I/O 相关参数
optimize_disk_io() {
    log "Optimizing disk I/O..."
    sudo tee -a /etc/sysctl.conf <<EOF
fs.file-max = 65536
fs.inotify.max_user_watches = 8192
fs.inotify.max_user_instances = 128
EOF
    sudo sysctl -p
}

# 文件系统同步
# optimize_file_system_sync 函数用于优化文件系统的同步机制
optimize_file_system_sync() {
    log "Optimizing file system sync..."
    sudo tee -a /etc/sysctl.conf <<EOF
fs.sync_write_behaviour = lazy
EOF
    sudo sysctl -p
}

# 日志记录优化
# optimize_logging 函数用于优化日志记录机制
optimize_logging() {
    log "Optimizing logging..."
    sudo tee -a /etc/syslog-ng/syslog-ng.conf <<EOF
destination console {
    file("/dev/console");
};

log {
    source(s_src);
    filter(f_filter);
    destination(console);
};
EOF
    sudo systemctl restart syslog-ng
}

# 用户权限管理
# optimize_user_permissions 函数用于优化用户权限配置
optimize_user_permissions() {
    log "Optimizing user permissions..."
    sudo tee -a /etc/sudoers <<EOF
# Allow members of the sudo group to execute any command as root
%sudo ALL=(ALL:ALL) ALL
EOF
}

# 主函数
# main 函数用于调用各个优化函数
main() {
    # 更新系统包
    update_system_packages

    # 更换镜像源
    switch_mirror_source

    # 更改 SSH 端口
    change_ssh_port

    # 禁用 root 登录
    disable_root_login

    # 安装 UFW 并配置
    install_and_configure_ufw

    # 安装必要的工具
    install_common_tools

    # 清理不必要的文件
    clean_up_files

    # 安装 `unattended-upgrades`
    install_unattended_upgrades

    # 安装 `logrotate`
    install_logrotate

    # 创建并启用 swap 文件
    create_swap_file

    # 调整内核参数
    adjust_kernel_parameters

    # 设置定时备份
    set_periodic_backup

    # 安装并配置 `monit`
    install_and_configure_monit

    # 网络配置优化
    optimize_network_configuration

    # 文件系统挂载选项
    optimize_file_system_mount_options

    # 系统服务管理
    disable_unnecessary_services

    # 内存优化
    optimize_memory_settings

    # 磁盘 I/O 调优
    optimize_disk_io

    # 文件系统同步
    optimize_file_system_sync

    # 日志记录优化
    optimize_logging

    # 用户权限管理
    optimize_user_permissions
}

# 检查是否需要帮助信息
# 如果传入参数为 --help 或 -h，则显示帮助信息
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<EOF
Usage:
    $(basename "$0") [options]

Options:
    --help|-h      Show this help message
EOF
    exit 0
fi

# 主流程
# 调用主函数执行优化
main
```

### 使用方法：

1. **创建并保存脚本文件**：
   ```bash
   nano debian_optimization.sh
   ```
   复制并粘贴上述脚本内容，保存并退出编辑器。

2. **赋予执行权限**：
   ```bash
   chmod +x debian_optimization.sh
   ```

3. **运行脚本**：
   ```bash
   ./debian_optimization.sh
   ```

4. **查看帮助信息**：
   ```bash
   ./debian_optimization.sh --help
   ```

### 示例场景

假设你刚安装了一个全新的 Debian 系统，并希望进行全面优化处理，并设置静态 IP 地址，可以这样做：

```bash
# 打开终端
$ nano debian_optimization.sh  # 创建并编辑脚本文件
# 粘贴脚本内容，保存并退出
$ chmod +x debian_optimization.sh  # 赋予执行权限
$ ./debian_optimization.sh          # 运行脚本
```

脚本将按照预定顺序执行各个优化步骤，并记录日志到 `debian_optimization.log` 文件中。
