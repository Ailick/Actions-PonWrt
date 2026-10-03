#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate


PATCH_DIR="$GITHUB_WORKSPACE/patch"

if [ -d "$PATCH_DIR" ]; then
    echo "===== 开始应用补丁 (来源: $PATCH_DIR) ====="
    for patch_file in "$PATCH_DIR"/*.patch; do
        [ -e "$patch_file" ] || continue
        patch_name="$(basename "$patch_file")"
        echo "--- 应用: $patch_name"

        # 优先用 git apply（OpenWrt 源码是 git 仓库，更严格可靠）
        if git apply --whitespace=fix "$patch_file" 2>/dev/null; then
            echo "    [OK] git apply 成功"
        else
            # git apply 失败，回退到 patch -p1
            if patch -p1 --dry-run < "$patch_file" > /dev/null 2>&1; then
                patch -p1 < "$patch_file"
                echo "    [OK] patch -p1 成功"
            else
                echo "    [WARN] 无法应用，已跳过: $patch_name"
            fi
        fi
    done
    echo "===== 补丁应用完成 ====="
else
    echo "[INFO] 未找到 patch 目录 ($PATCH_DIR)，跳过补丁应用"
fi
