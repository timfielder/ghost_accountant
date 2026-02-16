import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'logic/transaction_provider.dart';
import 'data/repositories/entity_repository.dart';
import 'ui/screens/triage_screen.dart';
import 'ui/widgets/triage_bottom_sheet.dart';

// 1. Initialize Notification Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Global Navigator Key to allow navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Setup Notifications (UPDATED FOR FOREGROUND VISIBILITY)
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

  // FIX: Explicitly allow banners/alerts while app is open
  const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    defaultPresentAlert: true,   // Show alert while app is open
    defaultPresentBanner: true,  // Show banner while app is open
    defaultPresentSound: true,   // Play sound while app is open
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // 3. HANDLE THE TAP
      if (response.payload != null) {
        final txId = response.payload!;
        print("🔔 NOTIFICATION TAPPED: $txId");

        // Slight delay to ensure UI is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          final context = navigatorKey.currentContext;
          if (context != null) {
            final provider = Provider.of<TransactionProvider>(context, listen: false);
            try {
              final tx = provider.queue.firstWhere((t) => t['transaction_id'] == txId);

              // Open the Triage Sheet
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => TriageBottomSheet(
                    transaction: tx,
                    onComplete: (success) {},
                  )
              );
            } catch (e) {
              print("Error finding transaction from notification: $e");
            }
          }
        });
      }
    },
  );

  final entityRepo = EntityRepository();
  await entityRepo.createDefaultEntities('user_01');

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
    return MaterialApp(
      title: 'Ghost Accountant',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        useMaterial3: true,
      ),
      home: const TriageScreen(),
    );
  }
}