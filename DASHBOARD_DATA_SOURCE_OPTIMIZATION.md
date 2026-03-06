# 仪表盘数据来源优化设计方案

## 1. 现状分析

### 1.1 当前问题

**数据来源配置缺失**：
- 仪表盘组件（DashboardWidget）的 `config` 字段只包含基础配置（如 `metric`, `chartType`）
- 没有数据源关联机制，组件无法动态绑定资产数据
- 组件显示的数据是硬编码的，无法根据用户选择的资产动态变化

**组件配置不完整**：
- WidgetConfigDialog 只允许编辑组件标题和类型
- 没有数据源选择界面
- 没有字段映射配置

**数据流不清晰**：
- 仪表盘屏幕直接从 Provider 获取所有资产数据
- 组件无法独立获取和管理自己的数据源
- 没有数据源变更时的自动更新机制

### 1.2 现有代码结构

```
DashboardWidget (config 字段)
  ├─ metric: 'total_value'  // 硬编码指标
  ├─ chartType: 'pie'       // 图表类型
  └─ 缺少: dataSource 配置

DashboardScreen
  ├─ 加载所有资产数据
  ├─ 传递给组件显示
  └─ 组件无法选择数据源
```

## 2. 优化目标

### 2.1 核心需求

1. **数据源配置**：每个组件可以关联一个或多个资产数据源
2. **灵活的数据绑定**：支持不同资产类型的数据绑定
3. **动态数据更新**：数据源变更时自动更新组件显示
4. **用户友好的配置**：提供直观的数据源选择界面

### 2.2 支持的数据源类型

```
资产数据源：
├─ 单个资产 (Single Asset)
│  ├─ 资产ID
│  ├─ 资产类型
│  └─ 显示字段（价值、数量等）
│
├─ 资产类型聚合 (Asset Type Aggregation)
│  ├─ 资产类型（现金、股票、基金等）
│  ├─ 聚合方式（求和、平均、最大、最小）
│  └─ 时间范围
│
├─ 多个资产 (Multiple Assets)
│  ├─ 资产列表
│  ├─ 分组方式
│  └─ 排序方式
│
└─ 资产记录时间序列 (Asset Record Time Series)
   ├─ 资产ID
   ├─ 时间范围
   ├─ 时间粒度（日/周/月/年）
   └─ 聚合方式
```

## 3. 数据模型设计

### 3.1 数据源配置模型

```dart
// 数据源类型枚举
enum DataSourceType {
  singleAsset,           // 单个资产
  assetTypeAggregation,  // 资产类型聚合
  multipleAssets,        // 多个资产
  assetRecordTimeSeries, // 资产记录时间序列
  customMetric,          // 自定义指标
}

// 数据源配置
class DataSourceConfig {
  final String id;
  final DataSourceType type;
  final Map<String, dynamic> params;  // 数据源参数
  final String? label;                // 数据源标签

  DataSourceConfig({
    required this.id,
    required this.type,
    required this.params,
    this.label,
  });
}

// 字段映射配置
class FieldMapping {
  final String sourceField;    // 数据源字段（如 'value', 'quantity'）
  final String displayField;   // 显示字段（如 '总价值', '持仓数量'）
  final String? format;        // 格式化方式（如 'currency', 'percentage'）
  final String? unit;          // 单位（如 '¥', '%'）

  FieldMapping({
    required this.sourceField,
    required this.displayField,
    this.format,
    this.unit,
  });
}

// 更新后的 DashboardWidget 配置
class DashboardWidgetConfig {
  final String title;
  final WidgetType type;

  // 新增：数据源配置
  final DataSourceConfig? dataSource;
  final List<FieldMapping>? fieldMappings;

  // 其他配置
  final String? chartType;
  final Map<String, dynamic>? chartOptions;
  final Map<String, dynamic>? displayOptions;

  DashboardWidgetConfig({
    required this.title,
    required this.type,
    this.dataSource,
    this.fieldMappings,
    this.chartType,
    this.chartOptions,
    this.displayOptions,
  });
}
```

### 3.2 数据源参数示例

**单个资产数据源**：
```json
{
  "type": "singleAsset",
  "params": {
    "assetId": 1,
    "assetTypeId": 1,
    "displayFields": ["value", "quantity", "unitPrice"]
  }
}
```

**资产类型聚合数据源**：
```json
{
  "type": "assetTypeAggregation",
  "params": {
    "assetTypeId": 1,
    "aggregation": "sum",
    "displayField": "value"
  }
}
```

**多个资产数据源**：
```json
{
  "type": "multipleAssets",
  "params": {
    "assetTypeIds": [1, 2, 3],
    "groupBy": "assetType",
    "sortBy": "value",
    "sortOrder": "desc",
    "limit": 10
  }
}
```

**资产记录时间序列数据源**：
```json
{
  "type": "assetRecordTimeSeries",
  "params": {
    "assetId": 1,
    "period": "month",
    "startDate": "2024-01-01",
    "endDate": "2024-12-31",
    "aggregation": "average"
  }
}
```

## 4. 数据源管理系统

### 4.1 数据源查询服务

```dart
class DataSourceService {
  // 根据数据源配置获取数据
  Future<dynamic> fetchData(DataSourceConfig config);

  // 获取单个资产数据
  Future<Map<String, dynamic>> fetchSingleAssetData(int assetId);

  // 获取资产类型聚合数据
  Future<Map<String, dynamic>> fetchAssetTypeAggregation(
    int assetTypeId,
    String aggregation,
  );

  // 获取多个资产数据
  Future<List<Map<String, dynamic>>> fetchMultipleAssetsData(
    List<int> assetTypeIds,
    String groupBy,
  );

  // 获取资产记录时间序列
  Future<List<Map<String, dynamic>>> fetchAssetRecordTimeSeries(
    int assetId,
    String period,
    DateTimeRange dateRange,
  );
}
```

### 4.2 数据源缓存策略

```
缓存层次：
├─ L1: 内存缓存（TTL: 5 分钟）
│  ├─ 单个资产数据
│  ├─ 资产类型聚合数据
│  └─ 最近查询的时间序列
│
├─ L2: 本地数据库缓存
│  ├─ 资产列表
│  ├─ 资产记录
│  └─ 聚合结果
│
└─ 缓存失效策略
   ├─ 手动失效：用户刷新、切换数据源
   ├─ 自动失效：TTL 过期
   └─ 事件失效：资产数据更新时清除相关缓存
```

## 5. UI 设计

### 5.1 组件配置对话框（增强版）

**步骤 1: 基本信息**
```
┌─────────────────────────────────┐
│ 组件配置                         │
├─────────────────────────────────┤
│ 组件标题: [输入框]              │
│ 组件类型: [下拉菜单]            │
│          ├─ 统计卡片            │
│          ├─ 图表                │
│          ├─ 表格                │
│          └─ 仪表盘              │
└─────────────────────────────────┘
```

**步骤 2: 数据源配置**
```
┌─────────────────────────────────┐
│ 数据源配置                       │
├─────────────────────────────────┤
│ 数据源类型: [下拉菜单]          │
│           ├─ 单个资产            │
│           ├─ 资产类型聚合        │
│           ├─ 多个资产            │
│           └─ 时间序列            │
│                                  │
│ [根据选择显示相应的配置字段]    │
│                                  │
│ 单个资产:                        │
│   资产: [下拉菜单]              │
│   显示字段: [多选]              │
│                                  │
│ 资产类型聚合:                    │
│   资产类型: [下拉菜单]          │
│   聚合方式: [下拉菜单]          │
│   ├─ 求和                       │
│   ├─ 平均                       │
│   ├─ 最大                       │
│   └─ 最小                       │
│                                  │
│ 多个资产:                        │
│   资产类型: [多选]              │
│   分组方式: [下拉菜单]          │
│   排序方式: [下拉菜单]          │
│                                  │
│ 时间序列:                        │
│   资产: [下拉菜单]              │
│   时间粒度: [下拉菜单]          │
│   开始日期: [日期选择]          │
│   结束日期: [日期选择]          │
│   聚合方式: [下拉菜单]          │
└─────────────────────────────────┘
```

**步骤 3: 字段映射**
```
┌─────────────────────────────────┐
│ 字段映射                         │
├─────────────────────────────────┤
│ 源字段          显示字段  格式   │
│ ─────────────────────────────── │
│ value      →    总价值    ¥     │
│ quantity   →    持仓数量  个     │
│ unitPrice  →    单价      ¥     │
│                                  │
│ [+ 添加字段映射]                │
└─────────────────────────────────┘
```

**步骤 4: 预览**
```
┌─────────────────────────────────┐
│ 预览                             │
├─────────────────────────────────┤
│ 组件标题: 现金总额              │
│ 数据源: 现金 (单个资产)         │
│ 显示字段: value                 │
│                                  │
│ 预览数据:                        │
│ ┌─────────────────────────────┐ │
│ │ 现金总额                    │ │
│ │ ¥ 8,000                     │ │
│ └─────────────────────────────┘ │
│                                  │
│ [取消] [保存]                   │
└─────────────────────────────────┘
```

### 5.2 数据源选择器组件

```dart
class DataSourceSelector extends StatefulWidget {
  final DataSourceType selectedType;
  final Map<String, dynamic> selectedParams;
  final Function(DataSourceType, Map<String, dynamic>) onChanged;

  // 显示资产列表、资产类型列表等
}
```

### 5.3 字段映射编辑器

```dart
class FieldMappingEditor extends StatefulWidget {
  final List<FieldMapping> mappings;
  final List<String> availableSourceFields;
  final Function(List<FieldMapping>) onChanged;

  // 允许添加、编辑、删除字段映射
}
```

## 6. 数据流设计

### 6.1 组件数据加载流程

```
用户打开仪表盘
  ↓
DashboardScreen 加载仪表盘配置
  ↓
遍历每个 DashboardWidget
  ├─ 检查是否有 dataSource 配置
  ├─ 如果有，调用 DataSourceService.fetchData()
  ├─ 根据 fieldMappings 映射字段
  └─ 将数据传递给组件渲染
  ↓
组件显示数据
```

### 6.2 数据更新流程

```
资产数据更新
  ↓
AssetProvider 通知监听者
  ↓
DashboardScreen 收到通知
  ↓
检查哪些组件依赖于更新的资产
  ↓
重新加载相关组件的数据
  ↓
组件自动更新显示
```

### 6.3 缓存更新策略

```
场景 1: 用户修改资产数据
  → 清除该资产的所有缓存
  → 清除包含该资产的聚合缓存
  → 重新加载依赖该资产的组件

场景 2: 用户切换数据源
  → 清除旧数据源的缓存
  → 加载新数据源的数据
  → 更新组件显示

场景 3: 缓存 TTL 过期
  → 自动重新加载数据
  → 更新缓存
```

## 7. 实现路线图

### Phase 1: 数据模型和服务 (Week 1)
- [ ] 创建 DataSourceConfig 和 FieldMapping 模型
- [ ] 创建 DataSourceService 服务类
- [ ] 实现数据源查询逻辑
- [ ] 实现缓存机制

### Phase 2: UI 组件 (Week 2)
- [ ] 创建 DataSourceSelector 组件
- [ ] 创建 FieldMappingEditor 组件
- [ ] 增强 WidgetConfigDialog
- [ ] 实现数据源配置流程

### Phase 3: 数据绑定 (Week 3)
- [ ] 更新 DashboardWidget 模型
- [ ] 实现组件数据加载逻辑
- [ ] 实现数据更新通知机制
- [ ] 测试数据流

### Phase 4: 优化和完善 (Week 4)
- [ ] 性能优化
- [ ] 错误处理
- [ ] 用户体验优化
- [ ] 测试和 Bug 修复

## 8. 关键设计决策

### 8.1 为什么分离数据源配置和字段映射？

**原因**：
- 数据源配置定义"从哪里获取数据"
- 字段映射定义"如何显示数据"
- 分离使得配置更灵活，同一数据源可以有多种显示方式

### 8.2 为什么需要缓存？

**原因**：
- 避免频繁查询数据库
- 提高仪表盘加载速度
- 减少数据库压力
- 支持离线查看

### 8.3 为什么支持多种数据源类型？

**原因**：
- 不同组件需要不同的数据
- 统计卡片需要单个资产数据
- 图表需要时间序列数据
- 表格需要多个资产数据
- 灵活性和可扩展性

## 9. 数据库设计

### 9.1 新增表：dashboard_widget_data_sources

```sql
CREATE TABLE dashboard_widget_data_sources (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  widget_id TEXT NOT NULL,
  dashboard_id TEXT NOT NULL,
  data_source_type TEXT NOT NULL,
  data_source_params TEXT NOT NULL,  -- JSON 格式
  field_mappings TEXT,               -- JSON 格式
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (dashboard_id) REFERENCES dashboards(id),
  UNIQUE(widget_id, dashboard_id)
);
```

### 9.2 索引优化

```sql
CREATE INDEX idx_data_sources_widget_id ON dashboard_widget_data_sources(widget_id);
CREATE INDEX idx_data_sources_dashboard_id ON dashboard_widget_data_sources(dashboard_id);
```

## 10. 文件结构参考

```
lib/
├── models/
│   ├── data_source/
│   │   ├── data_source_config.dart      (新建)
│   │   ├── field_mapping.dart           (新建)
│   │   └── data_source_type.dart        (新建)
│   └── dashboard_model.dart             (更新)
│
├── services/
│   └── data_source_service.dart         (新建)
│
├── repositories/
│   └── data_source_repository.dart      (新建)
│
├── providers/
│   ├── data_source_provider.dart        (新建)
│   └── dashboard_provider.dart          (更新)
│
├── widgets/
│   └── dashboard/
│       ├── data_source_selector.dart    (新建)
│       ├── field_mapping_editor.dart    (新建)
│       ├── widget_config_dialog.dart    (更新)
│       └── data_source_preview.dart     (新建)
│
└── utils/
    └── data_source_cache.dart           (新建)
```

## 11. 下一步行动

1. **创建数据源模型**：DataSourceConfig、FieldMapping
2. **实现 DataSourceService**：数据查询和缓存
3. **创建 UI 组件**：DataSourceSelector、FieldMappingEditor
4. **更新组件配置流程**：集成数据源配置
5. **实现数据绑定**：组件自动加载和更新数据
6. **测试和优化**：性能测试、用户体验优化

---

**文档版本**：1.0
**最后更新**：2026-03-06
**状态**：设计完成，待实现
