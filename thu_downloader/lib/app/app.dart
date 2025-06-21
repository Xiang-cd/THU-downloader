import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../gen_l10n/app_localizations.dart';
import 'routes.dart';
import '../features/settings/providers/locale_provider.dart';
import '../core/localization/l10n_helper.dart';

class THUDownloaderApp extends ConsumerWidget {
  const THUDownloaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    
    return MaterialApp.router(
      title: 'THU Downloader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
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
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.cloud_download),
                label: Text(L10nHelper.of(context).navigation.cloudDownload),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.school),
                label: Text(L10nHelper.of(context).navigation.learnDownload),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings),
                label: Text(L10nHelper.of(context).navigation.settings),
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