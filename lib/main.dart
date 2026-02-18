import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'logic/transaction_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/widgets/triage_bottom_sheet.dart';

// GLOBAL KEYS & PLUGINS
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// THIS IS THE MISSING MAIN FUNCTION
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. NOTIFICATION SETUP
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin
  );

  await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (resp) async {
        if (resp.payload != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            final context = navigatorKey.currentContext;
            if (context != null) {
              final provider = Provider.of<TransactionProvider>(context, listen: false);
              try {
                final tx = provider.queue.firstWhere((t) => t['transaction_id'] == resp.payload!);
                showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => TriageBottomSheet(transaction: tx, onComplete: (s){})
                );
              } catch (e) {
                // Transaction not found
              }
            }
          });
        }
      }
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()..loadInitialData('user_01')),
      ],
      child: const GhostAccountantApp(),
    ),
  );
}

class GhostAccountantApp extends StatelessWidget {
  const GhostAccountantApp({super.key});

  @override
  Widget build(BuildContext context) {
    // BEAMS PALETTE
    const tfeGreen = Color(0xFF355E3B); // Hunter Green
    const tfeBlack = Color(0xFF121212); // Ink Black (Void)
    const tfePaper = Color(0xFFFAFAFA); // Crisp White Paper

    return MaterialApp(
      title: 'BEAMS',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: tfePaper,

        // Color Scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: tfeGreen,
          primary: tfeGreen,
          onPrimary: Colors.white,
          secondary: tfeBlack,
          surface: Colors.white,
        ),

        // Typography
        textTheme: TextTheme(
          displayLarge: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: tfeBlack),
          titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: tfeBlack),
          bodyLarge: GoogleFonts.roboto(fontSize: 16, color: tfeBlack),
          bodyMedium: GoogleFonts.roboto(fontSize: 14, color: tfeBlack),
        ),

        // Component Styles - HIGH CONTRAST HEADER
        appBarTheme: AppBarTheme(
          backgroundColor: tfeBlack, // Ink Black Header
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: tfeGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            )
        ),
      ),
      home: const SplashScreen(),
    );
  }
}