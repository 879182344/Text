#!/bin/bash

# 设置默认值
DOCKER_NAME="jellyfin"
VOLUME_NAME="jellyfin-data"
HTTP_PORT="8096"
UDP_PORT="8097"
ACTION="deploy"
CONFIG_DIR="/config"
LOG_LEVEL="info"
SCRIPT_LOG_FILE="deploy_jellyfin.log"

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$SCRIPT_LOG_FILE"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --name)
            DOCKER_NAME="$2"
            shift
            ;;
        --volume)
            VOLUME_NAME="$2"
            shift
            ;;
        --http-port)
            HTTP_PORT="$2"
            shift
            ;;
        --udp-port)
            UDP_PORT="$2"
            shift
            ;;
        --action)
            ACTION="$2"
            shift
            ;;
        --config-dir)
            CONFIG_DIR="$2"
            shift
            ;;
        --log-level)
            LOG_LEVEL="$2"
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage:
    $(basename "$0") [options]

Options:
    --name <name>         Container name (default: jellyfin)
    --volume <volume>     Volume name for data persistence (default: jellyfin-data)
    --http-port <port>    HTTP port to expose (default: 8096)
    --udp-port <port>     UDP port for streaming (default: 8097)
    --action <deploy|uninstall> Action to perform (default: deploy)
    --config-dir <dir>    Directory to mount for configuration (default: /config)
    --log-level <level>   Log level for Jellyfin (default: info)
    --help|-h             Show this help message
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $key"
            exit 1
            ;;
    esac
    shift
done

# 检查Docker是否已经安装
if ! command -v docker &> /dev/null; then
    log "Docker is not installed. Please install Docker first."
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# 检查网络是否可达
if ! ping -c 1 google.com > /dev/null 2>&1; then
    log "Network is unreachable. Please check your internet connection."
    echo "Network is unreachable. Please check your internet connection."
    exit 1
fi

# 检查镜像是否存在
if [ "$ACTION" = "deploy" ]; then
    if ! docker images | grep -qw "jellyfin/jellyfin"; then
        log "Jellyfin image not found. Pulling the latest image..."
        echo "Jellyfin image not found. Pulling the latest image..."
        docker pull jellyfin/jellyfin
    fi
fi

# 根据用户选择的操作执行相应任务
case $ACTION in
    deploy)
        # 检查卷是否存在，如果不存在则创建
        if ! docker volume ls | grep -qw "$VOLUME_NAME"; then
            log "Creating volume '$VOLUME_NAME'..."
            echo "Creating volume '$VOLUME_NAME'..."
            docker volume create --name "$VOLUME_NAME"
        fi

        # 检查容器是否存在
        if docker ps -a | grep -qw "$DOCKER_NAME"; then
            log "Container '$DOCKER_NAME' already exists. Stopping and removing it..."
            echo "Container '$DOCKER_NAME' already exists. Stopping and removing it..."
            docker stop "$DOCKER_NAME" && docker rm "$DOCKER_NAME"
        fi

        # 运行Jellyfin容器
        log "Starting Jellyfin container '$DOCKER_NAME'..."
        echo "Starting Jellyfin container '$DOCKER_NAME'..."
        docker run -d \
                   --name "$DOCKER_NAME" \
                   --restart always \
                   --volume "$VOLUME_NAME:$CONFIG_DIR" \
                   --publish "$HTTP_PORT:8096" \
                   --publish "$UDP_PORT:8097/udp" \
                   -e JELLYFIN_LOG_LEVEL="$LOG_LEVEL" \
                   jellyfin/jellyfin

        log "Jellyfin container '$DOCKER_NAME' has been started successfully."
        echo "Jellyfin container '$DOCKER_NAME' has been started successfully."
        ;;
    uninstall)
        # 卸载容器和卷
        if docker ps -a | grep -qw "$DOCKER_NAME"; then
            log "Stopping container '$DOCKER_NAME'..."
            echo "Stopping container '$DOCKER_NAME'..."
            docker stop "$DOCKER_NAME"
            log "Removing container '$DOCKER_NAME'..."
            echo "Removing container '$DOCKER_NAME'..."
            docker rm "$DOCKER_NAME"
        else
            log "Container '$DOCKER_NAME' does not exist."
            echo "Container '$DOCKER_NAME' does not exist."
        fi

        if docker volume ls | grep -qw "$VOLUME_NAME"; then
            log "Removing volume '$VOLUME_NAME'..."
            echo "Removing volume '$VOLUME_NAME'..."
            docker volume rm "$VOLUME_NAME"
        else
            log "Volume '$VOLUME_NAME' does not exist."
            echo "Volume '$VOLUME_NAME' does not exist."
        fi

        log "Uninstallation complete."
        echo "Uninstallation complete."
        ;;
    *)
        log "Unsupported action '$ACTION'. Supported actions are 'deploy' or 'uninstall'."
        echo "Unsupported action '$ACTION'. Supported actions are 'deploy' or 'uninstall'."
        exit 1
        ;;
esac

使用这个脚本非常简单。以下是详细的步骤，帮助你正确地运行和使用这个脚本：

### 步骤 1: 创建并保存脚本文件

1. **打开终端**：在 Linux 或 macOS 上，你可以通过快捷键 `Cmd + Space`（Mac）或 `Ctrl + Alt + T`（Linux）打开终端。
2. **创建脚本文件**：使用你喜欢的文本编辑器创建一个新文件。这里以 `nano` 编辑器为例：

   ```bash
   nano deploy_jellyfin.sh
   ```

3. **复制并粘贴脚本内容**：将前面提供的完整脚本内容复制并粘贴到编辑器中。
4. **保存并退出编辑器**：
   - 在 `nano` 编辑器中，按 `Ctrl + X`，然后按 `Y` 键确认保存，最后按 `Enter` 键确定文件名。

### 步骤 2: 赋予执行权限

确保脚本文件具有可执行权限：

```bash
chmod +x deploy_jellyfin.sh
```

### 步骤 3: 运行脚本

#### 使用默认参数部署 Jellyfin

如果你想要使用默认参数来部署 Jellyfin，只需运行以下命令：

```bash
./deploy_jellyfin.sh
```

#### 使用自定义参数部署 Jellyfin

如果你需要自定义参数，可以在命令后面添加相应的选项。例如：

```bash
./deploy_jellyfin.sh --name custom-name --volume custom-volume --http-port 8080 --udp-port 8081 --log-level debug
```

#### 查看帮助信息

如果你不确定如何使用脚本，可以通过 `--help` 或 `-h` 参数查看帮助信息：

```bash
./deploy_jellyfin.sh --help
```

#### 卸载 Jellyfin

要卸载 Jellyfin 及其相关卷，可以使用 `--action uninstall` 参数：

```bash
./deploy_jellyfin.sh --action uninstall
```

### 示例场景

假设你想以默认设置部署 Jellyfin，并查看脚本执行的详细过程，你可以这样做：

（代码助手演示如何执行脚本）

```bash
# 打开终端
$ nano deploy_jellyfin.sh  # 创建并编辑脚本文件
# 粘贴脚本内容，保存并退出
$ chmod +x deploy_jellyfin.sh  # 赋予执行权限
$ ./deploy_jellyfin.sh          # 运行脚本
```

如果一切正常，脚本将会下载 Jellyfin 镜像（如果还没有下载过的话），创建卷，然后启动容器。

（代码助手观察终端输出，确保脚本按照预期执行）

### 具体示例

假设你想使用自定义名称和端口来部署 Jellyfin：

```bash
$ ./deploy_jellyfin.sh --name myjellyfin --http-port 8090 --udp-port 8091
```

假设你想查看帮助信息：

```bash
$ ./deploy_jellyfin.sh --help
```

假设你想卸载 Jellyfin 及其相关卷：

```bash
$ ./deploy_jellyfin.sh --action uninstall
```

### 日志记录

脚本会将关键的信息记录在 `deploy_jellyfin.log` 文件中。你可以随时查看这个文件来获取脚本执行的历史记录：

```bash
cat deploy_jellyfin.log
```

### 