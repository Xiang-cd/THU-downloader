import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';

class THUDownloaderApp extends ConsumerWidget {
  const THUDownloaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'THU Downloader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

class MainScreen extends StatefulWidget {
  final Widget child;
  
  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0:
        context.go('/cloud-download');
        break;
      case 1:
        context.go('/learn-download');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 根据当前路由更新选中的索引
    final location = GoRouterState.of(context).uri.path;
    switch (location) {
      case '/cloud-download':
        _selectedIndex = 0;
        break;
      case '/learn-download':
        _selectedIndex = 1;
        break;
      case '/settings':
        _selectedIndex = 2;
        break;
      default:
        _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.cloud_download),
                label: Text('云盘下载'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.school),
                label: Text('网络学堂下载'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('设置'),
              ),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content area
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
} 