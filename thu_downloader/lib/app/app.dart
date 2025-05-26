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

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

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
            selectedIndex: 0,
            onDestinationSelected: (int index) {
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
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content area
          Expanded(
            child: Center(
              child: Text('Select a feature from the navigation rail'),
            ),
          ),
        ],
      ),
    );
  }
} 