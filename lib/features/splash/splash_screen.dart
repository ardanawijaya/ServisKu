import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    // Logo tampil minimal 3 detik, sambil mengecek sesi login
    await Future.wait([
      auth.init(),
      Future.delayed(const Duration(seconds: 3)),
    ]);
    if (!mounted) return;
    context.go(auth.isLoggedIn ? homePathFor(auth.user!.role) : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.scale(scale: 0.85 + 0.15 * v, child: child),
          ),
          child: Image.asset(AppAssets.logoOnboarding, width: 170),
        ),
      ),
    );
  }
}
