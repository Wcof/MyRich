class DatabaseMigrations {
  static const int currentVersion = 2;

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

  static String get createAssetRecordsTable => '''
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

  static List<String> get allTables => [
    createAssetTypesTable,
    createAssetsTable,
    createAssetRecordsTable,
    createDashboardConfigsTable,
    createDashboardsTable,
    createDashboardWidgetsTable,
  ];
}
