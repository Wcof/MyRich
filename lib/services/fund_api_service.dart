import 'dart:convert';
import 'package:http/http.dart' as http;

class FundQuoteResult {
  final String fundCode;
  final String fundName;
  final double nav;
  final DateTime asOf;
  final String source;

  FundQuoteResult({
    required this.fundCode,
    required this.fundName,
    required this.nav,
    required this.asOf,
    required this.source,
  });
}

class FundApiService {
  static const String _source = 'tian Tian Fund';

  Future<FundQuoteResult> fetchQuote(String fundCode) async {
    try {
      final uri = Uri.parse(
        'https://fund.eastmoney.com/f10/F10DataApi.aspx?type=lsjz&code=$fundCode&page=1&per=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseEastMoneyResponse(fundCode, response.body);
      } else {
        throw Exception('API request failed with status ${response.statusCode}');
      }
    } catch (e) {
      return FundQuoteResult(
        fundCode: fundCode,
        fundName: '基金 $fundCode',
        nav: 1.0,
        asOf: DateTime.now(),
        source: _source,
      );
    }
  }

  Future<List<FundQuoteResult>> fetchQuotes(List<String> fundCodes) async {
    final List<FundQuoteResult> results = [];

    for (final code in fundCodes) {
      try {
        final quote = await fetchQuote(code);
        results.add(quote);
      } catch (e) {
        continue;
      }
    }

    return results;
  }

  FundQuoteResult _parseEastMoneyResponse(String fundCode, String body) {
    try {
      final jsonMatch = RegExp(r'var\s+data\s*=\s*(\{.*?\});', dotAll: true).firstMatch(body);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(1);
        if (jsonStr != null) {
          final data = json.decode(jsonStr);
          final records = data['lsjz'] as List?;
          if (records != null && records.isNotEmpty) {
            final record = records.first;
            final navStr = record['dwjz']?.toString();
            final nav = navStr != null ? double.tryParse(navStr) : null;
            final name = record['name']?.toString() ?? '基金 $fundCode';

            return FundQuoteResult(
              fundCode: fundCode,
              fundName: name,
              nav: nav ?? 1.0,
              asOf: DateTime.now(),
              source: _source,
            );
          }
        }
      }
    } catch (_) {
    }

    return FundQuoteResult(
      fundCode: fundCode,
      fundName: '基金 $fundCode',
      nav: 1.0,
      asOf: DateTime.now(),
      source: _source,
    );
  }
}
