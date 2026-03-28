import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for splash visibility
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    await authProvider.tryAutoLogin();
    
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_soccer,
              size: 100,
              color: Color(0xFF00E676),
            ),
            const SizedBox(height: 24),
            Text(
              'FOOTBALL ECOSYSTEM',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
