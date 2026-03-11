class DatabaseMigrations {
  static const int currentVersion = 9;

  static String get createAssetTypesTable => '''
    CREATE TABLE asset_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      icon TEXT,
      color TEXT,
      is_system INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';

  static String get createAssetsTable => '''
    CREATE TABLE assets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      location TEXT,
      custom_data TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (type_id) REFERENCES asset_types(id)
    )
  ''';

  static String get createAssetDetailsTable => '''
    CREATE TABLE asset_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      asset_id INTEGER NOT NULL,
      detail_type TEXT NOT NULL,
      name TEXT NOT NULL,
      data TEXT NOT NULL,
      version INTEGER DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
    )
  ''';

  static String get createAssetRecordsTable => '''
    CREATE TABLE asset_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      asset_id INTEGER,
      asset_detail_id INTEGER,
      value REAL NOT NULL,
      quantity REAL,
      unit_price REAL,
      note TEXT,
      record_date INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      is_revoked INTEGER DEFAULT 0,
      status INTEGER DEFAULT 0,
      FOREIGN KEY (asset_id) REFERENCES assets(id),
      FOREIGN KEY (asset_detail_id) REFERENCES asset_details(id) ON DELETE CASCADE
    )
  ''';

  static String get createFundPlansTable => '''
    CREATE TABLE fund_plans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      asset_id INTEGER NOT NULL,
      fund_code TEXT NOT NULL,
      fund_name TEXT NOT NULL,
      amount REAL NOT NULL,
      period INTEGER NOT NULL,
      week_day INTEGER,
      month_day INTEGER,
      start_date INTEGER NOT NULL,
      end_date INTEGER,
      status INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      last_executed_at INTEGER,
      next_execute_at INTEGER,
      FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
    )
  ''';

  static String get createDashboardConfigsTable => '''
    CREATE TABLE dashboard_configs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      layout TEXT NOT NULL,
      is_default INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';

  static String get createDashboardsTable => '''
    CREATE TABLE dashboards (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      is_default INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static String get createDashboardWidgetsTable => '''
    CREATE TABLE dashboard_widgets (
      id TEXT PRIMARY KEY,
      dashboard_id TEXT NOT NULL,
      title TEXT NOT NULL,
      type TEXT NOT NULL,
      x INTEGER NOT NULL,
      y INTEGER NOT NULL,
      w INTEGER NOT NULL,
      h INTEGER NOT NULL,
      config TEXT,
      FOREIGN KEY (dashboard_id) REFERENCES dashboards(id)
    )
  ''';

  static String get createLoansTable => '''
    CREATE TABLE loans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      asset_id INTEGER NOT NULL,
      loan_type TEXT NOT NULL,
      custom_loan_type TEXT,
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
      receiving_bank_account_id INTEGER,
      payment_bank_account_id INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
    )
  ''';

  static String get createRentalIncomesTable => '''
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
      FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
    )
  ''';

  static String get createRealEstatePricesTable => '''
    CREATE TABLE real_estate_prices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      asset_id INTEGER NOT NULL,
      price REAL NOT NULL,
      source TEXT NOT NULL,
      record_date INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
    )
  ''';

  static List<String> get allTables => [
    createAssetTypesTable,
    createAssetsTable,
    createAssetDetailsTable,
    createAssetRecordsTable,
    createDashboardConfigsTable,
    createDashboardsTable,
    createDashboardWidgetsTable,
    createLoansTable,
    createRentalIncomesTable,
    createRealEstatePricesTable,
  ];
}
