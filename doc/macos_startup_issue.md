# macOS 应用启动问题排查

## 问题描述

应用构建成功但启动时崩溃，错误信息：
```
Error waiting for a debug connection: The log reader stopped unexpectedly, or never started.
Error launching application on macOS.
```

## 已完成的修复

### 1. 添加网络权限
已在以下文件中添加 `com.apple.security.network.client` 权限：
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

### 2. 安装 CocoaPods
已通过 Homebrew 安装 CocoaPods 1.16.2_2

### 3. 简化代码
已将 `lib/main.dart` 替换为最简单的 Flutter 计数器代码，排除代码逻辑问题

## 可能的原因

### 1. macOS 沙盒限制
macOS 应用默认运行在沙盒环境中，可能需要：
- 禁用沙盒（仅用于开发测试）
- 或添加更多权限

### 2. 应用签名问题
开发环境可能需要：
- 禁用代码签名
- 或使用正确的开发者证书签名

### 3. Xcode 配置问题
可能需要检查：
- Xcode 项目的签名设置
- 部署目标版本
- 架构设置

## 解决方案

### 方案 1: 禁用沙盒（推荐用于开发测试）

编辑 `macos/Runner/DebugProfile.entitlements`：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<false/>
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
</dict>
</plist>
```

编辑 `macos/Runner/Release.entitlements`：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<false/>
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>
```

### 方案 2: 禁用代码签名

编辑 `macos/Runner.xcodeproj/project.pbxproj`，找到以下设置并修改：
```
CODE_SIGN_IDENTITY = "-";
CODE_SIGN_STYLE = Automatic;
```

### 方案 3: 使用 Xcode 打开项目

1. 打开 Xcode
2. 打开项目：`macos/Runner.xcworkspace`
3. 选择 Runner target
4. 在 Signing & Capabilities 标签页：
   - 取消勾选 "Automatically manage signing"
   - 或选择正确的开发者团队
5. 运行项目

### 方案 4: 检查系统日志

查看详细的崩溃日志：
```bash
log stream --predicate 'process == "myrich"' --level debug
```

或在控制台应用中查看：
```bash
open -a Console
```

## 下一步操作

1. 尝试方案 1（禁用沙盒）
2. 清理并重新构建：
   ```bash
   flutter clean
   cd macos
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   flutter run -d macos
   ```

3. 如果还是失败，尝试使用 Xcode 打开项目并运行

## 调试命令

### 查看应用是否在运行
```bash
ps aux | grep myrich
```

### 查看应用日志
```bash
log show --predicate 'process == "myrich"' --last 5m
```

### 直接运行应用（不通过 Flutter）
```bash
open build/macos/Build/Products/Debug/myrich.app
```

### 检查应用签名
```bash
codesign -dv --verbose=4 build/macos/Build/Products/Debug/myrich.app
```

### 检查 entitlements
```bash
codesign -d --entitlements :- build/macos/Build/Products/Debug/myrich.app
```
