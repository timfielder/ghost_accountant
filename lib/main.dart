import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'logic/transaction_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/widgets/triage_bottom_sheet.dart';
import 'ui/widgets/smart_triage_sheet.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
                    builder: (ctx) => SmartTriageSheet(transaction: tx)
                );
              } catch (e) {
                print("Transaction not found in queue: $e");
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
    // BRAND PALETTE: Success Journeys Hub
    const sjNavy   = Color(0xFF00264C); // Primary Background / Headers
    const sjGold   = Color(0xFFE0B42D); // Highlights / Value
    const sjTeal   = Color(0xFF4A7D8F); // Primary Action
    const sjBlue   = Color(0xFF99CCFF); // Secondary Accents
    const sjSilver = Color(0xFFCFCFCF); // Backgrounds / Cards

    return MaterialApp(
      title: 'BEAMS',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Very light grey for contrast against Navy

        // Color Scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: sjNavy,
          primary: sjTeal,
          onPrimary: Colors.white,
          secondary: sjNavy,
          surface: Colors.white,
          tertiary: sjGold,
          error: const Color(0xFFB00020),
        ),

        // Typography
        textTheme: TextTheme(
          displayLarge: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: sjNavy),
          titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: sjNavy),
          bodyLarge: GoogleFonts.roboto(fontSize: 16, color: sjNavy),
          bodyMedium: GoogleFonts.roboto(fontSize: 14, color: sjNavy),
        ),

        // Component Styles
        appBarTheme: AppBarTheme(
          backgroundColor: sjNavy,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: sjTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            )
        ),
      ),
      home: const SplashScreen(),
    );
  }
}