#!/usr/bin/env bash
# Build the iOS release and install it onto a connected iPhone/iPad.
# Usage: ./scripts/deploy_ios.sh [--no-build]
#   --no-build  Skip flutter build and install the existing build output.

set -euo pipefail

cd "$(dirname "$0")/.."

APP_PATH="build/ios/iphoneos/Runner.app"
SKIP_BUILD=false
[[ "${1:-}" == "--no-build" ]] && SKIP_BUILD=true

echo "==> 正在查找已连接的设备..."
DEVICE_LIST="$(xcrun devicectl list devices 2>/dev/null)"

# 提取包含 UUID 的行：名称 + UUID + 状态
DEVICES=()
while IFS= read -r line; do
  uuid="$(echo "$line" | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' || true)"
  [[ -z "$uuid" ]] && continue
  name="$(echo "$line" | sed -E 's/   +.*$//' | sed 's/[[:space:]]*$//')"
  state="unavailable"
  echo "$line" | grep -q "available" && ! echo "$line" | grep -q "unavailable" && state="available"
  DEVICES+=("$uuid|$name|$state")
done <<< "$DEVICE_LIST"

if [[ ${#DEVICES[@]} -eq 0 ]]; then
  echo "❌ 没有找到任何设备。请确认 iPhone 已用数据线连接并解锁。"
  exit 1
fi

echo ""
echo "可用设备："
i=1
for entry in "${DEVICES[@]}"; do
  IFS='|' read -r uuid name state <<< "$entry"
  if [[ "$state" == "available" ]]; then
    echo "  $i) $name  ✅"
  else
    echo "  $i) $name  （离线）"
  fi
  ((i++))
done
echo ""

if [[ ${#DEVICES[@]} -eq 1 ]]; then
  CHOICE=1
  echo "只有一台设备，自动选择。"
else
  read -rp "选择要安装的设备编号: " CHOICE
fi

if ! [[ "${CHOICE}" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#DEVICES[@]} )); then
  echo "❌ 无效的选择：${CHOICE}"
  exit 1
fi

IFS='|' read -r DEVICE_ID DEVICE_NAME DEVICE_STATE <<< "${DEVICES[$((CHOICE-1))]}"

if [[ "$DEVICE_STATE" != "available" ]]; then
  echo "❌ 「${DEVICE_NAME}」当前离线，请连接并解锁后重试。"
  exit 1
fi

if [[ "$SKIP_BUILD" == false ]]; then
  echo ""
  echo "==> 构建 release 包（约 5 分钟）..."
  flutter build ios --release
elif [[ ! -d "${APP_PATH}" ]]; then
  echo "❌ 找不到 ${APP_PATH}，请先去掉 --no-build 构建一次。"
  exit 1
fi

echo ""
echo "==> 安装到「${DEVICE_NAME}」..."
xcrun devicectl device install app --device "$DEVICE_ID" "${APP_PATH}"

echo ""
echo "✅ 完成！可以在手机桌面打开 App 了。"
