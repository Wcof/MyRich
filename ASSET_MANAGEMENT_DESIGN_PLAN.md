# 资产管理功能设计方案

## 1. 功能概述

资产管理模块是 MyRich 的核心功能，用于管理用户的各类资产配置和历史数据。该模块提供资产的创建、编辑、查询和数据分析功能，支持预定义资产类型和自定义资产类型。

### 核心目标
- 提供灵活的资产配置管理
- 支持多种数据类型和度量单位
- 实现时间序列数据查询（日/周/月/年）
- 为财务分析提供数据支持

---

## 2. 数据模型设计

### 2.1 资产类型 (AssetType)

**用途**：定义资产的分类和字段结构

**现有字段**：
```
- id: 唯一标识
- name: 类型名称（如：房产、股票、基金、现金等）
- icon: 图标标识
- color: 颜色代码
- fieldsSchema: JSON 格式的字段定义（动态字段）
- isSystem: 是否为系统预定义类型
- createdAt: 创建时间戳
- updatedAt: 更新时间戳
```

**预定义资产类型**：
```
1. 房产 (Real Estate)
   - 字段：位置、面积、购买价格、当前估值

2. 股票 (Stock)
   - 字段：股票代码、持股数量、购买价格、当前价格

3. 基金 (Fund)
   - 字段：基金代码、份额、购买价格、当前净值

4. 现金 (Cash)
   - 字段：账户类型、币种、余额

5. 加密资产 (Crypto)
   - 字段：币种、数量、购买价格、当前价格

6. 其他 (Other)
   - 字段：自定义
```

**fieldsSchema 结构**：
```json
{
  "fields": [
    {
      "id": "field_1",
      "name": "字段名称",
      "type": "text|number|date|select|currency",
      "required": true,
      "unit": "单位（可选）",
      "options": ["选项1", "选项2"]  // 仅 select 类型需要
    }
  ]
}
```

### 2.2 资产 (Asset)

**用途**：存储用户创建的具体资产实例

**现有字段**：
```
- id: 唯一标识
- typeId: 关联的资产类型 ID
- name: 资产名称（如：北京朝阳区房产、阿里巴巴股票）
- location: 位置信息（可选）
- customData: JSON 格式的自定义字段数据
- createdAt: 创建时间戳
- updatedAt: 更新时间戳
```

**customData 结构**：
```json
{
  "field_1": "值1",
  "field_2": 100,
  "field_3": "2024-01-15",
  "unit": "单位"  // 度量单位
}
```

### 2.3 资产记录 (AssetRecord)

**用途**：存储资产的历史数据，用于时间序列分析

**现有字段**：
```
- id: 唯一标识
- assetId: 关联的资产 ID
- value: 资产当前价值
- quantity: 数量（可选）
- unitPrice: 单价（可选）
- note: 备注
- recordDate: 记录日期（时间戳）
- createdAt: 创建时间戳
```

**数据类型支持**：
- 数值型：整数、浮点数、百分比
- 货币型：支持多币种
- 日期型：日期、时间
- 文本型：字符串、备注
- 枚举型：预定义选项

---

## 3. API 结构设计

### 3.1 资产类型 API

```
GET /api/asset-types
  - 获取所有资产类型（包括系统预定义和用户自定义）
  - 返回：AssetType[]

GET /api/asset-types/:id
  - 获取单个资产类型详情
  - 返回：AssetType

POST /api/asset-types
  - 创建自定义资产类型
  - 请求体：{ name, icon, color, fieldsSchema }
  - 返回：AssetType

PUT /api/asset-types/:id
  - 更新资产类型（仅自定义类型）
  - 请求体：{ name, icon, color, fieldsSchema }
  - 返回：AssetType

DELETE /api/asset-types/:id
  - 删除自定义资产类型
  - 返回：{ success: boolean }
```

### 3.2 资产 API

```
GET /api/assets
  - 获取所有资产列表
  - 查询参数：typeId（可选）、sortBy（可选）
  - 返回：Asset[]

GET /api/assets/:id
  - 获取单个资产详情
  - 返回：Asset

POST /api/assets
  - 创建新资产
  - 请求体：{ typeId, name, location, customData }
  - 返回：Asset

PUT /api/assets/:id
  - 更新资产信息
  - 请求体：{ name, location, customData }
  - 返回：Asset

DELETE /api/assets/:id
  - 删除资产
  - 返回：{ success: boolean }
```

### 3.3 资产记录 API

```
GET /api/assets/:id/records
  - 获取资产的历史记录
  - 查询参数：startDate, endDate, period(day|week|month|year)
  - 返回：AssetRecord[]

GET /api/assets/:id/records/summary
  - 获取资产的统计摘要
  - 查询参数：period(day|week|month|year)
  - 返回：{
      current: number,
      previous: number,
      change: number,
      changePercent: number,
      trend: AssetRecord[]
    }

POST /api/assets/:id/records
  - 添加新的资产记录
  - 请求体：{ value, quantity, unitPrice, note, recordDate }
  - 返回：AssetRecord

PUT /api/assets/:id/records/:recordId
  - 更新资产记录
  - 请求体：{ value, quantity, unitPrice, note }
  - 返回：AssetRecord

DELETE /api/assets/:id/records/:recordId
  - 删除资产记录
  - 返回：{ success: boolean }
```

---

## 4. UI/UX 设计

### 4.1 资产列表页面

**布局**：
- 顶部：搜索栏 + 筛选按钮 + 添加资产按钮
- 中间：资产卡片网格（2-3 列）
- 底部：分页或无限滚动

**资产卡片内容**：
```
┌─────────────────────────┐
│ [图标] 资产名称          │
│ 类型：房产              │
│ ─────────────────────── │
│ 当前价值：¥ 2,500,000   │
│ 变化：+5% (↑ ¥125,000)  │
│ ─────────────────────── │
│ [编辑] [删除] [详情]    │
└─────────────────────────┘
```

**交互**：
- 点击卡片进入详情页
- 长按卡片显示快速操作菜单
- 支持拖拽排序（可选）

### 4.2 资产详情页面

**顶部信息区**：
- 资产名称、类型、图标
- 当前价值（大字体显示）
- 变化趋势（百分比 + 金额）

**标签页**：

#### Tab 1: 概览 (Overview)
```
- 基本信息
  - 资产名称
  - 资产类型
  - 创建日期
  - 最后更新

- 自定义字段
  - 根据 fieldsSchema 动态显示

- 快速统计
  - 总价值
  - 平均价值
  - 最高/最低价值
```

#### Tab 2: 数据趋势 (Trends)
```
- 时间周期选择器
  - 日 (Day)
  - 周 (Week)
  - 月 (Month)
  - 年 (Year)

- 趋势图表
  - 折线图：价值变化趋势
  - 柱状图：周期对比
  - 面积图：累积变化

- 数据表格
  - 日期 | 价值 | 数量 | 单价 | 变化
```

#### Tab 3: 历史记录 (History)
```
- 记录列表
  - 日期 | 价值 | 数量 | 单价 | 备注 | 操作

- 操作
  - 编辑记录
  - 删除记录
  - 添加新记录
```

### 4.3 添加/编辑资产对话框

**步骤 1: 选择资产类型**
```
- 显示所有可用的资产类型
- 支持搜索和筛选
- 显示类型描述和字段信息
```

**步骤 2: 填写基本信息**
```
- 资产名称 (必填)
- 位置 (可选)
- 初始价值 (必填)
```

**步骤 3: 填写自定义字段**
```
- 根据 fieldsSchema 动态生成表单
- 支持各种数据类型的输入
- 实时验证
```

**步骤 4: 确认并保存**
```
- 显示摘要信息
- 保存按钮
```

### 4.4 数据查询周期

**支持的周期**：
- **日 (Day)**：显示每天的数据
- **周 (Week)**：显示每周的汇总数据
- **月 (Month)**：显示每月的汇总数据
- **年 (Year)**：显示每年的汇总数据

**查询逻辑**：
```
1. 获取指定时间范围内的所有记录
2. 按周期分组
3. 计算每个周期的统计值（平均、最大、最小、总和）
4. 返回格式化的数据用于图表展示
```

---

## 5. 数据库设计

### 5.1 表结构

**asset_types 表**：
```sql
CREATE TABLE asset_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  icon TEXT,
  color TEXT,
  fields_schema TEXT,  -- JSON 格式
  is_system INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

**assets 表**：
```sql
CREATE TABLE assets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  location TEXT,
  custom_data TEXT,  -- JSON 格式
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (type_id) REFERENCES asset_types(id)
);
```

**asset_records 表**：
```sql
CREATE TABLE asset_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  value REAL NOT NULL,
  quantity REAL,
  unit_price REAL,
  note TEXT,
  record_date INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
);
```

### 5.2 索引优化

```sql
-- 加快资产类型查询
CREATE INDEX idx_asset_types_is_system ON asset_types(is_system);

-- 加快资产查询
CREATE INDEX idx_assets_type_id ON assets(type_id);

-- 加快记录查询
CREATE INDEX idx_asset_records_asset_id ON asset_records(asset_id);
CREATE INDEX idx_asset_records_date ON asset_records(record_date);
CREATE INDEX idx_asset_records_asset_date ON asset_records(asset_id, record_date);
```

---

## 6. 业务逻辑

### 6.1 资产价值计算

**当前价值**：
```
currentValue = 最新记录的 value 字段
```

**变化计算**：
```
previousValue = 前一个周期的 value
change = currentValue - previousValue
changePercent = (change / previousValue) * 100
```

**趋势分析**：
```
1. 获取指定周期内的所有记录
2. 按时间排序
3. 计算每个时间点的变化率
4. 生成趋势数据
```

### 6.2 周期数据聚合

**日周期**：
```
- 每天一条记录
- 如果一天有多条记录，取最后一条
```

**周周期**：
```
- 按周分组（周一至周日）
- 计算周平均值、周末值
- 计算周变化
```

**月周期**：
```
- 按月分组
- 计算月平均值、月末值
- 计算月变化
```

**年周期**：
```
- 按年分组
- 计算年平均值、年末值
- 计算年变化
```

### 6.3 自定义字段验证

```
1. 检查必填字段是否填写
2. 根据字段类型进行格式验证
3. 检查数值范围（如果定义了）
4. 检查枚举值是否在允许的选项中
```

---

## 7. 实现路线图

### Phase 1: 基础设施 (Week 1-2)
- [ ] 完善数据库迁移脚本
- [ ] 实现资产类型 Repository
- [ ] 实现资产 Repository
- [ ] 实现资产记录 Repository
- [ ] 初始化系统预定义资产类型

### Phase 2: 核心功能 (Week 3-4)
- [ ] 实现资产列表页面
- [ ] 实现添加/编辑资产对话框
- [ ] 实现资产详情页面
- [ ] 实现基本的 CRUD 操作

### Phase 3: 数据分析 (Week 5-6)
- [ ] 实现资产记录管理
- [ ] 实现周期数据查询
- [ ] 实现趋势图表展示
- [ ] 实现数据统计功能

### Phase 4: 优化和完善 (Week 7-8)
- [ ] 性能优化
- [ ] 错误处理和验证
- [ ] 用户体验优化
- [ ] 测试和 Bug 修复

---

## 8. 技术栈

### 前端
- **框架**：Flutter
- **状态管理**：Provider
- **图表库**：Syncfusion Charts
- **数据库**：SQLite

### 后端（如适用）
- **API 框架**：RESTful API
- **数据验证**：JSON Schema
- **缓存**：内存缓存

---

## 9. 关键考虑事项

### 9.1 数据类型支持
- 支持多种数据类型：数值、货币、日期、文本、枚举
- 支持多币种显示
- 支持百分比和比率计算

### 9.2 性能优化
- 使用数据库索引加快查询
- 实现数据缓存机制
- 分页加载大数据集
- 异步加载图表数据

### 9.3 数据安全
- 验证所有用户输入
- 防止 SQL 注入
- 加密敏感数据（如有需要）

### 9.4 用户体验
- 提供清晰的错误提示
- 支持撤销/重做操作
- 实现快速搜索和筛选
- 提供数据导出功能

---

## 10. 扩展功能（未来考虑）

- [ ] 资产对比分析
- [ ] 投资组合优化建议
- [ ] 自动数据更新（API 集成）
- [ ] 数据备份和恢复
- [ ] 多用户支持
- [ ] 云同步功能
- [ ] 移动端适配
- [ ] 数据导入/导出

---

## 11. 文件结构参考

```
lib/
├── models/
│   ├── asset_type.dart          ✓ 已存在
│   ├── asset.dart               ✓ 已存在
│   └── asset_record.dart        ✓ 已存在
├── repositories/
│   ├── asset_type_repository.dart    ✓ 已存在
│   ├── asset_repository.dart         ✓ 已存在
│   └── asset_record_repository.dart  ✓ 已存在
├── providers/
│   ├── asset_type_provider.dart      ✓ 已存在
│   ├── asset_provider.dart           ✓ 已存在
│   └── asset_record_provider.dart    ✓ 已存在
├── screens/
│   ├── asset_list_screen.dart        ✓ 已存在
│   ├── asset_detail_screen.dart      ✓ 已存在
│   └── asset_management_screen.dart  (新建)
├── widgets/
│   ├── asset_card.dart               (新建)
│   ├── asset_form_dialog.dart        ✓ 已存在
│   ├── asset_trend_chart.dart        ✓ 已存在
│   ├── asset_distribution_chart.dart ✓ 已存在
│   └── period_selector.dart          (新建)
└── utils/
    └── asset_calculator.dart         (新建)
```

---

## 12. 下一步行动

1. **数据库迁移**：确保所有表结构和索引已创建
2. **系统初始化**：在应用首次启动时初始化预定义资产类型
3. **UI 实现**：按照设计稿实现各个页面和组件
4. **API 集成**：实现数据查询和操作的业务逻辑
5. **测试**：编写单元测试和集成测试

---

**文档版本**：1.0
**最后更新**：2026-03-06
**状态**：待审核和实现
