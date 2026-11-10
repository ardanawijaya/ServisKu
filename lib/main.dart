import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  final router = createRouter(auth);
  runApp(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
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
