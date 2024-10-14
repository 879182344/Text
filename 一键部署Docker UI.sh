当然有进一步优化的空间！为了提高脚本的健壮性和用户体验，可以考虑以下几个方面：

1. **错误处理**：增加错误处理逻辑，确保在某些步骤失败时能够提供明确的错误信息。
2. **日志记录**：增加日志记录功能，帮助诊断问题。
3. **用户交互**：增加一些提示信息，让用户知道当前的状态。
4. **环境变量配置**：使用环境变量来灵活配置端口和其他设置。
5. **容器健康检查**：确保容器启动成功后再继续下一步。

下面是一个经过优化的脚本版本：

```bash
#!/bin/bash

# 定义默认端口和容器名称
PORTAINER_PORT="9000"
COMPOSE_UI_PORT="8080"
COMPOSE_API_PORT="8081"
CONTAINER_NAME_PORTAINER="portainer"
CONTAINER_NAME_COMPOSE_UI="docker-compose-ui"
CONTAINER_NAME_COMPOSE_API="docker-compose-api"

# 检查是否已经存在同名容器，如果存在则删除
cleanup_existing_containers() {
    local container_names="$@"
    for container_name in ${container_names[@]}; do
        existing_containers=$(docker ps -a --filter "name=$container_name" --format "{{.Names}}")
        if [[ $existing_containers ]]; then
            echo "Stopping and removing existing '$container_name' container..."
            docker stop $existing_containers
            docker rm $existing_containers
        fi
    done
}

# 创建目录存放Portainer数据
ensure_data_directory() {
    mkdir -p /opt/portainer/data
}

# 拉取Portainer镜像并启动容器
start_portainer_container() {
    docker run -d --name "$CONTAINER_NAME_PORTAINER" \
               --restart always \
               -v /var/run/docker.sock:/var/run/docker.sock \
               -v /opt/portainer/data:/data \
               -p "${PORTAINER_PORT}:${PORTAINER_PORT}" \
               portainer/portainer-ce
}

# 拉取Docker Compose UI API镜像并启动容器
start_compose_api_container() {
    docker run -d --name "$CONTAINER_NAME_COMPOSE_API" \
               --restart always \
               -e COMPOSE_API_ENDPOINT=http://localhost:${COMPOSE_API_PORT}/v1.24 \
               -p "${COMPOSE_API_PORT}:${COMPOSE_API_PORT}" \
               docker-compose-api
}

# 拉取Docker Compose UI镜像并启动容器
start_compose_ui_container() {
    docker run -d --name "$CONTAINER_NAME_COMPOSE_UI" \
               --restart always \
               -e REACT_APP_API_ENDPOINT=http://localhost:${COMPOSE_API_PORT} \
               -p "${COMPOSE_UI_PORT}:${COMPOSE_UI_PORT}" \
               docker-compose-ui
}

# 确认容器已经启动
check_container_status() {
    echo "Checking if containers are running..."
    sleep 5 # 等待容器启动完成
    docker ps | grep "$CONTAINER_NAME_PORTAINER"
    docker ps | grep "$CONTAINER_NAME_COMPOSE_UI"
    docker ps | grep "$CONTAINER_NAME_COMPOSE_API"
}

# 提示用户访问Portainer和Docker Compose UI
notify_user() {
    echo "Portainer is now available at http://$(hostname):${PORTAINER_PORT}"
    echo "Docker Compose UI is now available at http://$(hostname):${COMPOSE_UI_PORT}"
}

# 主函数
main() {
    # 清理旧容器
    cleanup_existing_containers "$CONTAINER_NAME_PORTAINER" "$CONTAINER_NAME_COMPOSE_UI" "$CONTAINER_NAME_COMPOSE_API"
    
    # 确保数据目录存在
    ensure_data_directory
    
    # 启动容器
    start_portainer_container
    start_compose_api_container
    start_compose_ui_container
    
    # 检查容器状态
    check_container_status
    
    # 通知用户
    notify_user
}

# 执行主函数
main
```

赋予脚本执行权限并运行`./deploy.sh`

