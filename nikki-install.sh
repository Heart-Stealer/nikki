#!/bin/bash
# Nikki服务自动安装和配置脚本

# 同时输出到终端和日志文件
exec > >(tee -a "/tmp/nikki-install.log") 2>&1

# ========== 初始化变量 ==========
log_dir="/tmp/log"                          # 日志文件存放目录
app_log="$log_dir/nikki/app.log"            # Nikki应用日志路径
script_log="$log_dir/nikki-install.log"     # 脚本执行日志路径

# 配置文件下载URL（备用镜像）
config_url_1="https://gh-proxy.com/https://raw.githubusercontent.com/Heart-Stealer/nikki/main/nikki.yaml"
config_url_2="https://raw.githubusercontent.com/Heart-Stealer/nikki/main/nikki.yaml"
proxy_url_1="https://gh-proxy.com/https://raw.githubusercontent.com/Heart-Stealer/myclash/main/clashmetatest.yaml"
proxy_url_2="https://raw.githubusercontent.com/Heart-Stealer/myclash/main/clashmetatest.yaml"

# 目标目录和重试参数
target_dir="/etc/nikki/profiles"            # 配置文件存放目录
max_retries=3                               # 最大重试次数
short_delay=3                               # 短延迟时间（秒）
long_delay=30                               # 长延迟时间（秒）
# Nikki安装相关
nikki_install_script="https://gh-proxy.com/https://github.com/nikkinikki-org/OpenWrt-nikki/raw/refs/heads/main/feed.sh"
nikki_pkgs="nikki luci-app-nikki luci-i18n-nikki-zh-cn"

# ========== 日志记录函数 ==========
log() {
    # 记录带时间戳的日志信息
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$script_log"
}

# ========== 网络检查函数 ==========
check_network() {
    local retries=0
    while [ $retries -lt $max_retries ]; do
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            log "网络检查函数,网络连接正常"
            return 0
        fi
        retries=$((retries + 1))
        log "网络检查函数,网络连接异常，第 $retries 次重试..."
        sleep $short_delay
    done
    log "网络检查函数,错误：网络连接检查失败，请检查网络后重试"
    return 1
}

# ========== 安装Nikki服务函数 ==========
install_nikki() {
    log "安装Nikki服务函数,开始安装Nikki服务..."
    
    # 下载并执行安装脚本
    curl -s -L "$nikki_install_script" | ash
    if [ $? -ne 0 ]; then
        log "安装Nikki服务函数,错误：Nikki安装脚本下载失败"
        return 1
    fi
    
    # 安装必要的软件包
    local pkg_errors=0
    for pkg in $nikki_pkgs; do
        opkg install $pkg || pkg_errors=$((pkg_errors+1))
    done
    
    if [ $pkg_errors -gt 0 ]; then
        log "安装Nikki服务函数,错误：有 $pkg_errors 个软件包安装失败"
        return 1
    fi
    
    log "安装Nikki服务函数,Nikki服务安装完成"
    return 0
}

# ========== 初始化Nikki配置函数 ==========
init_nikki_config() {
    log "初始化Nikki配置函数,开始初始化/etc/config/nikki配置..."
    
    # 检查nikki是否安装
    if [ ! -f "/etc/init.d/nikki" ]; then
        log "初始化Nikki配置函数,错误：Nikki未安装，无法初始化配置"
        return 1
    fi
    
    # 检查app_log是否已经有Tun device is online或者successful，有了则直接跳出nikki配置函数
    if [ -f "$app_log" ]; then
        if grep -q "Tun device is online" "$app_log" || grep -q "successful" "$app_log"; then
            log "初始化Nikki配置函数,日志文件中已包含Tun device is online或successful，跳过Nikki配置初始化"
            return 0
        fi
    else
        log "初始化Nikki配置函数,错误：Nikki未启动成功，开始nikki启动前配置"
    fi

    uci set nikki.config.profile='file:nikki.yaml'
    uci set nikki.config.test_profile='0'
    uci set nikki.config.fast_reload='1'
    uci set nikki.subscription.name='nikki'
    uci set nikki.subscription.url='https://gh-proxy.com/https://raw.githubusercontent.com/Heart-Stealer/myclash/main/nikkitest.yaml'
    uci set nikki.subscription.prefer='local'
    uci del nikki.mixin.log_level
    uci del nikki.mixin.mode
    uci del nikki.mixin.match_process
    uci del nikki.mixin.ipv6
    uci del nikki.mixin.api_secret
    uci set nikki.mixin.ui_url='https://gh-proxy.com/https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip'
    uci del nikki.mixin.http_port
    uci del nikki.mixin.socks_port
    uci set nikki.mixin.redir_port='7893'
    uci set nikki.mixin.tproxy_port='7894'
    uci set nikki.mixin.authentication='0'
    uci del nikki.mixin.dns_ipv6
    uci del nikki.mixin.fake_ip_cache
    uci set nikki.cfg0793d7.proxy='1'
    uci set nikki.cfg0893d7.enabled='0'
    uci set nikki.cfg0893d7.proxy='0'
    uci add nikki lan_access_control # =cfg16a831
    uci set nikki.@lan_access_control[-1].enabled='1'
    uci add_list nikki.@lan_access_control[-1].ip='192.168.1.1'
    uci set nikki.@lan_access_control[-1].proxy='1'
    uci add nikki lan_access_control # =cfg17a831
    uci set nikki.@lan_access_control[-1].enabled='1'
    uci add_list nikki.@lan_access_control[-1].ip='192.168.1.150'
    uci set nikki.@lan_access_control[-1].proxy='1'
    uci add nikki lan_access_control # =cfg18a831
    uci set nikki.@lan_access_control[-1].enabled='1'
    uci add_list nikki.@lan_access_control[-1].ip='192.168.1.247'
    uci set nikki.@lan_access_control[-1].proxy='1'
    uci add nikki lan_access_control # =cfg19a831
    uci set nikki.@lan_access_control[-1].enabled='1'
    uci add_list nikki.@lan_access_control[-1].ip='192.168.1.192'
    uci set nikki.@lan_access_control[-1].proxy='1'
    uci set nikki.proxy.bypass_china_mainland_ip='1'
    uci set nikki.config.enabled='1'

    uci del dhcp.cfg01411c.dns_redirect
    uci del dhcp.cfg01411c.nonwildcard
    uci del dhcp.cfg01411c.boguspriv
    uci del dhcp.cfg01411c.filterwin2k
    uci del dhcp.cfg01411c.filter_aaaa
    uci del dhcp.cfg01411c.filter_a

    # 提交配置更改
    uci commit nikki
    /etc/init.d/nikki restart
    log "初始化Nikki配置函数,Nikki配置初始化完成"
    return 0
}

# ========== 配置文件下载函数 ==========
download_config() {
    # 创建目标目录（如果不存在）
    mkdir -p "$target_dir"
    
    local download_count=0

    # 检查如果"$target_dir/nikki.yaml"和"$target_dir/clashmetatest.yaml"已经存在，则跳出download_config当前的函数
    if [ -f "$target_dir/nikki.yaml" ] && [ -f "$target_dir/clashmetatest.yaml" ]; then
        log "配置文件下载函数,nikki.yaml和clashmetatest.yaml均已存在，跳过下载"
        return 0
    fi

    # 检查并下载主配置文件（如果不存在）
    if [ ! -f "$target_dir/nikki.yaml" ]; then
        log "配置文件下载函数,未找到nikki.yaml，开始下载..."
        for url in "$config_url_1" "$config_url_2"; do
            wget -q -O "$target_dir/nikki.yaml" "$url"
            if [ $? -eq 0 ]; then
                log "nikki.yaml下载成功: $url"
                download_count=$((download_count+1))
                break
            else
                log "nikki.yaml下载失败: $url"
            fi
        done
    else
        log "配置文件下载函数,nikki.yaml已存在，跳过下载"
        download_count=$((download_count+1))
    fi
    
    # 检查并下载代理配置文件（如果不存在）
    if [ ! -f "$target_dir/clashmetatest.yaml" ]; then
        log "配置文件下载函数,未找到clashmetatest.yaml，开始下载..."
        for url in "$proxy_url_1" "$proxy_url_2"; do
            wget -q -O "$target_dir/clashmetatest.yaml" "$url"
            if [ $? -eq 0 ]; then
                log "clashmetatest.yaml下载成功: $url"
                download_count=$((download_count+1))
                break
            else
                log "clashmetatest.yaml下载失败: $url"
            fi
        done
    else
        log "配置文件下载函数,clashmetatest.yaml已存在，跳过下载"
        download_count=$((download_count+1))
    fi
    
    # 返回状态（至少成功下载一个文件返回0，全部失败返回1）
    [ $download_count -gt 0 ] && return 0 || return 1
}

# ========== 服务管理函数 ==========
manage_service() {
    # 设置开机自启动
    /etc/init.d/nikki enable
    log "服务管理函数,已设置Nikki开机自启动"
    
    # 启动服务
    /etc/init.d/nikki start
    log "服务管理函数,已启动Nikki服务"

    log "服务管理函数,manage_service等待 ${long_delay}秒让服务稳定运行..."
    sleep $long_delay

    # 重载配置
    /etc/init.d/nikki reload
    log "服务管理函数,已重载Nikki配置"
}

# ========== 主程序开始 ==========
log "主程序开始,=== Nikki服务安装配置脚本开始 ==="

# 检查Nikki是否已安装
if [ -d "/etc/nikki" ]; then
    log "主程序开始,检测到/etc/nikki目录已存在，跳过安装步骤"
else
    log "主程序开始,未检测到Nikki安装，开始安装流程..."
    
    # 检查网络连接
    if ! check_network; then
        exit 1
    fi
    
    # 安装Nikki服务
    if ! install_nikki; then
        log "主程序开始,错误：Nikki安装失败"
        exit 1
    fi

fi

# 短暂延迟确保服务就绪
log "等待 ${short_delay}秒让服务初始化..."
sleep $short_delay

# 管理服务
# manage_service

# ========== 配置文件下载 ==========
log "配置文件下载,开始下载配置文件..."
attempt=1
while [ $attempt -le $max_retries ]; do
    if download_config; then
        log "配置文件下载,配置文件下载成功"
        break
    fi
    
    # 如果两个文件都已存在，直接跳出循环
    if [ -f "$target_dir/nikki.yaml" ] && [ -f "$target_dir/clashmetatest.yaml" ]; then
        log "配置文件下载,配置文件均已存在，无需下载，跳过重试"
        break
    fi
    
    if [ $attempt -eq $max_retries ]; then
        log "配置文件下载,错误：配置文件下载失败，达到最大重试次数"
        exit 1
    fi
    
    attempt=$((attempt + 1))
    log "等待 ${short_delay}秒后重试($attempt/$max_retries)..."
    sleep $short_delay
done

# 初始化Nikki配置
init_nikki_config

# 重载服务配置
manage_service
# log "等待 ${long_delay}秒让服务稳定运行..."
# sleep $long_delay

# ========== 服务状态检查 ==========
log "检查服务运行状态..."
if [ -f "$app_log" ]; then
    if grep -q "[Proxy] Waiting timeout" "$app_log"; then
        log "警告：检测到代理超时问题，可能需要手动检查配置"
    fi
    
    if grep -q "[App] Exit" "$app_log"; then
        log "警告插件启动失败"
    fi
    if grep -q "Tun device is online" "$app_log"; then
        log "Tun device is online，正常启动日志，服务正常运行"
    fi
    if grep -q "successful" "$app_log"; then
        log "Hijack successful，正常启动日志，服务正常运行"
    fi
else
    log "警告：未找到应用日志文件，服务状态未知"
fi

log "=== Nikki服务安装配置完成 ==="
exit 0
