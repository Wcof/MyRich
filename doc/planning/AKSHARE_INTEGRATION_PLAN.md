# AKShare 集成方案 - 基金和股票实时数据支持

**创建时间**: 2026-03-09
**项目阶段**: MVP 数据源优化
**目标**: 通过 AKShare 库实现基金和股票的实时数据更新

---

## 一、核心需求

### 1.1 基金数据支持

**ETF 基金**
- 获取 ETF 的实时持仓股票
- 实时更新持仓股票的价格
- 计算 ETF 的实时净值（基于持仓股票）
- 分钟级更新走势图

**聚合类基金**
- 获取基金的持仓股票列表
- 展示基金下所有持仓股票
- 用户可以单独查看每个股票的走势
- 日线更新基金净值

### 1.2 股票数据支持

- 获取股票的分钟级 K 线数据
- 实时更新股票价格
- 支持多个时间周期（1分钟、5分钟、15分钟等）

---

## 二、技术架构

### 2.1 整体架构

```
Flutter App (MyRich)
    ↓ HTTP 请求
Python 后端服务 (Flask/FastAPI)
    ↓ 调用
AKShare 库
    ↓
金融数据源
```

### 2.2 后端服务设计

**技术栈**：
- Python 3.8+
- Flask 或 FastAPI
- AKShare 库
- SQLite 缓存（可选）

**核心模块**：
1. **基金数据服务** (`fund_service.py`)
   - ETF 持仓查询
   - 基金持仓查询
   - 基金净值计算

2. **股票数据服务** (`stock_service.py`)
   - 股票分钟 K 线数据
   - 实时股票价格
   - 股票基本信息

3. **缓存管理** (`cache_manager.py`)
   - 缓存 API 响应
   - 避免频繁调用

4. **API 接口** (`api.py`)
   - RESTful API 端点
   - 数据格式转换

### 2.3 数据流

```
用户操作
    ↓
Flutter 发送 HTTP 请求
    ↓
Python 后端接收请求
    ↓
检查缓存
    ├─ 缓存命中 → 返回缓存数据
    └─ 缓存未命中 → 调用 AKShare
        ↓
    处理数据
        ↓
    缓存结果
        ↓
    返回给 Flutter
        ↓
Flutter 更新 UI
```

---

## 三、AKShare API 支持

### 3.1 基金相关 API

| API 名称 | 功能 | 返回数据 |
|---------|------|--------|
| `fund_etf_portfolio_web()` | ETF 持仓查询 | 持仓股票列表、占比 |
| `fund_portfolio_hold_em()` | 基金持仓查询 | 持仓股票列表、占比 |
| `fund_base_info_sina()` | 基金基本信息 | 基金名称、代码、类型 |
| `fund_daily_sina()` | 基金日线数据 | 净值、日期 |

### 3.2 股票相关 API

| API 名称 | 功能 | 返回数据 |
|---------|------|--------|
| `stock_zh_a_hist_min_em()` | 股票分钟 K 线 | OHLC、成交量 |
| `stock_zh_a_spot_em()` | 实时股票行情 | 价格、涨跌幅 |
| `stock_info_a_sina()` | 股票基本信息 | 名称、代码、行业 |

---

## 四、实现方案

### 4.1 后端服务启动

**方案 A：Python 脚本（简单）**
```bash
python backend/main.py
# 启动 Flask 服务，监听 http://localhost:5000
```

**方案 B：Docker 容器（推荐）**
```bash
docker-compose up
# 一键启动后端服务
```

### 4.2 Flutter 集成

**创建 API 服务类** (`lib/services/akshare_api_service.dart`)
- 调用后端 API
- 处理响应数据
- 错误处理和重试

**创建数据模型**
- `FundWithStocks` - 基金及其持仓股票
- `StockData` - 股票数据
- `ETFData` - ETF 数据

**创建 Provider**
- `FundDataProvider` - 管理基金数据
- `StockDataProvider` - 管理股票数据

### 4.3 数据更新机制

**ETF 基金**
- 获取 ETF 持仓股票
- 每分钟更新一次股票价格
- 实时计算 ETF 净值

**聚合类基金**
- 获取基金持仓股票
- 每天更新一次基金净值
- 用户可以查看持仓股票的实时价格

**股票**
- 支持多个时间周期
- 分钟级更新

---

## 五、文件结构

### 5.1 后端服务结构

```
backend/
├── main.py                 # 应用入口
├── requirements.txt        # 依赖列表
├── config.py              # 配置文件
├── services/
│   ├── fund_service.py    # 基金数据服务
│   ├── stock_service.py   # 股票数据服务
│   └── cache_manager.py   # 缓存管理
├── api/
│   ├── __init__.py
│   ├── fund_routes.py     # 基金 API 路由
│   └── stock_routes.py    # 股票 API 路由
└── docker-compose.yml     # Docker 配置
```

### 5.2 Flutter 集成文件

```
lib/
├── services/
│   └── akshare_api_service.dart
├── models/
│   ├── fund_with_stocks.dart
│   ├── stock_data.dart
│   └── etf_data.dart
├── providers/
│   ├── fund_data_provider.dart
│   └── stock_data_provider.dart
└── screens/
    ├── fund_detail_screen.dart
    └── stock_chart_screen.dart
```

---

## 六、API 端点设计

### 6.1 基金相关端点

```
GET /api/fund/etf/{code}
- 获取 ETF 持仓股票
- 返回：持仓股票列表、占比

GET /api/fund/portfolio/{code}
- 获取基金持仓股票
- 返回：持仓股票列表、占比

GET /api/fund/info/{code}
- 获取基金基本信息
- 返回：基金名称、类型、净值

GET /api/fund/daily/{code}
- 获取基金日线数据
- 返回：历史净值数据
```

### 6.2 股票相关端点

```
GET /api/stock/kline/{code}?period=1m&limit=100
- 获取股票分钟 K 线
- 参数：period (1m, 5m, 15m), limit (数据条数)
- 返回：OHLC 数据

GET /api/stock/realtime/{code}
- 获取实时股票价格
- 返回：当前价格、涨跌幅

GET /api/stock/info/{code}
- 获取股票基本信息
- 返回：名称、代码、行业
```

---

## 七、实现步骤

### Phase 1：后端服务搭建（Week 1）

- [ ] 创建 Python 后端项目
- [ ] 集成 AKShare 库
- [ ] 实现基金数据服务
- [ ] 实现股票数据服务
- [ ] 创建 API 端点
- [ ] 添加缓存机制

### Phase 2：Flutter 集成（Week 2）

- [ ] 创建 API 服务类
- [ ] 创建数据模型
- [ ] 创建 Provider
- [ ] 实现基金详情页面
- [ ] 实现股票走势图
- [ ] 集成自动更新机制

### Phase 3：优化和完善（Week 3）

- [ ] 性能优化
- [ ] 错误处理
- [ ] 缓存策略优化
- [ ] 测试和调试

---

## 八、关键设计决策

### 8.1 ETF vs 聚合类基金

**ETF 基金**
- 实时更新：基于持仓股票的实时价格
- 更新频率：分钟级
- 用户体验：看到真实的 ETF 净值变化

**聚合类基金**
- 日线更新：基于基金净值
- 展示持仓：用户可以看到基金的真实构成
- 用户体验：了解基金的投资方向

### 8.2 缓存策略

- **ETF 持仓**：缓存 1 小时（持仓变化不频繁）
- **股票 K 线**：缓存 5 分钟（数据更新频繁）
- **基金净值**：缓存 1 天（日线数据）

### 8.3 错误处理

- API 调用失败时，返回缓存数据
- 缓存过期时，返回最后一次有效数据
- 用户可以手动刷新

---

## 九、后端服务示例

### 9.1 基金服务示例

```python
import akshare as ak

class FundService:
    def get_etf_portfolio(self, code):
        """获取 ETF 持仓"""
        df = ak.fund_etf_portfolio_web(symbol=code)
        return df.to_dict('records')

    def get_fund_portfolio(self, code):
        """获取基金持仓"""
        df = ak.fund_portfolio_hold_em(symbol=code)
        return df.to_dict('records')

    def get_fund_daily(self, code):
        """获取基金日线数据"""
        df = ak.fund_daily_sina(symbol=code)
        return df.to_dict('records')
```

### 9.2 股票服务示例

```python
class StockService:
    def get_stock_kline(self, code, period='1m', limit=100):
        """获取股票 K 线"""
        df = ak.stock_zh_a_hist_min_em(
            symbol=code,
            period=period,
            start_date='',
            end_date=''
        )
        return df.tail(limit).to_dict('records')

    def get_stock_realtime(self, code):
        """获取实时股票价格"""
        df = ak.stock_zh_a_spot_em()
        stock = df[df['代码'] == code]
        return stock.to_dict('records')[0]
```

---

## 十、部署方案

### 10.1 本地开发

```bash
# 1. 创建虚拟环境
python -m venv venv
source venv/bin/activate

# 2. 安装依赖
pip install -r requirements.txt

# 3. 启动服务
python main.py
```

### 10.2 Docker 部署

```bash
# 1. 构建镜像
docker build -t myrich-backend .

# 2. 运行容器
docker run -p 5000:5000 myrich-backend
```

### 10.3 生产部署

- 使用 Gunicorn 作为 WSGI 服务器
- 使用 Nginx 作为反向代理
- 使用 Redis 作为缓存
- 使用 Supervisor 管理进程

---

## 十一、测试计划

- [ ] 基金持仓查询测试
- [ ] 股票 K 线数据测试
- [ ] 缓存机制测试
- [ ] API 端点测试
- [ ] 错误处理测试
- [ ] 性能测试

---

## 十二、注意事项

1. **API 限制**：AKShare 可能有请求频率限制，需要实现缓存和限流
2. **数据准确性**：确保数据源的准确性和及时性
3. **错误处理**：处理网络错误、API 错误等异常情况
4. **性能优化**：优化数据库查询和缓存策略
5. **安全性**：保护 API 端点，防止滥用

---

## 十三、后续扩展

- 支持更多数据源（Yahoo Finance、Tushare 等）
- 实现数据分析功能（技术指标、预测等）
- 支持实时推送（WebSocket）
- 支持数据导出和报表生成
