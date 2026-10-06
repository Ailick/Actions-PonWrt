#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
echo 'src-git pon_drivers https://github.com/pbs05/openwrt-pon-drivers.git' >>feeds.conf.default
echo 'src-git pon_userspace https://github.com/pbs05/openwrt-pon-userspace.git' >>feeds.conf.default

PATCH_DIR="$GITHUB_WORKSPACE/patch"

LIST_FILE="$GITHUB_WORKSPACE/del.list"

SOURCE_DIR="$GITHUB_WORKSPACE/dir"

if [ -f "$LIST_FILE" ]; then
    echo "开始删除列表中的文件..."
    while IFS= read -r file_path || [ -n "$file_path" ]; do
        case "$file_path" in
            ''|\#*) continue ;;
        esac
        if [ -e "$file_path" ]; then
            rm -f "$file_path"
            echo "已删除: $file_path"
        else
            echo "文件不存在，跳过: $file_path"
        fi
    done < "$LIST_FILE"
else
    echo "列表文件 '$LIST_FILE' 不存在或不是普通文件，跳过删除步骤。"
fi

if [ -d "$SOURCE_DIR" ]; then
    echo "开始复制 '$SOURCE_DIR' 到当前目录..."
    cp -rf "$SOURCE_DIR"/. .
    echo "复制完成。"
else
    echo "源目录 '$SOURCE_DIR' 不存在或不是目录，跳过复制步骤。"
fi

if [ -d "$PATCH_DIR" ]; then
    echo "===== 开始应用补丁 (来源: $PATCH_DIR) ====="
    for patch_file in "$PATCH_DIR"/*.patch; do
        [ -e "$patch_file" ] || continue
        patch_name="$(basename "$patch_file")"
        echo "--- 应用: $patch_name"

        if git apply --whitespace=fix "$patch_file" 2>/dev/null; then
            echo "    [OK] git apply 成功"
        else
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
