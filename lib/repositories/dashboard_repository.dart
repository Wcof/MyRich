import '../models/dashboard_model.dart';
import '../database/database_helper.dart';

class DashboardRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Dashboard>> getAllDashboards() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> dashboardMaps = await db.query(
      'dashboards',
      orderBy: 'created_at DESC',
    );

    final List<Dashboard> dashboards = [];
    for (final dashboardMap in dashboardMaps) {
      final widgets = await getWidgetsByDashboardId(dashboardMap['id'] as String);
      dashboards.add(Dashboard.fromMap(dashboardMap, widgets));
    }
    return dashboards;
  }

  Future<Dashboard?> getDashboardById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.query(
      'dashboards',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final widgets = await getWidgetsByDashboardId(id);
    return Dashboard.fromMap(results.first, widgets);
  }

  Future<Dashboard?> getDefaultDashboard() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.query(
      'dashboards',
      where: 'is_default = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final widgets = await getWidgetsByDashboardId(results.first['id'] as String);
    return Dashboard.fromMap(results.first, widgets);
  }

  Future<List<DashboardWidget>> getWidgetsByDashboardId(String dashboardId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> widgetMaps = await db.query(
      'dashboard_widgets',
      where: 'dashboard_id = ?',
      whereArgs: [dashboardId],
      orderBy: 'y ASC, x ASC',
    );

    return widgetMaps.map((map) => DashboardWidget.fromMap(map)).toList();
  }

  Future<String> insertDashboard(Dashboard dashboard) async {
    final db = await _dbHelper.database;
    final dashboardId = dashboard.id;

    await db.insert('dashboards', {
      'id': dashboardId,
      'name': dashboard.name,
      'is_default': 0,
      'created_at': dashboard.createdAt.toIso8601String(),
      'updated_at': dashboard.updatedAt.toIso8601String(),
    });

    for (final widget in dashboard.widgets) {
      await insertWidget(widget, dashboardId);
    }

    return dashboardId;
  }

  Future<void> insertWidget(DashboardWidget widget, String dashboardId) async {
    final db = await _dbHelper.database;
    final widgetMap = widget.toMap();
    widgetMap['dashboard_id'] = dashboardId;
    await db.insert('dashboard_widgets', widgetMap);
  }

  Future<void> updateDashboard(Dashboard dashboard) async {
    final db = await _dbHelper.database;
    await db.update(
      'dashboards',
      {
        'name': dashboard.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [dashboard.id],
    );
  }

  Future<void> updateWidget(DashboardWidget widget, String dashboardId) async {
    final db = await _dbHelper.database;
    final widgetMap = widget.toMap();
    widgetMap['dashboard_id'] = dashboardId;
    await db.update(
      'dashboard_widgets',
      widgetMap,
      where: 'id = ?',
      whereArgs: [widget.id],
    );
  }

  Future<void> deleteDashboard(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'dashboard_widgets',
      where: 'dashboard_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'dashboards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteWidget(String widgetId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'dashboard_widgets',
      where: 'id = ?',
      whereArgs: [widgetId],
    );
  }

  Future<void> saveWidgets(String dashboardId, List<DashboardWidget> widgets) async {
    final db = await _dbHelper.database;
    
    final existingWidgets = await getWidgetsByDashboardId(dashboardId);
    final existingIds = existingWidgets.map((w) => w.id).toSet();
    final newIds = widgets.map((w) => w.id).toSet();
    
    final toDelete = existingIds.difference(newIds);
    for (final id in toDelete) {
      await deleteWidget(id);
    }
    
    for (final widget in widgets) {
      if (existingIds.contains(widget.id)) {
        await updateWidget(widget, dashboardId);
      } else {
        await insertWidget(widget, dashboardId);
      }
    }
  }
}
