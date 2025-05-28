import 'package:go_router/go_router.dart';
import '../features/cloud_download/views/cloud_download_screen.dart';
import '../features/learn_download/views/learn_download_screen.dart';
import '../features/settings/views/settings_screen.dart';
import 'app.dart';

final router = GoRouter(
  initialLocation: '/cloud-download',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(
          path: '/cloud-download',
          builder: (context, state) => const CloudDownloadScreen(),
        ),
        GoRoute(
          path: '/learn-download',
          builder: (context, state) => const LearnDownloadScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
); 