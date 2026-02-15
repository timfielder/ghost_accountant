import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'logic/transaction_provider.dart';
import 'data/repositories/entity_repository.dart';
import 'ui/screens/triage_screen.dart'; // We will build this next

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize DB & Entities [Source 17]
  final entityRepo = EntityRepository();
  // In a real app, userId comes from Auth. For MVP, we use 'user_01'
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
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7), // iOS Light Grey
        useMaterial3: true,
      ),
      home: const TriageScreen(),
    );
  }
}