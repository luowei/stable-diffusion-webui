#!/bin/bash

# 检查 sdwebui 和 webui.sh 是否已经启动
is_webui_running() {
    pgrep -f "webui.sh" > /dev/null 2>&1
}

is_sdwebui_running() {
    pgrep -f "sdwebui" > /dev/null 2>&1
}

create_systemd_service() {
    cat <<EOF | sudo tee /etc/systemd/system/sdwebui.service
[Unit]
Description=Stable Diffusion Web UI
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/docker/sdwebui
ExecStart=/opt/docker/sdwebui/run.sh start service
Restart=on-failure
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
}

enable_launch_start() {
    create_systemd_service
    sudo systemctl enable sdwebui.service
    echo "sdwebui 服务已设置为开机启动。"
}

disable_launch_start() {
    sudo systemctl disable sdwebui.service
    echo "sdwebui 服务已禁用开机启动。"
}

start() {
    
    if is_webui_running; then
        echo "sdwebui 已经启动，跳过启动步骤。"
    else
        pushd /opt/docker/sdwebui || { echo "目录不存在"; exit 1; }
        
        echo "启动 sdwebui..."
        # source ./venv/bin/activate  # 激活虚拟环境（如果使用）
        
        # 检查是否为 systemd 服务运行环境
        if [[ "$2" == "service" ]]; then
            ./webui.sh > webui.log 2>&1  # 不在后台运行
            # 保持脚本运行，直到 sdwebui 进程结束
            while is_sdwebui_running; do
                sleep 1
            done
        else
            nohup ./webui.sh > webui.log 2>&1 &  # 在后台运行
        fi
        
        echo "sdwebui 启动中..."
        
        popd  # 返回原始目录
    fi
    
}

stop() {
    if is_webui_running || is_sdwebui_running; then
        echo "停止 sdwebui 和 webui.sh..."
        if is_webui_running; then
            pkill -f "webui.sh"
            echo "webui.sh 已停止。"
        fi
        if is_sdwebui_running; then
            pkill -f "sdwebui"
            echo "sdwebui 已停止。"
        fi
    else
        echo "sdwebui 和 webui.sh 未运行，无需停止。"
    fi
}

restart() {
    stop
    start
}

status() {
    if is_webui_running; then
        echo "sdwebui 正在运行。"
    else
        echo "sdwebui 未运行。"
    fi
}

# 获取输入参数，默认是 start
ACTION="${1:-start}"


# 根据输入参数执行相应的操作
case $ACTION in
    start)
        start "$@"
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    enable_launch_start)
        enable_launch_start
        ;;
    disable_launch_start)
        disable_launch_start
        ;;
    *)
        echo "无效的参数: $1"
        echo "使用方法: $0 [start|stop|restart|status|enable_launch_start|disable_launch_start]"
        exit 1
        ;;
esac

