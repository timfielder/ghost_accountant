import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // NEW IMPORT
import '../../logic/transaction_provider.dart';
import 'home_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Streams
  final _primaryController = TextEditingController();
  final List<TextEditingController> _streamControllers = [TextEditingController()];

  // Accounts & Balances
  final List<TextEditingController> _accountControllers = [TextEditingController()];
  final List<TextEditingController> _balanceControllers = [TextEditingController()];

  void _addStreamField() => setState(() => _streamControllers.add(TextEditingController()));

  void _addAccountField() {
    setState(() {
      _accountControllers.add(TextEditingController());
      _balanceControllers.add(TextEditingController());
    });
  }

  Future<void> _completeSetup() async {
    if (_primaryController.text.isEmpty) return;

    final provider = context.read<TransactionProvider>();

    // 1. REQUEST PERMISSIONS (Moved here from the Debug Button)
    final plugin = FlutterLocalNotificationsPlugin();
    final androidImplementation = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // 2. Clear & Rebuild DB
    await provider.resetDatabase();

    // 3. Create Streams (Entities)
    await provider.addEntity(_primaryController.text, isPrimary: true);
    for (var c in _streamControllers) {
      if (c.text.isNotEmpty) await provider.addEntity(c.text, isPrimary: false);
    }

    // 4. Create Accounts with Balances
    for (var i = 0; i < _accountControllers.length; i++) {
      if (_accountControllers[i].text.isNotEmpty) {
        final balanceText = _balanceControllers[i].text;
        final balance = double.tryParse(balanceText.replaceAll(r'$', '').replaceAll(',', '')) ?? 0.0;
        await provider.addAccount(_accountControllers[i].text, balance);
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeWrapper()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("WELCOME TO BEAMS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2.0, color: Colors.grey)),
              const SizedBox(height: 10),
              const Text("System Setup", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1)),

              const SizedBox(height: 30),

              // SECTION 1: STREAMS
              const Text("1. Business Streams", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              TextField(
                controller: _primaryController,
                decoration: const InputDecoration(hintText: "Primary LLC (e.g. Enterprises)", filled: true, fillColor: Color(0xFFFAFAFA)),
              ),
              const SizedBox(height: 10),
              ...List.generate(_streamControllers.length, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _streamControllers[index],
                  decoration: InputDecoration(
                      hintText: "Stream Name (e.g. Voice Artist)",
                      filled: true, fillColor: const Color(0xFFFAFAFA),
                      suffixIcon: index == _streamControllers.length - 1 ? IconButton(icon: const Icon(Icons.add), onPressed: _addStreamField) : null
                  ),
                ),
              )),

              const SizedBox(height: 30),

              // SECTION 2: ACCOUNTS
              const Text("2. Bank Accounts & Balances", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Text("Physical accounts where money moves.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),

              ...List.generate(_accountControllers.length, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _accountControllers[index],
                        decoration: const InputDecoration(
                            hintText: "Account Name",
                            filled: true, fillColor: Color(0xFFFAFAFA)
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _balanceControllers[index],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                            hintText: "0.00",
                            prefixText: "\$ ",
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            suffixIcon: index == _accountControllers.length - 1
                                ? IconButton(icon: const Icon(Icons.add_circle), onPressed: _addAccountField)
                                : null
                        ),
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeSetup,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF355E3B), padding: const EdgeInsets.all(20)),
                  child: const Text("INITIALIZE SYSTEM", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}