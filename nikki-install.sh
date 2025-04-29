#!/bin/bash

# ========== 全局变量定义 ==========
SCRIPT_LOG="/tmp/nikki-install.log"
NIKKI_SERVICE_PATH="/etc/init.d/nikki"
NIKKI_PROFILE_DIR="/etc/nikki/profiles"
CONFIG_APPLIED_MARKER="/var/run/nikki_config_applied"
LOG_DIR="/tmp/log"
APP_LOG="$LOG_DIR/nikki/app.log"

# URL配置
FEED_URL="https://github.com/nikkinikki-org/OpenWrt-nikki/raw/refs/heads/main/feed.sh"
NIKKI_CONFIG_URL="https://raw.githubusercontent.com/Heart-Stealer/nikki/main/nikki.yaml"
PROXY_CONFIG_URL="https://raw.githubusercontent.com/Heart-Stealer/myclash/main/clashmetatest.yaml"
GH_PROXY="https://gh-proxy.com/"

# 软件包列表
PACKAGES=(
    "nikki"
    "luci-app-nikki"
    "luci-i18n-nikki-zh-cn"
)

# ========== 日志记录函数 ==========
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp - $1" | tee -a "$SCRIPT_LOG"
}

# ========== 辅助函数 ==========

# 检查网络连接
check_network() {
    log "检查网络连接..."
    if ping -c 3 8.8.8.8 &> /dev/null; then
        log "网络连接正常"
        return 0
    else
        log "错误：当前路由器无法连接互联网，请检查网络设置"
        return 1
    fi
}

# 从URL提取文件名
extract_filename() {
    basename "$1"
}

# 显示菜单并获取用户选择
show_menu() {
    local prompt="$1"
    local options=("${@:2}")
    local choice
    
    echo "$prompt"
    for i in "${!options[@]}"; do
        printf "%d) %s\n" $((i+1)) "${options[i]}"
    done
    
    while true; do
        read -p "请输入选择 (1-${#options[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#options[@]})); then
            return $((choice-1))
        fi
        log "无效输入，请重新选择"
    done
}

# ========== 核心功能函数 ==========

# 检查Nikki服务状态
check_nikki_service() {
    if [ -x "$NIKKI_SERVICE_PATH" ]; then
        if [ -f "$CONFIG_APPLIED_MARKER" ]; then
            log "Nikki服务已存在且已配置"
            return 0
        else
            show_menu "Nikki服务已存在但未配置，是否继续？" \
                      "继续配置" \
                      "退出安装"
            if [ $? -eq 1 ]; then
                log "安装已取消"
                exit 0
            fi
            return 1
        fi
    else
        log "Nikki服务未安装"
        return 1
    fi
}

# 下载Nikki安装脚本
download_nikki_feed() {
    local options=(
        "原始源地址 ($FEED_URL)"
        "代理镜像地址 ($GH_PROXY$FEED_URL)"
    )
    
    show_menu "请选择Nikki安装源：" "${options[@]}"
    local selected=$?
    
    local download_url
    if [ $selected -eq 0 ]; then
        download_url="$FEED_URL"
    else
        download_url="$GH_PROXY$FEED_URL"
    fi
    
    log "正在从 $download_url 下载Nikki安装脚本..."
    if curl -sSL "$download_url" | ash; then
        log "Nikki安装脚本下载成功"
        return 0
    else
        log "错误：Nikki安装脚本下载失败"
        return 1
    fi
}

# 安装Nikki软件包
install_packages() {
    log "开始安装Nikki相关软件包..."
    
    for pkg in "${PACKAGES[@]}"; do
        log "正在安装 $pkg ..."
        if ! opkg install "$pkg"; then
            log "错误：$pkg 安装失败"
            return 1
        fi
    done
    
    log "所有软件包安装完成"
    return 0
}

# 初始化Nikki配置
init_nikki_config() {
    log "正在初始化Nikki配置..."
    
    # 基本配置
    uci set nikki.config.profile='file:nikki.yaml'
    uci set nikki.config.test_profile='0'
    uci set nikki.config.fast_reload='1'
    uci set nikki.config.enabled='1'
    
    # 订阅设置
    uci set nikki.subscription.name='nikki'
    uci set nikki.subscription.url="$GH_PROXY/https://raw.githubusercontent.com/Heart-Stealer/myclash/main/nikkitest.yaml"
    uci set nikki.subscription.prefer='local'
    
    # 混合设置
    uci set nikki.mixin.log_level='warning'
    uci del nikki.mixin.mode >/dev/null 2>&1
    uci del nikki.mixin.match_process >/dev/null 2>&1
    uci del nikki.mixin.ipv6 >/dev/null 2>&1
    uci del nikki.mixin.api_secret >/dev/null 2>&1
    uci set nikki.mixin.ui_url="$GH_PROXY/https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip"
    uci del nikki.mixin.http_port >/dev/null 2>&1
    uci del nikki.mixin.socks_port >/dev/null 2>&1
    uci set nikki.mixin.redir_port='7893'
    uci set nikki.mixin.tproxy_port='7894'
    uci set nikki.mixin.authentication='0'
    uci del nikki.mixin.dns_ipv6 >/dev/null 2>&1
    uci del nikki.mixin.fake_ip_cache >/dev/null 2>&1
    
    # 代理设置
    uci set nikki.cfg0793d7.proxy='1'
    uci set nikki.cfg0893d7.enabled='0'
    uci set nikki.cfg0893d7.proxy='0'
    
    # LAN访问控制
    local lan_ips=("192.168.1.1" "192.168.1.150" "192.168.1.247" "192.168.1.192")
    for ip in "${lan_ips[@]}"; do
        uci add nikki lan_access_control
        uci set "nikki.@lan_access_control[-1].enabled=1"
        uci add_list "nikki.@lan_access_control[-1].ip=$ip"
        uci set "nikki.@lan_access_control[-1].proxy=1"
    done
    
    # 代理设置
    uci set nikki.proxy.bypass_china_mainland_ip='1'
    
    # DHCP设置
    uci del dhcp.cfg01411c.dns_redirect >/dev/null 2>&1
    uci del dhcp.cfg01411c.nonwildcard >/dev/null 2>&1
    uci del dhcp.cfg01411c.boguspriv >/dev/null 2>&1
    uci del dhcp.cfg01411c.filterwin2k >/dev/null 2>&1
    uci del dhcp.cfg01411c.filter_aaaa >/dev/null 2>&1
    uci del dhcp.cfg01411c.filter_a >/dev/null 2>&1
    
    uci commit
    
    # 标记已配置
    touch "$CONFIG_APPLIED_MARKER"
    log "Nikki配置初始化完成"
}

# 下载配置文件
download_config_files() {
    log "正在检查并下载配置文件..."
    mkdir -p "$NIKKI_PROFILE_DIR"
    
    # 使用关联数组定义配置文件和目标文件名
    declare -A config_map=(
        ["$NIKKI_CONFIG_URL"]="nikki.yaml"
        ["$PROXY_CONFIG_URL"]="proxy.yaml"
    )
    
    for url in "${!config_map[@]}"; do
        local filename="${config_map[$url]}"
        local dest="$NIKKI_PROFILE_DIR/$filename"
        
        if [ -f "$dest" ]; then
            show_menu "文件 $filename 已存在，是否覆盖？" \
                      "保留现有文件" \
                      "下载并覆盖"
            if [ $? -eq 0 ]; then
                continue
            fi
        fi
        
        show_menu "请选择 $filename 下载源：" \
                  "原始源 ($url)" \
                  "代理镜像 ($GH_PROXY$url)"
        local selected=$?
        
        local download_url
        if [ $selected -eq 0 ]; then
            download_url="$url"
        else
            download_url="$GH_PROXY$url"
        fi
        
        log "正在从 $download_url 下载 $filename ..."
        if ! wget -O "$dest" "$download_url"; then
            log "错误：$filename 下载失败"
            return 1
        fi
        log "$filename 下载成功"
    done
    
    return 0
}

# 启动Nikki服务
start_nikki_service() {
    log "正在设置Nikki服务自启动..."
    mkdir -p "$(dirname "$APP_LOG")"
    
    /etc/init.d/nikki enable
    /etc/init.d/nikki restart
    
    log "等待5秒让Nikki服务启动..."
    sleep 5
    
    # 检查服务状态
    if [ -f "$APP_LOG" ]; then
        if grep -q "Waiting timeout" "$APP_LOG"; then
            log "警告：TUN启动超时，正在重新加载Nikki..."
            /etc/init.d/nikki reload
        elif grep -q "\[App\] Exit" "$APP_LOG"; then
            log "警告：Nikki意外退出，正在重新加载..."
            /etc/init.d/nikki reload
        elif grep -q "Tun device is online\|successful" "$APP_LOG"; then
            log "Nikki启动成功"
        else
            log "Nikki正在运行，但日志中没有明确的启动状态"
        fi
    else
        log "警告：未找到Nikki日志文件 $APP_LOG"
    fi
}

# ========== 主程序 ==========
main() {
    # 1. 检查网络连接
    if ! check_network; then
        exit 1
    fi
    
    # 2. 检查Nikki服务状态
    if check_nikki_service; then
        # 服务已存在且已配置
        if [ -f "$NIKKI_PROFILE_DIR/nikki.yaml" ] && [ -f "$NIKKI_PROFILE_DIR/proxy.yaml" ]; then
            start_nikki_service
            exit 0
        fi
    else
        # 服务不存在或未配置
        if ! download_nikki_feed || ! install_packages; then
            log "错误：Nikki安装失败"
            exit 1
        fi
    fi
    
    # 3. 初始化配置
    init_nikki_config
    
    # 4. 下载配置文件
    if ! download_config_files; then
        log "错误：配置文件下载失败"
        exit 1
    fi
    
    # 5. 启动服务
    start_nikki_service
    
    log "Nikki安装和配置完成"
}

# 执行主程序
main