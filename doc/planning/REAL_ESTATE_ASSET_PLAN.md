# 房产资产管理方案 - 完整设计

**创建时间**: 2026-03-10
**项目阶段**: MVP 房产资产管理
**目标**: 实现房产、贷款、租赁收益的完整关联管理

---

## 一、核心需求

### 1.1 房产资产管理

用户需要从多个维度管理房产资产：
- **固定价值线**：购置价格、装修投入等历史成本
- **市场价值线**：当前市场价（多来源对比）
- **融资信息**：贷款详情、还款进度
- **收入信息**：租赁收益、收益率

### 1.2 关联资产类型

房产资产需要支持关联创建：
1. **贷款资产** - 房产相关的债务
2. **租赁收益资产** - 房产出租的收入

---

## 二、资产类型设计

### 2.1 房产 (RealEstate)

**基础信息**
```
名称: 房屋名称
地址: 具体位置
面积: 建筑面积/使用面积
房型: 几室几厅
购置日期: 购买日期
购置价格: 当时成交价
```

**价值信息**
```
固定价值:
  - 购置价格
  - 装修投入
  - 改造投入
  - 总投入成本

市场价值:
  - 当前市场价 (多来源)
  - 来源1: 链家评估价
  - 来源2: 贝壳找房价
  - 来源3: 专业评估机构
  - 来源4: 用户自定义价格
  - 更新频率: 月度/季度/年度
```

**计算字段**
```
房产净值 = 市场价 - 贷款余额
杠杆率 = 贷款 / 市场价
```

### 2.2 贷款 (Loan) - 新增

**基础信息**
```
贷款类型: 公积金/商业贷款/混合
贷款金额: 初始贷款金额
贷款利率: 年利率
贷款期限: 贷款年数
还款方式: 等额本息/等额本金
贷款日期: 贷款开始日期
到期日期: 贷款到期日期
```

**还款信息**
```
已还款金额: 已还总额
剩余贷款: 当前贷款余额
月还款额: 每月还款金额
```

**关联信息**
```
关联房产: 房产ID
关联状态: 活跃/已结清
```

### 2.3 租赁收益 (RentalIncome) - 新增

**基础信息**
```
租赁状态: 自住/出租
月租金: 每月租金收入
租赁期限: 租赁合同期限
租赁开始日期: 租赁开始日期
租赁结束日期: 租赁结束日期
租户信息: 租户名称 (可选)
```

**收益信息**
```
年租赁收入: 月租金 × 12
租金收益率: 年租赁收入 / 房产市场价
投资回报率: 年租赁收入 / 房产购置价格
```

**关联信息**
```
关联房产: 房产ID
关联状态: 活跃/已结束
```

---

## 三、数据关系设计

### 3.1 关联关系图

```
房产 (RealEstate)
├── 一对多 → 贷款 (Loan)
│   └─ 房产可能有多笔贷款
├── 一对一 → 租赁收益 (RentalIncome)
│   └─ 房产最多一个租赁收益记录
└── 一对多 → 市场价格记录 (PriceHistory)
    └─ 多个来源的价格记录
```

### 3.2 创建流程

```
用户创建房产
    ↓
输入房产基础信息
    ↓
输入房产价值信息
    ↓
是否有贷款？
├─ 是 → 同时创建贷款资产
│       ├─ 贷款类型
│       ├─ 贷款金额
│       ├─ 贷款利率
│       └─ 还款方式
└─ 否 → 跳过

是否出租？
├─ 是 → 同时创建租赁收益资产
│       ├─ 月租金
│       ├─ 租赁期限
│       └─ 租户信息
└─ 否 → 跳过

完成创建
```

---

## 四、多维度分析

### 4.1 资产价值分析

| 维度 | 计算方式 | 用途 |
|------|--------|------|
| **固定价值** | 购置价格 + 装修投入 | 成本基准 |
| **市场价值** | 多来源平均价格 | 当前资产价值 |
| **净资产** | 市场价值 - 贷款余额 | 真实净值 |
| **增值** | 市场价值 - 固定价值 | 资产增长 |

### 4.2 收益分析

| 指标 | 计算方式 | 说明 |
|------|--------|------|
| **年租赁收入** | 月租金 × 12 | 年度租赁收入 |
| **租金收益率** | 年租赁收入 / 市场价值 | 基于市场价的收益率 |
| **投资回报率** | 年租赁收入 / 购置价格 | 基于购置价的收益率 |
| **净收益** | 年租赁收入 - 年贷款利息 | 扣除贷款利息后的收益 |

### 4.3 风险分析

| 指标 | 计算方式 | 说明 |
|------|--------|------|
| **杠杆率** | 贷款 / 市场价值 | 债务风险 |
| **还款压力** | 月还款额 / 月租金 | 租金覆盖还款的比例 |
| **流动性** | 市场价值 / 总资产 | 资产流动性 |

---

## 五、实现步骤

### Phase 1：数据模型设计（Week 1）

**需要初始化的内容**：

#### 1. 添加贷款资产类型

在 `lib/database/migrations.dart` 中添加贷款表：

```sql
CREATE TABLE loans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  loan_type TEXT NOT NULL,
  loan_amount REAL NOT NULL,
  loan_rate REAL NOT NULL,
  loan_period INTEGER NOT NULL,
  repayment_method TEXT NOT NULL,
  loan_date INTEGER NOT NULL,
  due_date INTEGER NOT NULL,
  paid_amount REAL DEFAULT 0,
  remaining_amount REAL NOT NULL,
  monthly_payment REAL NOT NULL,
  status TEXT DEFAULT 'active',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
)
```

#### 2. 添加租赁收益资产类型

在 `lib/database/migrations.dart` 中添加租赁收益表：

```sql
CREATE TABLE rental_incomes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  rental_status TEXT NOT NULL,
  monthly_rent REAL NOT NULL,
  rental_start_date INTEGER NOT NULL,
  rental_end_date INTEGER,
  tenant_name TEXT,
  annual_income REAL NOT NULL,
  status TEXT DEFAULT 'active',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
)
```

#### 3. 添加房产市场价格记录表

在 `lib/database/migrations.dart` 中添加价格历史表：

```sql
CREATE TABLE real_estate_prices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  price REAL NOT NULL,
  source TEXT NOT NULL,
  record_date INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
)
```

### Phase 2：数据模型创建（Week 1）

**需要创建的 Dart 模型**：

#### 1. 创建 `lib/models/loan.dart`

```dart
class Loan {
  final int? id;
  final int assetId;
  final String loanType;
  final double loanAmount;
  final double loanRate;
  final int loanPeriod;
  final String repaymentMethod;
  final int loanDate;
  final int dueDate;
  final double paidAmount;
  final double remainingAmount;
  final double monthlyPayment;
  final String status;
  final int createdAt;
  final int updatedAt;

  Loan({
    this.id,
    required this.assetId,
    required this.loanType,
    required this.loanAmount,
    required this.loanRate,
    required this.loanPeriod,
    required this.repaymentMethod,
    required this.loanDate,
    required this.dueDate,
    required this.paidAmount,
    required this.remainingAmount,
    required this.monthlyPayment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'loan_type': loanType,
      'loan_amount': loanAmount,
      'loan_rate': loanRate,
      'loan_period': loanPeriod,
      'repayment_method': repaymentMethod,
      'loan_date': loanDate,
      'due_date': dueDate,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'monthly_payment': monthlyPayment,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'],
      assetId: map['asset_id'],
      loanType: map['loan_type'],
      loanAmount: map['loan_amount'],
      loanRate: map['loan_rate'],
      loanPeriod: map['loan_period'],
      repaymentMethod: map['repayment_method'],
      loanDate: map['loan_date'],
      dueDate: map['due_date'],
      paidAmount: map['paid_amount'],
      remainingAmount: map['remaining_amount'],
      monthlyPayment: map['monthly_payment'],
      status: map['status'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
```

#### 2. 创建 `lib/models/rental_income.dart`

```dart
class RentalIncome {
  final int? id;
  final int assetId;
  final String rentalStatus;
  final double monthlyRent;
  final int rentalStartDate;
  final int? rentalEndDate;
  final String? tenantName;
  final double annualIncome;
  final String status;
  final int createdAt;
  final int updatedAt;

  RentalIncome({
    this.id,
    required this.assetId,
    required this.rentalStatus,
    required this.monthlyRent,
    required this.rentalStartDate,
    this.rentalEndDate,
    this.tenantName,
    required this.annualIncome,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'rental_status': rentalStatus,
      'monthly_rent': monthlyRent,
      'rental_start_date': rentalStartDate,
      'rental_end_date': rentalEndDate,
      'tenant_name': tenantName,
      'annual_income': annualIncome,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory RentalIncome.fromMap(Map<String, dynamic> map) {
    return RentalIncome(
      id: map['id'],
      assetId: map['asset_id'],
      rentalStatus: map['rental_status'],
      monthlyRent: map['monthly_rent'],
      rentalStartDate: map['rental_start_date'],
      rentalEndDate: map['rental_end_date'],
      tenantName: map['tenant_name'],
      annualIncome: map['annual_income'],
      status: map['status'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  double get rentalYield => annualIncome / 12; // 月收益率
}
```

### Phase 3：Repository 层实现（Week 2）

**需要创建的 Repository**：

#### 1. 创建 `lib/repositories/loan_repository.dart`
- 实现 CRUD 操作
- 按资产 ID 查询贷款
- 计算贷款相关指标

#### 2. 创建 `lib/repositories/rental_income_repository.dart`
- 实现 CRUD 操作
- 按资产 ID 查询租赁收益
- 计算收益率

### Phase 4：Provider 层实现（Week 2）

**需要创建的 Provider**：

#### 1. 创建 `lib/providers/loan_provider.dart`
- 管理贷款列表状态
- 加载、添加、更新、删除贷款

#### 2. 创建 `lib/providers/rental_income_provider.dart`
- 管理租赁收益状态
- 加载、添加、更新、删除租赁收益

### Phase 5：UI 层实现（Week 3）

**需要创建的 UI 组件**：

#### 1. 房产详情页面增强
- 显示房产基本信息
- 显示多来源市场价对比
- 显示关联的贷款信息
- 显示关联的租赁收益信息

#### 2. 贷款管理对话框
- 创建贷款时的表单
- 编辑贷款信息
- 显示还款进度

#### 3. 租赁收益管理对话框
- 创建租赁收益时的表单
- 编辑租赁收益信息
- 显示收益率

### Phase 6：多维度分析（Week 4）

**需要实现的分析功能**：

#### 1. 资产价值分析
- 固定价值 vs 市场价值对比
- 资产增值计算
- 净资产计算

#### 2. 收益分析
- 租金收益率计算
- 投资回报率计算
- 净收益计算

#### 3. 风险分析
- 杠杆率计算
- 还款压力分析
- 流动性分析

---

## 六、关键设计决策

### 6.1 关联创建流程

创建房产时，支持同时创建关联资产：
- 如果有贷款，自动创建贷款资产
- 如果出租，自动创建租赁收益资产
- 用户可以选择跳过

### 6.2 多来源价格对比

房产市场价支持多个来源：
- 链家评估价
- 贝壳找房价
- 专业评估机构
- 用户自定义价格

### 6.3 计算字段

所有计算字段都在 Model 层实现，不存储在数据库：
- 房产净值 = 市场价 - 贷款余额
- 年租赁收入 = 月租金 × 12
- 租金收益率 = 年租赁收入 / 市场价值

---

## 七、测试计划

- [ ] 房产创建和关联贷款
- [ ] 房产创建和关联租赁收益
- [ ] 多来源价格对比
- [ ] 贷款还款进度计算
- [ ] 收益率计算
- [ ] 风险指标计算
- [ ] UI 交互测试

---

## 八、后续扩展

- 支持房产保险资产
- 支持房产维修成本记录
- 支持房产税费记录
- 支持房产评估历史
- 支持房产投资分析报告
