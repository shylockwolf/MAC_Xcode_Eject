# Eject - 外置存储设备自动弹出工具

[![Platform](https://img.shields.io/badge/platform-macOS-blue.svg)](https://github.com/shylockwolf/MAC_Xcode_Eject) [![Version](https://img.shields.io/badge/version-1.3.0-green.svg)]() [![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

一个专为macOS设计的简洁工具，用于自动检测并安全弹出所有外置存储设备。

## 功能特性

- 🔍 **自动检测**：启动时自动扫描挂载的所有存储设备
- ⚡ **一键弹出**：自动安全弹出所有检测到的外置设备
- 📊 **状态监控**：实时显示设备列表和操作日志
- 🎯 **简洁界面**：基于SwiftUI的现代化用户界面

## 快速开始

### 构建与运行
1. 使用Xcode打开 `Eject.xcodeproj`
2. 选择目标设备 (My Mac)
3. 按 `⌘B` 构建项目
4. 按 `⌘R` 运行应用程序

## 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI 5+
- **系统**: macOS 13+

## 项目结构

```
Eject/
├── Eject.xcodeproj/          # Xcode项目
├── Eject/                    # 源代码
│   ├── ContentView.swift     # 主界面
│   ├── EjectApp.swift        # 应用入口
│   └── Assets.xcassets/      # 资源文件
└── README.md                 # 说明文档
```

## 版本历史

### v1.3.0 (2024-11-16)
- 代码仓库优化，仅保留当前稳定版本
- 界面布局优化
- 性能提升

## 许可证

MIT License
