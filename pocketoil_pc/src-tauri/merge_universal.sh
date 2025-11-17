#!/bin/bash
set -e

# ==============================================
# 配置（必须修改！）
# ==============================================
APP_NAME="口袋原油PC"  # 应用名称
SIGN_IDENTITY="Developer ID Application: Nanjing Yuanlian Network Technology Co., Ltd (BHYBHZGP8X)"  # 签名证书
ENTITLEMENTS_FILE="./entitlements.plist"  # entitlements 文件路径（src-tauri 目录下）

# ==============================================
# 路径配置
# ==============================================
INTEL_ARCH="x86_64-apple-darwin"
ARM_ARCH="aarch64-apple-darwin"
BUILD_DIR="./target"
INTEL_APP_DIR="${BUILD_DIR}/${INTEL_ARCH}/release/bundle/macos"
ARM_APP_DIR="${BUILD_DIR}/${ARM_ARCH}/release/bundle/macos"
UNIVERSAL_DIR="${BUILD_DIR}/universal"
UNIVERSAL_APP_PATH="${UNIVERSAL_DIR}/macos/${APP_NAME}.app"

# ==============================================
# 依赖与输入检查
# ==============================================
check_dependency() {
  if ! command -v "$1" &> /dev/null; then
    echo "Error: 缺少工具 '$1'"
    exit 1
  fi
}

check_dependency "lipo"
check_dependency "codesign"

check_inputs() {
  if [ ! -d "${INTEL_APP_DIR}/${APP_NAME}.app" ] || [ ! -d "${ARM_APP_DIR}/${APP_NAME}.app" ]; then
    echo "Error: 未找到单架构 .app"
    exit 1
  fi
  if ! security find-identity -v -p codesigning | grep -q "$SIGN_IDENTITY"; then
    echo "Error: 签名证书不存在"
    exit 1
  fi
}

# ==============================================
# 合并与签名
# ==============================================
merge_components() {
  rm -rf "$UNIVERSAL_DIR"
  mkdir -p "$(dirname "$UNIVERSAL_APP_PATH")"
  cp -R "${INTEL_APP_DIR}/${APP_NAME}.app" "$UNIVERSAL_APP_PATH"

  # 合并主可执行文件
  lipo -create -output \
    "${UNIVERSAL_APP_PATH}/Contents/MacOS/${APP_NAME}" \
    "${INTEL_APP_DIR}/${APP_NAME}.app/Contents/MacOS/${APP_NAME}" \
    "${ARM_APP_DIR}/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

  # 合并框架（如需要）
  # ...（省略框架合并代码，同之前）
}

sign_with_hardened_runtime() {
  echo "应用 Hardened Runtime 并签名..."
  codesign \
    --deep \
    --force \
    --sign "$SIGN_IDENTITY" \
    --entitlements "$ENTITLEMENTS_FILE" \
    --options runtime \
    "$UNIVERSAL_APP_PATH"

  # 验证
  if codesign -d --entitlements - "$UNIVERSAL_APP_PATH" | grep -q "com.apple.security.hardened-runtime"; then
    echo "Hardened Runtime 配置成功"
  else
    echo "Error: Hardened Runtime 配置失败"
    exit 1
  fi
}

# ==============================================
# 主流程
# ==============================================
main() {
  check_inputs
  merge_components
  sign_with_hardened_runtime
  echo "完成！通用 .app 路径：$UNIVERSAL_APP_PATH"
}

main