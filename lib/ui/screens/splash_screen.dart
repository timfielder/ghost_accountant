import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/transaction_provider.dart';
import 'onboarding_screen.dart';
import 'home_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _logoOpacity;
  late Animation<double> _tagline1Opacity;
  late Animation<double> _tagline2Opacity;
  late Animation<double> _tagline3Opacity;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4)
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn))
    );

    _tagline1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.6, curve: Curves.easeOut))
    );

    _tagline2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainController, curve: const Interval(0.6, 0.8, curve: Curves.easeOut))
    );

    _tagline3Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainController, curve: const Interval(0.8, 1.0, curve: Curves.easeOut))
    );

    _mainController.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    final provider = context.read<TransactionProvider>();
    await provider.loadInitialData('user_01');

    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      Widget nextScreen;
      if (provider.entities.isEmpty) {
        nextScreen = const OnboardingScreen();
      } else {
        nextScreen = const HomeWrapper();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sjNavy = Color(0xFF00264C);
    const sjTeal = Color(0xFF4A7D8F);
    const sjGold = Color(0xFFE0B42D);

    const baseStyle = TextStyle(
        fontFamily: 'Roboto',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        height: 1.5
    );

    return Scaffold(
      // CHANGED: Pure white to blend with your logo background
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoOpacity,
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', width: 140, height: 140),
                  const SizedBox(height: 20),
                  const Text(
                    "B E A M S",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: sjNavy,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 12.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _tagline1Opacity,
                  child: Text("One Business.", style: baseStyle.copyWith(color: sjNavy)),
                ),
                FadeTransition(
                  opacity: _tagline2Opacity,
                  child: Text("Multiple Streams.", style: baseStyle.copyWith(color: sjTeal)),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _tagline3Opacity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: sjNavy,
                        borderRadius: BorderRadius.circular(4)
                    ),
                    child: Text(
                        "One Tool.",
                        style: baseStyle.copyWith(color: sjGold)
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}