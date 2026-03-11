import 'dart:convert';
import 'package:http/http.dart' as http;

class FundQuoteResult {
  final String fundCode;
  final String fundName;
  final double nav;
  final DateTime navDate;
  final double? estimatedNav;
  final DateTime? estimatedTime;
  final String source;
  final bool isSuccess;

  FundQuoteResult({
    required this.fundCode,
    required this.fundName,
    required this.nav,
    required this.navDate,
    this.estimatedNav,
    this.estimatedTime,
    required this.source,
    this.isSuccess = true,
  });
}

class FundApiService {
  static const String _source = '天天基金';
  static const String _baseUrl = 'http://fundgz.1234567.com.cn/js';

  Future<FundQuoteResult?> fetchQuote(String fundCode) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.parse('$_baseUrl/$fundCode.js?rt=$timestamp');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        return _parseTianTianFundResponse(fundCode, body);
      } else {
        throw Exception('API request failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('获取基金信息失败: $e');
      return null;
    }
  }

  Future<List<FundQuoteResult>> fetchQuotes(List<String> fundCodes) async {
    final List<FundQuoteResult> results = [];

    for (final code in fundCodes) {
      try {
        final quote = await fetchQuote(code);
        if (quote != null) {
          results.add(quote);
        }
      } catch (e) {
        continue;
      }
    }

    return results;
  }

  FundQuoteResult? _parseTianTianFundResponse(String fundCode, String body) {
    try {
      final startIndex = body.indexOf('(');
      final endIndex = body.lastIndexOf(')');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonStr = body.substring(startIndex + 1, endIndex);
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        final fundName = json['name'] as String?;
        final navStr = json['dwjz'] as String?;
        final navDateStr = json['jzrq'] as String?;
        final estimatedNavStr = json['gsz'] as String?;
        final estimatedTimeStr = json['gztime'] as String?;
        
        final nav = navStr != null ? double.tryParse(navStr) : null;
        
        if (fundName != null && nav != null) {
          DateTime navDate = DateTime.now();
          if (navDateStr != null) {
            try {
              navDate = DateTime.parse(navDateStr);
            } catch (e) {
              print('解析净值日期失败: $e');
            }
          }
          
          double? estimatedNav;
          if (estimatedNavStr != null) {
            estimatedNav = double.tryParse(estimatedNavStr);
          }
          
          DateTime? estimatedTime;
          if (estimatedTimeStr != null) {
            try {
              estimatedTime = DateTime.parse(estimatedTimeStr);
            } catch (e) {
              print('解析估值时间失败: $e');
            }
          }
          
          return FundQuoteResult(
            fundCode: fundCode,
            fundName: fundName,
            nav: nav,
            navDate: navDate,
            estimatedNav: estimatedNav,
            estimatedTime: estimatedTime,
            source: _source,
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      print('解析基金数据失败: $e');
    }

    return null;
  }
}
