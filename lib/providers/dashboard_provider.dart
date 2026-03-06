import 'package:flutter/foundation.dart';
import '../models/dashboard_model.dart';
import '../repositories/dashboard_repository.dart';
import '../utils/grid_layout_manager.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();

  List<Dashboard> _dashboards = [];
  Dashboard? _currentDashboard;
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _error;

  List<Dashboard> get dashboards => _dashboards;
  Dashboard? get currentDashboard => _currentDashboard;
  bool get isLoading => _isLoading;
  bool get isEditMode => _isEditMode;
  String? get error => _error;

  Future<void> loadDashboards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboards = await _repository.getAllDashboards();
      if (_dashboards.isEmpty) {
        await _createDefaultDashboard();
      }
      _currentDashboard = await _repository.getDefaultDashboard();
      if (_currentDashboard == null && _dashboards.isNotEmpty) {
        _currentDashboard = _dashboards.first;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _createDefaultDashboard() async {
    final now = DateTime.now();
    final defaultDashboard = Dashboard(
      id: 'default',
      name: '默认看板',
      widgets: [
        DashboardWidget(
          id: 'stat_1',
          title: '总资产',
          type: WidgetType.stat,
          x: 0,
          y: 0,
          w: 12,
          h: 6,
          config: {'metric': 'total_value'},
        ),
        DashboardWidget(
          id: 'chart_1',
          title: '资产分布',
          type: WidgetType.chart,
          x: 0,
          y: 6,
          w: 18,
          h: 12,
          config: {'chartType': 'pie'},
        ),
        DashboardWidget(
          id: 'chart_2',
          title: '资产趋势',
          type: WidgetType.chart,
          x: 18,
          y: 0,
          w: 18,
          h: 18,
          config: {'chartType': 'line'},
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await _repository.insertDashboard(defaultDashboard);
    _dashboards = [defaultDashboard];
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  Future<void> selectDashboard(String dashboardId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentDashboard = await _repository.getDashboardById(dashboardId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDashboard(String name) async {
    final now = DateTime.now();
    final newDashboard = Dashboard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      widgets: [],
      createdAt: now,
      updatedAt: now,
    );

    await _repository.insertDashboard(newDashboard);
    _dashboards.add(newDashboard);
    _currentDashboard = newDashboard;
    notifyListeners();
  }

  Future<void> deleteDashboard(String dashboardId) async {
    await _repository.deleteDashboard(dashboardId);
    _dashboards.removeWhere((d) => d.id == dashboardId);
    if (_currentDashboard?.id == dashboardId) {
      _currentDashboard = _dashboards.isNotEmpty ? _dashboards.first : null;
    }
    notifyListeners();
  }

  Future<void> addWidget(DashboardWidget widget, {int maxColumns = 48}) async {
    if (_currentDashboard == null) return;

    final (x, y) = GridLayoutManager.findNextAvailablePosition(
      _currentDashboard!.widgets,
      widget.w,
      widget.h,
      maxColumns: maxColumns,
    );

    final positionedWidget = widget.copyWith(x: x, y: y);
    final updatedWidgets = [..._currentDashboard!.widgets, positionedWidget];

    _currentDashboard = _currentDashboard!.copyWith(
      widgets: updatedWidgets,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persistWidgets(updatedWidgets);
  }

  Future<void> updateWidget(
    DashboardWidget widget, {
    bool persist = true,
    bool resolveOverlap = false,
    int? maxColumns,
  }) async {
    if (_currentDashboard == null) return;

    var updatedWidgets = _currentDashboard!.widgets.map((w) {
      return w.id == widget.id ? widget : w;
    }).toList();

    if (resolveOverlap) {
      updatedWidgets = GridLayoutManager.resolveOverlapsKeeping(
        widget,
        updatedWidgets,
        maxColumns: maxColumns ?? GridLayoutManager.defaultMaxColumns,
      );
    }

    _currentDashboard = _currentDashboard!.copyWith(
      widgets: updatedWidgets,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    if (persist) {
      await _persistWidgets(updatedWidgets);
    }
  }

  Future<void> deleteWidget(String widgetId) async {
    if (_currentDashboard == null) return;

    final updatedWidgets =
        _currentDashboard!.widgets.where((w) => w.id != widgetId).toList();

    _currentDashboard = _currentDashboard!.copyWith(
      widgets: updatedWidgets,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persistWidgets(updatedWidgets);
  }

  Future<void> reorderWidgets(List<DashboardWidget> widgets) async {
    if (_currentDashboard == null) return;

    _currentDashboard = _currentDashboard!.copyWith(
      widgets: widgets,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persistWidgets(widgets);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _persistWidgets(List<DashboardWidget> widgets) async {
    final dashboardId = _currentDashboard?.id;
    if (dashboardId == null) return;

    try {
      await _repository.saveWidgets(dashboardId, widgets);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
