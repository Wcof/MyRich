# 项目关键信息文档

## 项目概述
- 项目名称: MyRich
- 项目类型: 个人资产管理系统
- 开发平台: macOS (桌面端优先)
- 技术栈: Flutter + SQLite

## 开发目标
- 跨平台支持 (Windows, macOS)
- 本地数据存储 (SQLite)
- Dashboard 可视化
- 灵活的资产类型管理

## 关键技术决策
- 状态管理: provider
- 图表库: fl_chart
- 数据库: sqflite_common_ffi
- 自定义字段: JSON 存储

## 数据库设计
- asset_types: 资产类型表
- assets: 资产表
- asset_records: 资产记录表
- dashboard_configs: 看板配置表

## 预定义资产类型
现金、银行存款、股票、基金、债券、房产、加密货币、期货、借款、贷款

## 开发阶段
- Phase 1: 项目初始化和基础架构
- Phase 2: 数据库设计和模型
- Phase 3: 核心功能实现
- Phase 4: Dashboard 可视化
- Phase 5: UI/UX 实现
- Phase 6: 数据接口架构 (预留)
