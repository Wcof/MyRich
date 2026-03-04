class DatabaseMigrations {
  static const int currentVersion = 1;

  static String get createAssetTypesTable => '''
    CREATE TABLE asset_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      icon TEXT,
      color TEXT,
      fields_schema TEXT,
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

  static String get createIndexes => '''
batch
    CREATE INDEX idx_asset_records_asset_id ON asset_records(asset_id);
    CREATE INDEX idx_asset_records_record_date ON asset_records(record_date);
    CREATE INDEX idx_assets_type_id ON assets(type_id);
  ''';

  static List<String> get allTables => [
    createAssetTypesTable,
    createAssetsTable,
    createAssetRecordsTable,
    createDashboardConfigsTable,
  ];
}
