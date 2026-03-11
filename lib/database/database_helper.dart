import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'migrations.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocDir.path, 'myrich.db');

    final database = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: DatabaseMigrations.currentVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );

    return database;
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final table in DatabaseMigrations.allTables) {
      batch.execute(table);
    }
    await batch.commit();
    
    await _createIndexes(db);
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    switch (oldVersion) {
      case 1:
        await _migrateFromV1ToV2(db);
        await _migrateFromV2ToV3(db);
        await _migrateFromV3ToV4(db);
        await _migrateFromV4ToV5(db);
        await _migrateFromV5ToV6(db);
        await _migrateFromV6ToV7(db);
        await _migrateFromV7ToV8(db);
        break;
      case 2:
        await _migrateFromV2ToV3(db);
        await _migrateFromV3ToV4(db);
        await _migrateFromV4ToV5(db);
        await _migrateFromV5ToV6(db);
        await _migrateFromV6ToV7(db);
        await _migrateFromV7ToV8(db);
        break;
      case 3:
        await _migrateFromV3ToV4(db);
        await _migrateFromV4ToV5(db);
        await _migrateFromV5ToV6(db);
        await _migrateFromV6ToV7(db);
        await _migrateFromV7ToV8(db);
        break;
      case 4:
        await _migrateFromV4ToV5(db);
        await _migrateFromV5ToV6(db);
        await _migrateFromV6ToV7(db);
        await _migrateFromV7ToV8(db);
        break;
      case 5:
        await _migrateFromV5ToV6(db);
        await _migrateFromV6ToV7(db);
        await _migrateFromV7ToV8(db);
        break;
      case 6:
        await _migrateFromV6ToV7(db);
        await _migrateFromV7ToV8(db);
        break;
      case 7:
        await _migrateFromV7ToV8(db);
        break;
      default:
        break;
    }
  }

  Future<void> _migrateFromV1ToV2(Database db) async {
    await db.execute(DatabaseMigrations.createDashboardsTable);
    await db.execute(DatabaseMigrations.createDashboardWidgetsTable);
  }

  Future<void> _migrateFromV2ToV3(Database db) async {
    await db.execute(DatabaseMigrations.createAssetDetailsTable);
    
    await db.execute('''
      ALTER TABLE asset_records ADD COLUMN asset_detail_id INTEGER;
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_details_asset_id ON asset_details(asset_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_details_detail_type ON asset_details(detail_type);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_details_created_at ON asset_details(created_at DESC);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_details_asset_created ON asset_details(asset_id, created_at DESC);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_records_detail_id ON asset_records(asset_detail_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_records_detail_date ON asset_records(asset_detail_id, record_date DESC);
    ''');
  }

  Future<void> _migrateFromV3ToV4(Database db) async {
    await db.execute('''
      ALTER TABLE asset_records ADD COLUMN is_revoked INTEGER DEFAULT 0;
    ''');
  }

  Future<void> _migrateFromV4ToV5(Database db) async {
    await db.execute('''
      ALTER TABLE asset_records ADD COLUMN status INTEGER DEFAULT 0;
    ''');
    
    await db.execute('''
      UPDATE asset_records 
      SET status = 1 
      WHERE status = 0 AND is_revoked = 0;
    ''');
  }

  Future<void> _migrateFromV5ToV6(Database db) async {
    await db.execute(DatabaseMigrations.createFundPlansTable);
  }

  Future<void> _migrateFromV6ToV7(Database db) async {
    await db.execute(DatabaseMigrations.createLoansTable);
    await db.execute(DatabaseMigrations.createRentalIncomesTable);
    await db.execute(DatabaseMigrations.createRealEstatePricesTable);
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_loans_asset_id ON loans(asset_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_loans_status ON loans(status);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_rental_incomes_asset_id ON rental_incomes(asset_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_rental_incomes_status ON rental_incomes(status);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_real_estate_prices_asset_id ON real_estate_prices(asset_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_real_estate_prices_record_date ON real_estate_prices(record_date DESC);
    ''');
  }

  Future<void> _migrateFromV7ToV8(Database db) async {
    await db.execute('''
      ALTER TABLE loans ADD COLUMN custom_loan_type TEXT;
    ''');
    await db.execute('''
      ALTER TABLE loans ADD COLUMN receiving_bank_account_id INTEGER;
    ''');
    await db.execute('''
      ALTER TABLE loans ADD COLUMN payment_bank_account_id INTEGER;
    ''');
  }

  Future<void> _migrateFromV8ToV9(Database db) async {
    await db.execute('''
      ALTER TABLE loans ADD COLUMN related_asset_id INTEGER;
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_records_asset_id ON asset_records(asset_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_records_record_date ON asset_records(record_date);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_assets_type_id ON assets(type_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_details_asset_id ON asset_details(asset_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_details_detail_type ON asset_details(detail_type);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_details_created_at ON asset_details(created_at DESC);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_details_asset_created ON asset_details(asset_id, created_at DESC);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_records_detail_id ON asset_records(asset_detail_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_asset_records_detail_date ON asset_records(asset_detail_id, record_date DESC);
    ''');
  }

  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

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

    for (final type in systemAssetTypes) {
      await db.insert('asset_types', {
        'name': type['name'],
        'icon': type['icon'],
        'color': type['color'],
        'is_system': 1,
        'created_at': now,
        'updated_at': now,
      });
    }

    final defaultDashboardLayout = '''
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
    ''';

    await db.insert('dashboard_configs', {
      'name': '默认看板',
      'layout': defaultDashboardLayout,
      'is_default': 1,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
