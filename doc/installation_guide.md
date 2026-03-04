# Flutter 安装指南

## 当前状态

由于网络连接问题，无法自动下载 Homebrew 和 Flutter SDK。请按照以下步骤手动安装。

## 方法 1: 使用 Homebrew 安装（推荐）

如果系统已安装 Homebrew，运行：

```bash
# 安装 Flutter
brew install flutter

# 验证安装
flutter doctor
```

如果系统未安装 Homebrew，先安装 Homebrew：

```bash
# 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 添加 Homebrew 到 PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# 安装 Flutter
brew install flutter
```

## 方法 2: 直接下载 Flutter SDK

### macOS (Apple Silicon - M1/M2/M3)

```bash
# 下载 Flutter SDK
cd ~/Development
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 添加 Flutter 到 PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 验证安装
flutter doctor
```

### macOS (Intel)

```bash
# 下载 Flutter SDK
cd ~/Development
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 添加 Flutter 到 PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 验证安装
flutter doctor
```

## 方法 3: 使用国内镜像（如果 GitHub 访问慢）

### 使用 Gitee 镜像

```bash
# 设置 Flutter 镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 下载 Flutter SDK
git clone https://gitee.com/mirrors/flutter.git -b stable

# 添加 Flutter 到 PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 验证安装
flutter doctor
```

## 永久配置 PATH

将 Flutter 添加到 shell 配置文件：

### Zsh (macOS 默认)

编辑 `~/.zshrc`，添加：

```bash
export PATH="$PATH:$HOME/Development/flutter/bin"
```

然后运行：

```bash
source ~/.zshrc
```

### Bash

编辑 `~/.bash_profile`，添加：

```bash
export PATH="$PATH:$HOME/Development/flutter/bin"
```

然后运行：

```bash
source ~/.bash_profile
```

## 验证安装

运行以下命令验证 Flutter 安装：

```bash
# 检查 Flutter 版本
flutter --version

# 运行 Flutter Doctor 检查环境
flutter doctor
```

## 运行 MyRich 项目

安装 Flutter 后，在项目目录运行：

```bash
# 进入项目目录
cd /Users/ldh/Downloads/project/MyRich

# 获取依赖
flutter pub get

# 运行 macOS 版本
flutter run -d macos
```

## 常见问题

### 1. flutter: command not found

Flutter 未添加到 PATH，请按照"永久配置 PATH"部分配置。

### 2. Xcode not installed

Flutter 需要 Xcode 命令行工具。安装 Xcode：

```bash
# 从 App Store 安装 Xcode
# 或运行以下命令安装命令行工具
sudo xcode-select --install
```

### 3. CocoaPods not installed

安装 CocoaPods：

```bash
sudo gem install cocoapods
```

### 4. 网络问题

如果 GitHub 访问慢，使用国内镜像：

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

## 下一步

安装 Flutter 后，运行以下命令启动项目：

```bash
cd /Users/ldh/Downloads/project/MyRich
flutter pub get
flutter run -d macos
```
