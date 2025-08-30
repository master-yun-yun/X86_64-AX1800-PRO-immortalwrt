#!/bin/bash

#----------------------------2025.07.13------以下新增istore相关------------------------#

# 在脚本开头添加所有必要的软件源
##echo "Adding software feeds to feeds.conf.default"

# 检查并添加iStore软件源
##echo >> ../feeds.conf.default
##echo 'src-git istore https://github.com/linkease/istore;main' >> ../feeds.conf.default

# 添加NAS软件源
##echo >> ../feeds.conf.default
##echo 'src-git nas https://github.com/linkease/nas-packages.git;master' >> ../feeds.conf.default
##echo >> ../feeds.conf.default
##echo 'src-git nas_luci https://github.com/linkease/nas-packages-luci.git;main' >> ../feeds.conf.default

# 更新并安装所有添加的软件源
##echo "Updating and installing feeds"
##../scripts/feeds update istore nas nas_luci
##../scripts/feeds install -d y -p istore luci-app-store
##../scripts/feeds install -a -p nas
##../scripts/feeds install -a -p nas_luci
##echo "All feeds added and installed successfully"

#----------------------------2025.07.13------以上新增istore相关------------------------#

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}

	echo " "

	# 删除本地可能存在的不同名称的软件包
	for NAME in "${PKG_LIST[@]}"; do
		# 查找匹配的目录
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		# 删除找到的目录
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not fonud directory: $NAME"
		fi
	done

	# 克隆 GitHub 仓库
	git clone --depth=10 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

 	#--------以下原代码--------恢复时取消“##”（2个#）------#
	### 处理克隆的仓库
	##if [[ $PKG_SPECIAL == "pkg" ]]; then
		##find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
		##rm -rf ./$REPO_NAME/
	##elif [[ $PKG_SPECIAL == "name" ]]; then
		##mv -f $REPO_NAME $PKG_NAME
	##fi
##}
	#--------以上原代码--------恢复时取消“##”（2个#）------#
 
	# 处理克隆的仓库
 	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
  	  # 修改后的 find 命令：覆盖深层目录（如 relevance/filebrowser）
  	  find ./$REPO_NAME/ -maxdepth 10 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
  	  rm -rf ./$REPO_NAME/
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
  	  # 原逻辑：直接重命名仓库目录（适用于插件与仓库同名的情况）
  	  mv -f $REPO_NAME $PKG_NAME
	fi
}

# 调用示例
# UPDATE_PACKAGE "OpenAppFilter" "destan19/OpenAppFilter" "master" "" "custom_name1 custom_name2"
# UPDATE_PACKAGE "open-app-filter" "destan19/OpenAppFilter" "master" "" "luci-app-appfilter oaf" 这样会把原有的open-app-filter，luci-app-appfilter，oaf相关组件删除，不会出现coremark错误。

# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-24.10"
UPDATE_PACKAGE "theme-kucat" "sirpdboy/luci-theme-kucat" "js"
UPDATE_PACKAGE "kucat-config" "sirpdboy/luci-app-kucat-config" "main"

UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "xiaorouji/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "xiaorouji/openwrt-passwall2" "main" "pkg"

UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"

#UPDATE_PACKAGE "alist" "sbwml/luci-app-alist" "main"
UPDATE_PACKAGE "openlist" "sbwml/luci-app-openlist" "main"
UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"
#UPDATE_PACKAGE "diskman" "lisaac/luci-app-diskman" "master"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
#UPDATE_PACKAGE "gecoosac" "lwb1978/openwrt-gecoosac" "main"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
#UPDATE_PACKAGE "netspeedtest" "sirpdboy/luci-app-netspeedtest" "js" "" "homebox speedtest"
#UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
#UPDATE_PACKAGE "qbittorrent" "sbwml/luci-app-qbittorrent" "master" "" "qt6base qt6tools rblibtorrent"
#UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main"
UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "luci-app-timewol luci-app-wolplus vlmcsd"
UPDATE_PACKAGE "vnt" "lmq8267/luci-app-vnt" "main"

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-false}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo -e "\n$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
		local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
		local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
		local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
		local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")

		local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")

		local NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
		local NEW_URL=$(echo $PKG_URL | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
		local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

		echo "old version: $OLD_VER $OLD_HASH"
		echo "new version: $NEW_VER $NEW_HASH"

		if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
UPDATE_VERSION "sing-box"
UPDATE_VERSION "tailscale"

#---------------------------------以下自定义源-------------------------------------#
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-24.10"

#全能推送PushBot----OK
UPDATE_PACKAGE "luci-app-pushbot" "zzsj0928/luci-app-pushbot" "master"

#关机poweroff----OK
UPDATE_PACKAGE "luci-app-poweroff" "DongyangHu/luci-app-poweroff" "main"

#主题界面edge----OK
UPDATE_PACKAGE "luci-theme-edge" "ricemices/luci-theme-edge" "master"

#分区扩容----OK
UPDATE_PACKAGE "luci-app-partexp" "sirpdboy/luci-app-partexp" "main"

#阿里云盘aliyundrive-webdav----OK
UPDATE_PACKAGE "luci-app-aliyundrive-webdav" "messense/aliyundrive-webdav" "main"
#UPDATE_PACKAGE "aliyundrive-webdav" "master-yun-yun/aliyundrive-webdav" "main" "pkg"
#UPDATE_PACKAGE "luci-app-aliyundrive-webdav" "master-yun-yun/aliyundrive-webdav" "main"

#服务器
#UPDATE_PACKAGE "luci-app-openvpn-server" "hyperlook/luci-app-openvpn-server" "main"
#UPDATE_PACKAGE "luci-app-openvpn-server" "ixiaan/luci-app-openvpn-server" "main"

#luci-app-navidrome音乐服务器----OK
UPDATE_PACKAGE "luci-app-navidrome" "tty228/luci-app-navidrome" "main"

#luci-theme-design主题界面----OK
#UPDATE_PACKAGE "luci-theme-design" "emxiong/luci-theme-design" "master"
#luci-app-design-config主题配置----OK
#UPDATE_PACKAGE "luci-app-design-config" "kenzok78/luci-app-design-config" "main"

#luci-app-quickstart
#UPDATE_PACKAGE "luci-app-quickstart" "animegasan/luci-app-quickstart" "main"

#端口转发luci-app-socat----OK
UPDATE_PACKAGE "luci-app-socat" "WROIATE/luci-app-socat" "main"

#timecontrol 上网时间控制插件 -- 上网时间控制NFT版2.0.2版==专门针对24.10分支，适配NFT的上网时间控制插件。
#UPDATE_PACKAGE "luci-app-timecontrol" "sirpdboy/luci-app-timecontrol" "main"
#timecontrol 上网时间控制插件 -- 自适应FW3/FW4防火墙，支持IPv4/IPv6。改自Lienol原版luci-app-timecontrol FW3版本
UPDATE_PACKAGE "luci-app-timecontrol" "gaobin89/luci-app-timecontrol" "main" 

#luci-app-taskplan 任务设置2.0版
UPDATE_PACKAGE "luci-app-taskplan" "sirpdboy/luci-app-taskplan" "master"

#---------------------------------以下自定义源-------------------------------------#

#-------------------2025.04.12-测试-----------------#
#UPDATE_PACKAGE "luci-app-clouddrive2" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"

UPDATE_PACKAGE "istoreenhance" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
UPDATE_PACKAGE "luci-app-istoreenhance" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"

UPDATE_PACKAGE "linkmount" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
UPDATE_PACKAGE "linkease" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
UPDATE_PACKAGE "luci-app-linkease" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"

UPDATE_PACKAGE "quickstart" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
UPDATE_PACKAGE "luci-app-quickstart" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
#UPDATE_PACKAGE "quickstart" "master-yun-yun/package-i" "Immortalwrt" "pkg"
#UPDATE_PACKAGE "luci-app-quickstart" "master-yun-yun/package-i" "Immortalwrt" "pkg"

UPDATE_PACKAGE "luci-app-store" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
# 以下PATCH: 修正 luci-app-store Makefile-----------2025.07.13------------------------------------------#
#LCS_MK=$(find ./luci-app-store -type f -name Makefile | head -n 1)
#if [ -f "$LCS_MK" ]; then
    #echo "Patching luci-app-store Makefile: $LCS_MK"
    #sed -i -E 's/^(PKG_VERSION:=)([0-9]+\.[0-9]+\.[0-9]+)-([0-9]+)$/\1\2\nPKG_RELEASE:=\3/' "$LCS_MK"
#else
    #echo "luci-app-store Makefile not found for patch!"
#fi
# 以上PATCH: 修正 luci-app-store Makefile-----------2025.07.13------------------------------------------#

#---------------------------2025.07.12----------------------#
#git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
#UPDATE_PACKAGE "app-store-ui" "linkease/istore-ui" "main" "pkg"
#git_sparse_clone main https://github.com/linkease/istore luci
#UPDATE_PACKAGE "luci" "linkease/istore" "main" "pkg"

#UPDATE_PACKAGE "istore" "linkease/istore" "main" "pkg"
#UPDATE_PACKAGE "luci-app-store" "linkease/istore" "main" "pkg"
#---------------------------2025.07.12----------------------#

UPDATE_PACKAGE "webdav2" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
UPDATE_PACKAGE "unishare" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
UPDATE_PACKAGE "luci-app-unishare" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
UPDATE_PACKAGE "luci-app-daed" "QiuSimons/luci-app-daed" "master"
#luci-app-athena-led-雅典娜led屏幕显示（第一个源显示效果不好）
#UPDATE_PACKAGE "luci-app-athena-led" "haipengno1/luci-app-athena-led" "main"
UPDATE_PACKAGE "luci-app-athena-led" "NONGFAH/luci-app-athena-led" "main"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"
UPDATE_PACKAGE "momo" "nikkinikki-org/OpenWrt-momo" "main"
#-------------------2025.04.12-测试-----------------#
# 添加雅典娜LED执行权限
if [ -d "luci-app-athena-led" ]; then
    chmod +x luci-app-athena-led/root/etc/init.d/athena_led
    chmod +x luci-app-athena-led/root/usr/sbin/athena-led
    echo "Added execute permissions for athena_led files."
fi
#-------------------2025.05.31-测试-----------------#
# 删除官方的v2ray-geodata和daed相关文件
rm -rf ../feeds/luci/applications/luci-app-{passwall*,mosdns,dockerman,dae*,bypass*}
rm -rf ../feeds/packages/net/{v2ray-geodata,dae*}
#修复daed/Makefile
rm -rf luci-app-daed/daed/Makefile && cp -r $GITHUB_WORKSPACE/patches/daed/Makefile luci-app-daed/daed/
cat luci-app-daed/daed/Makefile
