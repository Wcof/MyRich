# Dashboard 配置格式文档

## 配置格式

Dashboard 配置使用 JSON 格式存储在 `dashboard_configs` 表的 `layout` 字段中。

### JSON 结构

```json
{
  "cards": [
    {
      "id": "card1",
      "type": "asset_distribution_pie",
      "position": {"x": 0, "y": 0},
      "size": {"width": 2, "height": 2},
      "config": {"timeRange": "all"}
    },
    {
      "id": "card2",
      "type": "asset_trend_line",
      "position": {"x": 2, "y": 0},
      "size": {"width": 2, "height": 2},
      "config": {"assetTypes": ["stock", "fund"]}
    }
  ]
}
```

### 字段说明

#### cards 数组
- `id`: 卡片唯一标识符
- `type`: 卡片类型
  - `asset_distribution_pie`: 资产分布饼图
  - `asset_trend_line`: 资产走势折线图
  - `asset_card`: 资产卡片
  - `stat_card`: 统计卡片
- `position`: 卡片位置
  - `x`: X 坐标（网格列）
  - `y`: Y 坐标（网格行）
- `size`: 卡片大小
  - `width`: 宽度（网格单位）
  - `height`: 高度（网格单位）
- `config`: 卡片配置（根据类型不同而不同）

### 默认配置

```json
{
  "cards": [
    {
      "id": "total_assets",
      "type": "stat_card",
      "position": {"x": 0, "y": 0},
      "size": {"width": 2, "height": 1},
      "config": {
        "title": "总资产",
        "metric": "total_value",
        "timeRange": "all"
      }
    },
    {
      "id": "distribution",
      "type": "asset_distribution_pie",
      "position": {"x": 0, "y": 1},
      "size": {"width": 2, "height": 2},
      "config": {"timeRange": "all"}
    },
    {
      "id": "trend",
      "type": "asset_trend_line",
      "position": {"x": 2, "y": 0},
      "size": {"width": 2, "height": 3},
      "config": {"timeRange": "month"}
    }
  ]
}
```
