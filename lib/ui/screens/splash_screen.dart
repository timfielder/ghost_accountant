import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/transaction_provider.dart';
import 'onboarding_screen.dart'; // NEW IMPORT
import 'home_wrapper.dart';      // NEW IMPORT

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _logoOpacity;

  // Tagline Animations
  late Animation<double> _tagline1Opacity;
  late Animation<double> _tagline2Opacity;
  late Animation<double> _tagline3Opacity;

  @override
  void initState() {
    super.initState();

    // 1. Setup the Master Timeline (3 Seconds Total)
    _mainController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3)
    );

    // 2. Define the Sequence (Intervals 0.0 to 1.0)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn))
    );

    _tagline1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainController, curve: const Interval(0.5, 0.65, curve: Curves.easeOut))
    );

    _tagline2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainController, curve: const Interval(0.65, 0.8, curve: Curves.easeOut))
    );

    _tagline3Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainController, curve: const Interval(0.8, 0.95, curve: Curves.easeOut))
    );

    _mainController.forward();

    // 3. Load Data & Decide Destination
    _initApp();
  }

  Future<void> _initApp() async {
    final provider = context.read<TransactionProvider>();

    // Load Data to check if entities exist
    await provider.loadInitialData('user_01');

    // Ensure animation finishes (3s) + slight buffer
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      // THE TRAFFIC COP LOGIC
      Widget nextScreen;

      if (provider.entities.isEmpty) {
        // No Data? -> Setup Mode
        nextScreen = const OnboardingScreen();
      } else {
        // Has Data? -> Dashboard Mode
        nextScreen = const HomeWrapper();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 800),
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
    const taglineStyle = TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white,
        fontSize: 12,
        letterSpacing: 1.2,
        height: 1.5
    );

    const highlightStyle = TextStyle(
      fontFamily: 'Roboto',
      color: Color(0xFF355E3B), // Hunter Green
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: 1.2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoOpacity,
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', width: 120, height: 120),
                  const SizedBox(height: 20),
                  const Text(
                    "B E A M S",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 12.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _tagline1Opacity,
                  child: const Text("One Business.  ", style: taglineStyle),
                ),
                FadeTransition(
                  opacity: _tagline2Opacity,
                  child: const Text("Multiple Streams.  ", style: taglineStyle),
                ),
                FadeTransition(
                  opacity: _tagline3Opacity,
                  child: const Text("One Tool.", style: highlightStyle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}