#!/bin/sh

# Nikki's feed

# check env
if [[ ! -x "/bin/opkg" && ! -x "/usr/bin/apk" || ! -x "/sbin/fw4" ]]; then
	echo "only supports OpenWrt build with firewall4!"
	exit 1
fi

# curl -s -L https://github.com/nikkinikki-org/OpenWrt-nikki/raw/refs/heads/main/feed.sh | ash
# https://nikkinikki.pages.dev/key-build.pub
# https://nikkinikki.pages.dev/openwrt-24.10/mipsel_24kc/nikki
# https://nikkinikki.pages.dev/openwrt-24.10/mipsel_24kc/nikki/Packages.gz

# curl -s -L https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/raw/refs/heads/main/nikki_feed.sh | ash
# curl -s -L https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/raw/refs/heads/main/nikki_feed.sh | ash
# /raw/main/
# /raw/refs/heads/main/
# https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/raw/refs/heads/main/key-build.pub
# https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/releases/download/nikki/key-build.pub
# packages="https://gh-proxy.com/https://github.com/Heart-Stealer/nikki/releases/download/nikki/Packages.gz"
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
  if (grep -q nikki "$nikki_feeds"); then
    sed -i.bak '/nikki/d' "$nikki_feeds"
  fi
  echo "src/gz nikki $repository_url" >> $nikki_feeds
  # update feeds
  echo "update feeds"
  # opkg update
else
  exit 1
fi
echo "success"
# 执行opkg update
opkg update
# 检查opkg update的返回值
if [ $? -eq 0 ]; then
    echo "opkg update 成功，开始安装软件包"
    opkg install nikki
    opkg install luci - app - nikki
    opkg install luci - i18n - nikki - zh - cn
else
    echo "opkg update 失败，无法安装软件包"
    exit 1
fi
exit 0
