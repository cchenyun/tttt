 # 整个流程 打包，签名，公证 目前Inter芯片电脑打出的包只有M1能用


  # build Inter芯片
  npm run tauri build -- --target x86_64-apple-darwin  

  # build M芯片
    npm run tauri build -- --target aarch64-apple-darwin

# 执行签名
codesign --deep --force --sign "Developer ID Application: Nanjing Yuanlian Network Technology Co., Ltd (BHYBHZGP8X)" --entitlements entitlements.plist target/release/bundle/macos/口袋原油PC.app


# 验证签名是否有效
 codesign -dvvv target/release/bundle/macos/口袋原油PC.app

# 检查entitlements环境
 codesign -d --entitlements - /Users/chenyun/Desktop/pocketoil_pc_tauri/pocketoil_pc/src-tauri/target/universal/macos/口袋原油PC.app  2>/dev/null


# 公证
 xcrun notarytool submit "$APP_NAME.zip" \
  --apple-id "$APPLE_ID" \
  --password "$APP_PASSWORD" \
  --team-id "$TEAM_ID" \
  --wait


# 检查公证结果
  xcrun notarytool info "8c164a9c-1736-467b-92d5-3b1b58277fa6" \
  --apple-id "hehuajia@163.com" \
  --password "bkaz-lxqu-ycan-oqqg" \
  --team-id "BHYBHZGP8X"

  # 查看公证错误日志
  xcrun notarytool log ff1415a2-d533-48fa-9a60-e326762125dd  --apple-id hehuajia@163.com --password bkaz-lxqu-ycan-oqqg --team-id BHYBHZGP8X ./notary_log.json
  
  # 查看账号下的所有公证信息
  xcrun notarytool history --apple-id hehuajia@163.com --password bkaz-lxqu-ycan-oqqg --team-id BHYBHZGP8X


# 查看app架构
lipo -info '/Users/chenyun/Desktop/pocketoil_pc_tauri/pocketoil_pc/src-tauri/target/universal/macos/ 口袋原油PC.app/Contents/MacOS/口袋原油PC'