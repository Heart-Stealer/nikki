#!/bin/sh

# curl -s -L https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/raw/refs/heads/main/ai_feed.sh | ash
# 下载文件
wget -O ai_feeds.conf https://dl.openwrt.ai/packages-24.10/mipsel_24kc/feeds.conf

# 检查文件是否下载成功
if [ -f ai_feeds.conf ]; then
    # 将文件移动到/etc/opkg目录
    mv ai_feeds.conf /etc/opkg/
    echo "文件已成功移动到 /etc/opkg/ 目录"
else
    echo "文件下载失败"
fi
