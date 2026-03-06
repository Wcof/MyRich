import '../models/dashboard_model.dart';

class GridLayoutManager {
  static const int defaultMaxColumns = 12;
  static const int defaultMaxRows = 100;

  static List<List<bool>> createOccupancyMatrix(
    List<DashboardWidget> widgets, {
    int maxColumns = defaultMaxColumns,
    int maxRows = defaultMaxRows,
  }) {
    final matrix = List.generate(
      maxRows,
      (_) => List.filled(maxColumns, false),
    );

    for (final widget in widgets) {
      for (int dy = 0; dy < widget.h && (widget.y + dy) < maxRows; dy++) {
        for (int dx = 0; dx < widget.w && (widget.x + dx) < maxColumns; dx++) {
          matrix[widget.y + dy][widget.x + dx] = true;
        }
      }
    }

    return matrix;
  }

  static (int x, int y) findNextAvailablePosition(
    List<DashboardWidget> widgets,
    int newWidgetWidth,
    int newWidgetHeight, {
    int maxColumns = defaultMaxColumns,
    int maxRows = defaultMaxRows,
  }) {
    if (widgets.isEmpty) {
      return (0, 0);
    }

    final matrix = createOccupancyMatrix(
      widgets,
      maxColumns: maxColumns,
      maxRows: maxRows,
    );

    for (int y = 0; y < maxRows - newWidgetHeight + 1; y++) {
      for (int x = 0; x < maxColumns - newWidgetWidth + 1; x++) {
        if (_canPlaceWidget(
            matrix, x, y, newWidgetWidth, newWidgetHeight, maxColumns)) {
          return (x, y);
        }
      }
    }

    return _findLowestRowEnd(widgets, maxColumns);
  }

  static bool _canPlaceWidget(
    List<List<bool>> matrix,
    int x,
    int y,
    int width,
    int height,
    int maxColumns,
  ) {
    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        if (y + dy >= matrix.length || x + dx >= maxColumns) {
          return false;
        }
        if (matrix[y + dy][x + dx]) {
          return false;
        }
      }
    }
    return true;
  }

  static (int x, int y) _findLowestRowEnd(
    List<DashboardWidget> widgets,
    int maxColumns,
  ) {
    if (widgets.isEmpty) {
      return (0, 0);
    }

    int maxY = 0;
    for (final widget in widgets) {
      final bottomY = widget.y + widget.h;
      if (bottomY > maxY) {
        maxY = bottomY;
      }
    }

    int currentX = 0;
    for (final widget in widgets) {
      if (widget.y == maxY - widget.h) {
        final rightX = widget.x + widget.w;
        if (rightX > currentX) {
          currentX = rightX;
        }
      }
    }

    if (currentX + 2 > maxColumns) {
      return (0, maxY);
    }

    return (currentX, maxY - 1 > 0 ? maxY - 1 : maxY);
  }

  static List<DashboardWidget> autoLayout(
    List<DashboardWidget> widgets, {
    int maxColumns = defaultMaxColumns,
  }) {
    if (widgets.isEmpty) return widgets;

    final sortedWidgets = List<DashboardWidget>.from(widgets);
    sortedWidgets.sort((a, b) {
      if (a.y != b.y) return a.y.compareTo(b.y);
      return a.x.compareTo(b.x);
    });

    final matrix = createOccupancyMatrix(
      sortedWidgets,
      maxColumns: maxColumns,
      maxRows: defaultMaxRows,
    );

    final result = <DashboardWidget>[];
    int currentY = 0;
    int currentX = 0;

    for (final widget in sortedWidgets) {
      final (newX, newY) = _findPositionInMatrix(
        matrix,
        widget.w,
        widget.h,
        maxColumns,
        currentX,
        currentY,
      );

      result.add(widget.copyWith(x: newX, y: newY));

      for (int dy = 0; dy < widget.h && (newY + dy) < matrix.length; dy++) {
        for (int dx = 0; dx < widget.w && (newX + dx) < maxColumns; dx++) {
          matrix[newY + dy][newX + dx] = true;
        }
      }

      currentX = newX + widget.w;
      currentY = newY;

      if (currentX >= maxColumns) {
        currentX = 0;
        currentY = _findNextRowY(matrix, maxColumns);
      }
    }

    return result;
  }

  static (int x, int y) _findPositionInMatrix(
    List<List<bool>> matrix,
    int width,
    int height,
    int maxColumns,
    int startX,
    int startY,
  ) {
    for (int y = startY; y < matrix.length - height + 1; y++) {
      for (int x = startX; x < maxColumns - width + 1; x++) {
        if (_canPlaceWidget(matrix, x, y, width, height, maxColumns)) {
          return (x, y);
        }
      }
      startX = 0;
    }
    return (0, matrix.length);
  }

  static List<DashboardWidget> resolveOverlapsKeeping(
    DashboardWidget primary,
    List<DashboardWidget> widgets, {
    int maxColumns = defaultMaxColumns,
    int maxRows = defaultMaxRows,
  }) {
    if (widgets.isEmpty) return widgets;

    final others = widgets.where((w) => w.id != primary.id).toList();
    final ordered = [primary, ...others];

    final matrix = createOccupancyMatrix(
      [],
      maxColumns: maxColumns,
      maxRows: maxRows,
    );

    DashboardWidget placeWidget(
      DashboardWidget widget,
      int x,
      int y,
    ) {
      for (int dy = 0; dy < widget.h && (y + dy) < maxRows; dy++) {
        for (int dx = 0; dx < widget.w && (x + dx) < maxColumns; dx++) {
          matrix[y + dy][x + dx] = true;
        }
      }
      return widget.copyWith(x: x, y: y);
    }

    bool canPlaceAt(DashboardWidget widget, int x, int y) {
      return _canPlaceWidget(matrix, x, y, widget.w, widget.h, maxColumns);
    }

    (int x, int y) findNextPosition(DashboardWidget widget, int startY) {
      for (int y = startY; y < maxRows - widget.h + 1; y++) {
        for (int x = 0; x < maxColumns - widget.w + 1; x++) {
          if (canPlaceAt(widget, x, y)) {
            return (x, y);
          }
        }
      }
      return (0, maxRows - widget.h);
    }

    final result = <DashboardWidget>[];
    for (final widget in ordered) {
      final targetX = widget.x.clamp(0, maxColumns - widget.w);
      final targetY = widget.y.clamp(0, maxRows - widget.h);
      if (canPlaceAt(widget, targetX, targetY)) {
        result.add(placeWidget(widget, targetX, targetY));
      } else {
        final (newX, newY) = findNextPosition(widget, targetY);
        result.add(placeWidget(widget, newX, newY));
      }
    }

    return result;
  }

  static int _findNextRowY(List<List<bool>> matrix, int maxColumns) {
    for (int y = 0; y < matrix.length; y++) {
      bool hasOccupied = false;
      for (int x = 0; x < maxColumns; x++) {
        if (matrix[y][x]) {
          hasOccupied = true;
          break;
        }
      }
      if (!hasOccupied) {
        return y;
      }
    }
    return matrix.length;
  }

  static int calculateGridHeight(
    List<DashboardWidget> widgets, {
    int maxColumns = defaultMaxColumns,
    double cellHeight = 130.0,
  }) {
    if (widgets.isEmpty) return (cellHeight * 2).toInt();

    int maxY = 0;
    for (final widget in widgets) {
      final bottomY = widget.y + widget.h;
      if (bottomY > maxY) maxY = bottomY;
    }

    return ((maxY + 1) * cellHeight).toInt();
  }

  static bool checkOverlap(
    DashboardWidget widget,
    List<DashboardWidget> otherWidgets, {
    String? excludeId,
  }) {
    for (final other in otherWidgets) {
      if (excludeId != null && other.id == excludeId) {
        continue;
      }

      if (_widgetsOverlap(widget, other)) {
        return true;
      }
    }
    return false;
  }

  static bool _widgetsOverlap(DashboardWidget a, DashboardWidget b) {
    final aRight = a.x + a.w;
    final aBottom = a.y + a.h;
    final bRight = b.x + b.w;
    final bBottom = b.y + b.h;

    return !(a.x >= bRight ||
        aRight <= b.x ||
        a.y >= bBottom ||
        aBottom <= b.y);
  }

  static List<DashboardWidget> getWidgetsWithoutId(
    List<DashboardWidget> widgets,
    String excludeId,
  ) {
    return widgets.where((w) => w.id != excludeId).toList();
  }
}
