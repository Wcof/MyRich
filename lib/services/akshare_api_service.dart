import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fund_portfolio.dart';
import '../models/stock_data.dart';

class AkshareApiService {
  final String baseUrl;
  
  AkshareApiService({
    this.baseUrl = 'http://localhost:5000/api',
  });

  Future<FundPortfolio?> getFundPortfolio(String fundCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fund/portfolio/$fundCode'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return FundPortfolio.fromJson(json);
      }
      return null;
    } catch (e) {
      print('获取基金持仓失败: $e');
      return null;
    }
  }

  Future<FundPortfolio?> getETFPortfolio(String fundCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fund/etf/$fundCode'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return FundPortfolio.fromJson(json);
      }
      return null;
    } catch (e) {
      print('获取ETF持仓失败: $e');
      return null;
    }
  }

  Future<StockData?> getStockRealtime(String stockCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stock/realtime/$stockCode'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return StockData.fromJson(json);
      }
      return null;
    } catch (e) {
      print('获取股票实时数据失败: $e');
      return null;
    }
  }

  Future<List<StockKLine>> getStockKLine(
    String stockCode, {
    KLinePeriod period = KLinePeriod.minute1,
    int limit = 100,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stock/kline/$stockCode?period=${period.code}&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json
            .map((e) => StockKLine.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('获取股票K线数据失败: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getFundInfo(String fundCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fund/info/$fundCode'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('获取基金信息失败: $e');
      return null;
    }
  }

  Future<List<StockData>> getBatchStockRealtime(List<String> stockCodes) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stock/realtime/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'codes': stockCodes}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json
            .map((e) => StockData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('批量获取股票实时数据失败: $e');
      return [];
    }
  }
}
