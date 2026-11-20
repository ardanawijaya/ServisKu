import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/service_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/workshop_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  final notifications = NotificationProvider();
  // Setiap data kendaraan berubah (odometer, servis, dst.), notifikasi disegarkan
  final vehicles =
      VehicleProvider(onDataChanged: () => notifications.load(silent: true));
  final services = ServiceProvider();
  final workshop = WorkshopProvider();
  final router = createRouter(auth);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<VehicleProvider>.value(value: vehicles),
        ChangeNotifierProvider<ServiceProvider>.value(value: services),
        ChangeNotifierProvider<NotificationProvider>.value(value: notifications),
        ChangeNotifierProvider<WorkshopProvider>.value(value: workshop),
      ],
      child: ServisKuApp(router: router),
    ),
  );
}

class ServisKuApp extends StatelessWidget {
  const ServisKuApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ServisKu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
