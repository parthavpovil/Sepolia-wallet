import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/wallet_service.dart';
import 'package:web3dart/web3dart.dart';
import 'screens/send_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sepolia Wallet',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: const Color(0xFF14213D),
          onPrimary: Colors.white,
          secondary: const Color(0xFFFCA311),
          onSecondary: const Color(0xFF14213D),
          error: Colors.red,
          onError: Colors.white,
          background: const Color(0xFFE5E5E5),
          onBackground: const Color(0xFF14213D),
          surface: Colors.white,
          onSurface: const Color(0xFF14213D),
        ),
        scaffoldBackgroundColor: const Color(0xFFE5E5E5),
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF14213D)),
          bodyMedium: TextStyle(color: Color(0xFF14213D)),
          titleLarge: TextStyle(color: Color(0xFF14213D)),
          titleMedium: TextStyle(color: Color(0xFF14213D)),
        ),
        useMaterial3: true,
      ),
      home: const WalletScreen(),
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  String? _mnemonic;
  String? _address;
  String? _privateKey;
  EtherAmount? _balance;
  bool _isLoading = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    setState(() => _isLoading = true);
    try {
      await _walletService.init();
      final savedAddress = _walletService.getSavedAddress();
      if (savedAddress != null) {
        setState(() {
          _address = savedAddress;
          _privateKey = _walletService.getSavedPrivateKey();
        });
        await _refreshBalance();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                address: _address!,
                privateKey: _privateKey!,
              ),
            ),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createWallet() async {
    setState(() => _isLoading = true);
    try {
      final wallet = await _walletService.createWallet();
      setState(() {
        _mnemonic = wallet['mnemonic'];
        _address = wallet['address'];
        _privateKey = wallet['privateKey'];
      });
      await _refreshBalance();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              address: _address!,
              privateKey: _privateKey!,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshBalance() async {
    if (_address != null) {
      final balance = await _walletService.getBalance(_address!);
      setState(() => _balance = balance);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Sepolia Wallet'),
        actions: [
          if (_address != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshBalance,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_address == null)
                    ElevatedButton(
                      onPressed: _createWallet,
                      child: const Text('Create New Wallet'),
                    )
                  else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Wallet Address:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _address!,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    if (_address != null) {
                                      Clipboard.setData(
                                          ClipboardData(text: _address!));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Address copied to clipboard')));
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Balance: ${_balance?.getValueInUnit(EtherUnit.ether)} ETH',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF14213D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_mnemonic != null) ...[
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Seed Phrase (Keep this safe!):',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                              const SizedBox(height: 8),
                              Text(_mnemonic!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
