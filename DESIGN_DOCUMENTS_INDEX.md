# MyRich 设计文档索引

本文件为所有设计文档的索引，方便其他技能快速定位和读取相关设计方案。

## 📚 设计文档列表

### 1. 资产管理模块设计

#### 📄 ASSET_DETAIL_MANAGEMENT_DESIGN.md
**版本**: 2.4 | **状态**: 设计完成，待实现 | **行数**: 1900+

**核心内容**:
- 资产明细管理系统的完整设计方案
- 三层数据模型：Asset → AssetDetail → AssetRecord
- 6 种资产类型的具体设计（现金、银行卡、股票、基金、债券、房产）

**主要章节**:
1. 核心问题分析
2. 新的数据模型设计
3. 资产类型的具体设计（6 种）
4. API 结构设计
5. UI 流程设计
6. 数据验证规则
7. 搜索和筛选功能
8. 批量操作功能
9. 错误处理策略
10. 性能优化建议
11. 安全性考虑
12. 缓存策略
13. 并发控制
14. 数据一致性保证
15. 灾难恢复计划
16. 性能基准
17. 用户体验指南
18. 可访问性设计
19. 国际化支持
20. 离线支持设计
21. 状态管理设计
22. 业务流程图
23. 测试策略
24. 监控和日志
25. 版本管理
26. 数据导入/导出设计
27. API 响应格式设计
28. 权限和访问控制
29. 数据库索引详细设计
30. 实现示例
31. 总结和风险分析

**实现路线图**:
- Phase 1: 数据模型（Week 1）
- Phase 2: 基础 CRUD（Week 2-3）
- Phase 3: 数据管理（Week 4）
- Phase 4: 优化和完善（Week 5）

**关键文件**:
- `lib/models/asset_detail.dart` (新建)
- `lib/repositories/asset_detail_repository.dart` (新建)
- `lib/providers/asset_detail_provider.dart` (新建)
- `lib/screens/asset_detail_list_screen.dart` (新建)

---

### 2. 仪表盘数据来源优化

#### 📄 DASHBOARD_DATA_SOURCE_OPTIMIZATION.md
**版本**: 1.0 | **状态**: 设计完成，待实现 | **行数**: 600+

**核心内容**:
- 仪表盘组件数据来源配置系统
- 支持 4 种数据源类型
- 灵活的字段映射配置
- 完整的数据流和缓存策略

**主要章节**:
1. 现状分析
2. 优化目标
3. 数据模型设计
4. 数据源管理系统
5. UI 设计
6. 数据流设计
7. 实现路线图
8. 关键设计决策
9. 数据库设计
10. 文件结构参考

**支持的数据源类型**:
1. 单个资产 (Single Asset)
2. 资产类型聚合 (Asset Type Aggregation)
3. 多个资产 (Multiple Assets)
4. 时间序列 (Asset Record Time Series)

**实现路线图**:
- Phase 1: 数据模型和服务（Week 1）
- Phase 2: UI 组件（Week 2）
- Phase 3: 数据绑定（Week 3）
- Phase 4: 优化和完善（Week 4）

**关键文件**:
- `lib/models/data_source/data_source_config.dart` (新建)
- `lib/models/data_source/field_mapping.dart` (新建)
- `lib/services/data_source_service.dart` (新建)
- `lib/widgets/dashboard/data_source_selector.dart` (新建)
- `lib/widgets/dashboard/field_mapping_editor.dart` (新建)

---

### 3. 仪表盘相关设计（历史）

#### 📄 DASHBOARD_DESIGN_PLAN.md
**版本**: 1.0 | **状态**: 已实现部分

Grafana 风格可拖拽仪表盘的初始设计方案。

#### 📄 DASHBOARD_REFINEMENT_PLAN.md
**版本**: 1.0 | **状态**: 已实现部分

仪表盘细节调整计划，包括菜单折叠、Header 简化等。

#### 📄 DASHBOARD_GRID_LAYOUT_OPTIMIZATION.md
**版本**: 1.0 | **状态**: 已实现部分

网格布局优化方案，解决组件重叠问题。

---

### 4. 资产管理初始设计（已更新）

#### 📄 ASSET_MANAGEMENT_DESIGN_PLAN.md
**版本**: 1.0 | **状态**: 已被 ASSET_DETAIL_MANAGEMENT_DESIGN.md 替代

初始的资产管理设计方案，已被更完善的版本替代。

---

## 🎯 实现优先级

### 高优先级（必须实现）
1. **资产明细管理** - ASSET_DETAIL_MANAGEMENT_DESIGN.md
   - AssetDetail 模型和 Repository
   - 基础 CRUD 操作
   - 资产明细列表和详情页面
   - 数据验证

2. **仪表盘数据源** - DASHBOARD_DATA_SOURCE_OPTIMIZATION.md
   - DataSourceService 和缓存
   - DataSourceSelector 和 FieldMappingEditor 组件
   - 组件数据绑定

### 中优先级（应该实现）
- 搜索和筛选功能
- 资产记录管理
- 缓存策略优化
- 错误处理完善

### 低优先级（可以延后）
- 批量操作
- 导入/导出
- 离线支持
- 监控和日志

---

## 📋 快速导航

| 需求 | 对应文档 | 章节 |
|------|--------|------|
| 了解资产明细数据模型 | ASSET_DETAIL_MANAGEMENT_DESIGN.md | 第 2-3 章 |
| 了解资产类型设计 | ASSET_DETAIL_MANAGEMENT_DESIGN.md | 第 3 章 |
| 了解 API 设计 | ASSET_DETAIL_MANAGEMENT_DESIGN.md | 第 4 章 |
| 了解 UI 流程 | ASSET_DETAIL_MANAGEMENT_DESIGN.md | 第 5 章 |
| 了解数据验证规则 | ASSET_DETAIL_MANAGEMENT_DESIGN.md | 第 10 章 |
| 了解仪表盘数据源配置 | DASHBOARD_DATA_SOURCE_OPTIMIZATION.md | 第 3 章 |
| 了解数据源类型 | DASHBOARD_DATA_SOURCE_OPTIMIZATION.md | 第 2.2 章 |
| 了解 UI 设计 | DASHBOARD_DATA_SOURCE_OPTIMIZATION.md | 第 5 章 |
| 了解数据流 | DASHBOARD_DATA_SOURCE_OPTIMIZATION.md | 第 6 章 |

---

## 🔧 实现指南

### 第一步：资产明细管理实现
1. 阅读 ASSET_DETAIL_MANAGEMENT_DESIGN.md 的第 2-3 章
2. 创建 AssetDetail 模型
3. 实现 AssetDetailRepository
4. 实现 AssetDetailProvider
5. 构建 UI 层

### 第二步：仪表盘数据源实现
1. 阅读 DASHBOARD_DATA_SOURCE_OPTIMIZATION.md 的第 3-6 章
2. 创建 DataSourceConfig 和 FieldMapping 模型
3. 实现 DataSourceService
4. 创建 UI 组件
5. 集成数据绑定

---

## 📝 文档维护

- **最后更新**: 2026-03-06
- **维护者**: Claude Code
- **版本**: 1.0

---

## 📞 相关资源

- 项目目录: `/Users/ldh/Downloads/project/MyRich`
- 内存文件: `/Users/ldh/.claude/projects/-Users-ldh-Downloads-project-MyRich/memory/MEMORY.md`
- 所有设计文档都在项目根目录下

---

**注意**: 本索引文件用于快速导航和查找相关设计文档。具体实现时，请参考对应文档的详细内容。
