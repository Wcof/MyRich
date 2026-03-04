import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/asset_type_provider.dart';
import 'providers/asset_provider.dart';
import 'providers/asset_record_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/asset_list_screen.dart';

void main() {
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
        ChangeNotifierProvider(create: (_) => AssetRecordProvider()),
      ],
      child: MaterialApp(
        title: 'MyRich',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainScreen(),
        routes: {
          '/dashboard': (context) => const DashboardScreen(),
          '/assets': (context) => const AssetListScreen(),
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

  final List<Widget> _screens = const [
    DashboardScreen(),
    AssetListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: '看板',
          ),
          NavigationDestination(
            icon: Icon(Icons.list),
            label: '资产',
          ),
        ],
      ),
    );
  }
}
