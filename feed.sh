#!/bin/sh
# /raw/main/
# /raw/refs/heads/main/

# Nikki's feed

# check env
if [[ ! -x "/bin/opkg" && ! -x "/usr/bin/apk" || ! -x "/sbin/fw4" ]]; then
	echo "only supports OpenWrt build with firewall4!"
	exit 1
fi

# https://nikkinikki.pages.dev/key-build.pub
# https://nikkinikki.pages.dev/openwrt-24.10/mipsel_24kc/nikki
# https://nikkinikki.pages.dev/openwrt-24.10/mipsel_24kc/nikki/Packages.gz

# https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/raw/refs/heads/main/key-build.pub
# https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/raw/refs/heads/main/Packages.gz
# packages="https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/releases/download/nikki_tag/Packages.gz"
# my_feed_url="/root/nikki"
# https://github.com/Heart-Stealer/nikki/releases/download/nikki/key-build.pub
# https://github.com/Heart-Stealer/nikki/releases/download/nikki/Packages.gz
repository_url="https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/releases/download/nikki"
nikki_feeds="/etc/opkg/customfeeds.conf"
echo "$repository_url"
echo "$nikki_feeds"

if [ -x "/bin/opkg" ]; then
  # add key
  echo "add key"
  key_build_pub_file="key-build.pub"
  curl -s -L -o "$key_build_pub_file" "$repository_url/key-build.pub"
  opkg-key add "$key_build_pub_file"
  rm -f "$key_build_pub_file"
  # add feed
  echo "add feed"
  if (grep -q nikki $nikki_feeds); then
    sed -i.bak /etc/opkg/distfeeds.conf \
        -i '/nikki/d' $nikki_feeds
  fi
  echo "src/gz nikki_my $repository_url/Packages.gz" >> $nikki_feeds
  # update feeds
  echo "update feeds"
  # opkg update
fi

echo "success"

# only needs to be run once
# curl -s -L https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/raw/refs/heads/main/feed.sh | ash
# curl -s -L https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/raw/refs/heads/main/feed.sh | ash
# curl -s -L https://github.com/nikkinikki-org/OpenWrt-nikki/raw/refs/heads/main/feed.sh | ash
#!/bin/sh

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
