import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/asset_type_provider.dart';
import 'providers/asset_provider.dart';
import 'providers/asset_detail_provider.dart';
import 'providers/asset_record_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/fund_sync_provider.dart';
import 'providers/fund_plan_provider.dart';
import 'providers/loan_provider.dart';
import 'providers/rental_income_provider.dart';
import 'providers/real_estate_price_provider.dart';
import 'services/fund_api_service.dart';
import 'models/asset.dart';
import 'models/asset_type.dart';
import 'screens/dashboard_screen.dart';
import 'screens/asset_list_screen.dart';
import 'screens/asset_detail_screen.dart';
import 'screens/fund_asset_detail_screen.dart';
import 'screens/stock_asset_detail_screen.dart';
import 'screens/real_estate_asset_detail_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssetTypeProvider()),
        ChangeNotifierProvider(create: (_) => AssetProvider()),
        ChangeNotifierProvider(create: (_) => AssetDetailProvider()),
        ChangeNotifierProvider(create: (_) => AssetRecordProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        Provider(create: (_) => FundApiService()),
        ChangeNotifierProvider<FundSyncProvider>(
          create: (context) => FundSyncProvider(
            apiService: context.read<FundApiService>(),
            assetProvider: context.read<AssetProvider>(),
            recordProvider: context.read<AssetRecordProvider>(),
            typeProvider: context.read<AssetTypeProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => FundPlanProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
        ChangeNotifierProvider(create: (_) => RentalIncomeProvider()),
        ChangeNotifierProvider(create: (_) => RealEstatePriceProvider()),
      ],
      child: MaterialApp(
        title: 'MyRich',
        theme: AppTheme.lightTheme,
        home: const MainScreen(),
        routes: {
          '/dashboard': (context) => const DashboardScreen(),
          '/assets': (context) => const AssetListScreen(),
          '/asset_detail': (context) {
            final asset = ModalRoute.of(context)?.settings.arguments as Asset;
            return AssetDetailScreen(asset: asset);
          },
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isMenuExpanded = true;
  Asset? _selectedAsset;
  bool _isShowingAssetDetail = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoUpdateFundAssets();
    });
  }

  Future<void> _autoUpdateFundAssets() async {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 9 && hour < 15) {
      final fundSyncProvider = context.read<FundSyncProvider>();
      final assetProvider = context.read<AssetProvider>();
      final assetTypeProvider = context.read<AssetTypeProvider>();
      
      await assetProvider.loadAssets();
      await assetTypeProvider.loadAssetTypes();
      
      final fundType = assetTypeProvider.assetTypes.firstWhere(
        (type) => type.name == '基金',
        orElse: () => throw Exception('基金类型不存在'),
      );
      
      final fundAssets = assetProvider.assets.where(
        (asset) => asset.typeId == fundType.id,
      ).toList();
      
      if (fundAssets.isNotEmpty) {
        await fundSyncProvider.refreshNow();
      }
    }
  }

  final List<NavigationRailDestination> _destinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('仪表盘'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: Text('资产'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: Text('分析'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('设置'),
    ),
  ];

  void _displayAssetDetail(Asset asset) async {
    final assetTypeProvider = context.read<AssetTypeProvider>();
    await assetTypeProvider.loadAssetTypes();
    
    setState(() {
      _selectedAsset = asset;
      _isShowingAssetDetail = true;
    });
  }

  Widget _getAssetDetailScreen(Asset asset) {
    final assetTypeProvider = context.read<AssetTypeProvider>();
    final assetType = assetTypeProvider.assetTypes.firstWhere(
      (type) => type.id == asset.typeId,
      orElse: () => assetTypeProvider.assetTypes.isNotEmpty 
          ? assetTypeProvider.assetTypes.first 
          : AssetType(
              id: asset.typeId,
              name: '未知类型',
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
    );
    
    if (assetType.name == '基金') {
      return FundAssetDetailScreen(asset: asset, onBack: _hideAssetDetail);
    }
    
    if (assetType.name == '股票') {
      return StockAssetDetailScreen(asset: asset, onBack: _hideAssetDetail);
    }
    
    if (assetType.name == '房产') {
      return RealEstateAssetDetailScreen(asset: asset, onBack: _hideAssetDetail);
    }
    
    return AssetDetailScreen(asset: asset, onBack: _hideAssetDetail);
  }

  void _hideAssetDetail() {
    setState(() {
      _selectedAsset = null;
      _isShowingAssetDetail = false;
    });
  }

  List<Widget> _getScreens() {
    return [
      const DashboardScreen(),
      AssetListScreen(onAssetTap: _displayAssetDetail),
      const PlaceholderScreen(title: '分析'),
      const PlaceholderScreen(title: '设置'),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isShowingAssetDetail = false;
      _selectedAsset = null;
    });
  }

  void _toggleMenuExpanded() {
    setState(() {
      _isMenuExpanded = !_isMenuExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            extended: _isMenuExpanded,
            minExtendedWidth: 180,
            backgroundColor: Colors.white,
            elevation: 1,
            leading: Column(
              children: [
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    if (_isMenuExpanded) ...[
                      const SizedBox(width: AppTheme.spacingS),
                      const Text(
                        'MyRich',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                IconButton(
                  icon: Icon(
                    _isMenuExpanded ? Icons.chevron_left : Icons.chevron_right,
                    color: const Color(0xFF1E293B),
                  ),
                  onPressed: _toggleMenuExpanded,
                  tooltip: _isMenuExpanded ? '折叠菜单' : '展开菜单',
                ),
              ],
            ),
            destinations: _destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _isShowingAssetDetail && _selectedAsset != null
                ? _getAssetDetailScreen(_selectedAsset!)
                : _getScreens()[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                size: 64,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              '${title}功能开发中...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (title) {
      case '分析':
        return Icons.analytics_outlined;
      case '设置':
        return Icons.settings_outlined;
      default:
        return Icons.extension_outlined;
    }
  }
}
