import 'dart:convert';
import 'package:http/http.dart' as http;

class FundNavHistory {
  final DateTime date;
  final double nav;
  final double? accumulatedNav;

  FundNavHistory({
    required this.date,
    required this.nav,
    this.accumulatedNav,
  });

  factory FundNavHistory.fromMap(Map<String, dynamic> map) {
    return FundNavHistory(
      date: DateTime.parse(map['date'] as String),
      nav: (map['nav'] as num).toDouble(),
      accumulatedNav: map['accumulated_nav'] != null
          ? (map['accumulated_nav'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'nav': nav,
      'accumulated_nav': accumulatedNav,
    };
  }
}

class FundHistoryApiService {
  static const String _baseUrl = 'http://fund.eastmoney.com/f10/F10DataApi.aspx';

  Future<List<FundNavHistory>> fetchNavHistory(
    String fundCode, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 365));
      final end = endDate ?? now;

      final startDateStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final endDateStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'type': 'lsjz',
        'code': fundCode,
        'page': '1',
        'sdate': startDateStr,
        'edate': endDateStr,
        'per': '365',
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Referer': 'http://fund.eastmoney.com/',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        return _parseHistoryData(body);
      } else {
        throw Exception('API request failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('获取基金历史净值失败: $e');
      return [];
    }
  }

  List<FundNavHistory> _parseHistoryData(String body) {
    final historyList = <FundNavHistory>[];

    try {
      final contentMatch = RegExp(r'content:"([^"]*)"').firstMatch(body);
      if (contentMatch == null) return [];

      final content = contentMatch.group(1)!;
      final rows = RegExp(r'<td>([^<]*)</td>').allMatches(content);

      final rowData = <String>[];
      for (final match in rows) {
        rowData.add(match.group(1)!);
      }

      for (int i = 0; i < rowData.length; i += 7) {
        if (i + 6 >= rowData.length) break;

        final dateStr = rowData[i];
        final navStr = rowData[i + 1];
        final accumulatedNavStr = rowData[i + 2];

        final date = DateTime.tryParse(dateStr);
        final nav = double.tryParse(navStr);
        final accumulatedNav = double.tryParse(accumulatedNavStr);

        if (date != null && nav != null) {
          historyList.add(FundNavHistory(
            date: date,
            nav: nav,
            accumulatedNav: accumulatedNav,
          ));
        }
      }

      historyList.sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      print('解析历史净值数据失败: $e');
    }

    return historyList;
  }
}
