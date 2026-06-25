import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medisync/core/constants/app_strings.dart';
import 'package:medisync/core/di/injection_container.dart';
import 'package:medisync/core/router/app_router.dart';
import 'package:medisync/core/theme/app_theme.dart';
import 'package:medisync/features/alerts/presentation/viewmodels/alerts_viewmodel.dart';
import 'package:medisync/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:medisync/features/device/presentation/viewmodels/device_viewmodel.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env asset.
  await dotenv.load(fileName: '.env');

  // Wire up the dependency graph.
  await initDependencies();

  // Restore session from secure storage before the first frame.
  await sl<AuthViewModel>().checkAuthStatus();

  sl<AlertsViewModel>().startListening();
  sl<AlertsViewModel>().loadAlerts();

  runApp(const MediSyncApp());
}

class MediSyncApp extends StatelessWidget {
  const MediSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: sl<AuthViewModel>()),
        ChangeNotifierProvider<DeviceViewModel>.value(
            value: sl<DeviceViewModel>()),
        ChangeNotifierProvider<AlertsViewModel>.value(
            value: sl<AlertsViewModel>()),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
