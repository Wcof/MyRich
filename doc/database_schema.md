# 数据库表结构

## asset_types 表（资产类型）

```sql
CREATE TABLE asset_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  fields_schema TEXT,  -- JSON格式存储自定义字段定义
  is_system INTEGER DEFAULT 0,  -- 是否系统预定义
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### 字段说明
- `id`: 主键
- `name`: 资产类型名称
- `icon`: 图标名称
- `color`: 颜色值（十六进制）
- `fields_schema`: 自定义字段定义（JSON 格式）
- `is_system`: 是否系统预定义（0=否，1=是）
- `created_at`: 创建时间（Unix 时间戳，毫秒）
- `updated_at`: 更新时间（Unix 时间戳，毫秒）

## assets 表（资产）

```sql
CREATE TABLE assets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  location TEXT,  -- 资产所在位置(银行、券商等)
  custom_data TEXT,  -- JSON格式存储自定义字段数据
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (type_id) REFERENCES asset_types(id)
);
```

### 字段说明
- `id`: 主键
- `type_id`: 资产类型 ID（外键）
- `name`: 资产名称
- `location`: 资产所在位置
- `custom_data`: 自定义字段数据（JSON 格式）
- `created_at`: 创建时间（Unix 时间戳，毫秒）
- `updated_at`: 更新时间（Unix 时间戳，毫秒）

## asset_records 表（资产记录/快照）

```sql
CREATE TABLE asset_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  value REAL NOT NULL,  -- 资产价值
  quantity REAL,  -- 数量(如股票数量)
  unit_price REAL,  -- 单价
  note TEXT,
  record_date INTEGER NOT NULL,  -- 记录日期
  created_at INTEGER NOT NULL,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
);
```

### 字段说明
- `id`: 主键
- `asset_id`: 资产 ID（外键）
- `value`: 资产价值
- `quantity`: 数量
- `unit_price`: 单价
- `note`: 备注
- `record_date`: 记录日期（Unix 时间戳，毫秒）
- `created_at`: 创建时间（Unix 时间戳，毫秒）

## dashboard_configs 表（看板配置）

```sql
CREATE TABLE dashboard_configs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  layout TEXT NOT NULL,  -- JSON格式存储看板布局配置
  is_default INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### 字段说明
- `id`: 主键
- `name`: 看板名称
- `layout`: 看板布局配置（JSON 格式）
- `is_default`: 是否默认看板（0=否，1=是）
- `created_at`: 创建时间（Unix 时间戳，毫秒）
- `updated_at`: 更新时间（Unix 时间戳，毫秒）

## 索引

```sql
CREATE INDEX idx_asset_records_asset_id ON asset_records(asset_id);
CREATE INDEX idx_asset_records_record_date ON asset_records(record_date);
CREATE INDEX idx_assets_type_id ON assets(type_id);
```
