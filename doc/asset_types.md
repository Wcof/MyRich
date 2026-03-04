# 预定义资产类型

## 系统预定义资产类型

以下资产类型在系统初始化时自动创建，标记为 `is_system=1`，不可删除。

```dart
final systemAssetTypes = [
  {'name': '现金', 'icon': 'cash', 'color': '#4CAF50'},
  {'name': '银行存款', 'icon': 'bank', 'color': '#2196F3'},
  {'name': '股票', 'icon': 'trending_up', 'color': '#F44336'},
  {'name': '基金', 'icon': 'pie_chart', 'color': '#FF9800'},
  {'name': '债券', 'icon': 'receipt', 'color': '#9C27B0'},
  {'name': '房产', 'icon': 'home', 'color': '#795548'},
  {'name': '加密货币', 'icon': 'currency_bitcoin', 'color': '#FF5722'},
  {'name': '期货', 'icon': 'show_chart', 'color': '#607D8B'},
  {'name': '借款', 'icon': 'arrow_upward', 'color': '#8BC34A'},
  {'name': '贷款', 'icon': 'arrow_downward', 'color': '#E91E63'},
];
```

## 自定义字段示例

### 股票类型自定义字段

```json
{
  "fields": [
    {
      "name": "股票代码",
      "type": "string",
      "required": true
    },
    {
      "name": "交易所",
      "type": "string",
      "required": true,
      "options": ["上交所", "深交所", "港交所", "纳斯达克", "纽交所"]
    },
    {
      "name": "持仓数量",
      "type": "number",
      "required": true
    }
  ]
}
```

### 房产类型自定义字段

```json
{
  "fields": [
    {
      "name": "地址",
      "type": "string",
      "required": true
    },
    {
      "name": "面积",
      "type": "number",
      "required": true
    },
    {
      "name": "房产类型",
      "type": "string",
      "required": true,
      "options": ["住宅", "商业", "工业", "土地"]
    }
  ]
}
```

## 字段类型

- `string`: 文本类型
- `number`: 数字类型
- `date`: 日期类型
- `select`: 选择类型（需要提供 options）
