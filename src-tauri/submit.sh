#!/bin/bash

# ==================== 配置参数（根据你的项目修改）====================
APP_NAME="口袋原油PC"                  # 例如：MyApp
BUNDLE_ID="com.kingbi.oilpc"      # 应用的bundle ID（需与签名时一致）
SIGNED_APP_PATH="target/universal/macos/$APP_NAME.app"  # 已签名的.app路径
OUTPUT_DIR="./dist_signed"              # 输出目录（存放公证文件和DMG）
DEV_EMAIL="hehuajia@163.com"          # 开发者邮箱
DEV_PASSWORD="bkaz-lxqu-ycan-oqqg"  # 开发者密码
TEAM_ID="BHYBHZGP8X"                # 开发者团队ID
# ==================================================================

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

# 检查必要工具
check_dependencies() {
  if ! command -v xcrun &> /dev/null; then
    red "错误：未找到Xcode工具，请安装Xcode并配置命令行工具。"
    exit 1
  fi
  if ! command -v ditto &> /dev/null; then
    red "错误：未找到ditto工具（通常随Xcode安装）。"
    exit 1
  fi
}

# 验证已签名的应用是否存在且有效
verify_signed_app() {
  yellow "验证已签名的应用..."
  if [ ! -d "$SIGNED_APP_PATH" ]; then
    red "错误：未找到已签名的应用，请检查路径：$SIGNED_APP_PATH"
    exit 1
  fi
  # 验证签名有效性（确保签名正确且包含Hardened Runtime）
  if ! codesign -vvv --deep --strict "$SIGNED_APP_PATH"; then
    red "错误：应用签名无效！请确认已用Developer ID正确签名。"
    exit 1
  fi
  # 检查是否启用Hardened Runtime（公证必需）
  if ! codesign -d --entitlements - "$SIGNED_APP_PATH" 2>/dev/null | grep -q "com.apple.security.hardened-runtime"; then
    red "错误：未启用Hardened Runtime！公证需要开启该功能（在Xcode的Signing & Capabilities中添加）。"
    exit 1
  fi
  green "已签名应用验证通过。"
}

# 清理输出目录
cleanup() {
  yellow "清理旧输出文件..."
  rm -rf "$OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"
}

# 打包为ZIP（用于公证）
package_zip() {
  yellow "打包已签名应用为ZIP（用于公证）..."
  ZIP_PATH="$OUTPUT_DIR/$APP_NAME.zip"
  ditto -c -k --sequesterRsrc --keepParent "$SIGNED_APP_PATH" "$ZIP_PATH"
  if [ ! -f "$ZIP_PATH" ]; then
    red "ZIP打包失败！"
    exit 1
  fi
  green "ZIP包路径：$ZIP_PATH"
}

notarize_app() {
  yellow "使用硬编码凭据提交提交公证（可能需要10-30分钟）..."
  
  # 提交公证并捕获返回码（0为成功，非0为失败）
  NOTARIZE_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$DEV_EMAIL" \
    --password "$DEV_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait \
    --timeout 1800 2>&1)
  NOTARIZE_EXIT_CODE=$?  # 捕获命令的返回码
  green "结果----"
    green "$NOTARIZE_OUTPUT"
  # 优先通过返回码判断（0为成功）
  if [ $NOTARIZE_EXIT_CODE -eq 0 ]; then
    # 二次确认输出中是否有成功标志（双重保险）
    if echo "$NOTARIZE_OUTPUT" | grep -qi "status: accepted"; then
      green "公证成功！"
    else
      yellow "警告：返回码显示成功，但未找到预期的成功标志。输出信息："
      echo "$NOTARIZE_OUTPUT"
      green "按返回码判断，公证成功。"
    fi
  else
    # 失败处理
    red "公证失败！错误信息："
    echo "$NOTARIZE_OUTPUT"
    LOG_ID=$(echo "$NOTARIZE_OUTPUT" | grep -i "id:" | awk '{print $2}')
    if [ -n "$LOG_ID" ]; then
      yellow "详细日志命令："
      echo "xcrun notarytool log $LOG_ID --apple-id $DEV_EMAIL --password $DEV_PASSWORD --team-id $TEAM_ID"
    fi
    exit 1
  fi
}

# 装订公证结果
staple_app() {
  yellow "将公证结果装订到应用中..."
  if ! xcrun stapler staple "$SIGNED_APP_PATH"; then
    red "装订失败！"
    exit 1
  fi
  if xcrun stapler validate "$SIGNED_APP_PATH"; then
    green "公证结果装订成功。"
  else
    red "装订验证失败！"
    exit 1
  fi
}

# 生成DMG安装包
generate_dmg() {
  yellow "生成DMG安装包..."
  DMG_PATH="$OUTPUT_DIR/$APP_NAME.dmg"
  TEMP_DIR="./temp_dmg"
  mkdir -p "$TEMP_DIR"
  cp -R "$SIGNED_APP_PATH" "$TEMP_DIR/"
  ln -s /Applications "$TEMP_DIR/应用程序"  # 添加应用程序快捷方式
  hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"
  rm -rf "$TEMP_DIR"
  if [ -f "$DMG_PATH" ]; then
    green "DMG生成成功，路径：$DMG_PATH"
  else
    red "DMG生成失败！"
    exit 1
  fi
}

# 主流程
main() {
  check_dependencies
  cleanup
  verify_signed_app
  package_zip
  notarize_app
  staple_app
  generate_dmg
  green "============= 操作完成！可分发的DMG文件位于：$OUTPUT_DIR ============="
}

# 启动脚本
main
