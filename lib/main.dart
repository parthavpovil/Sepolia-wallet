import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/wallet_service.dart';
import 'package:web3dart/web3dart.dart';

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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
        _address = savedAddress;
        _privateKey = _walletService.getSavedPrivateKey();
        await _refreshBalance();
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
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
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (_mnemonic != null) {
                                  Clipboard.setData(
                                      ClipboardData(text: _mnemonic!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Seed phrase copied to clipboard')));
                                }
                              },
                              child: const Text('Copy Seed Phrase'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
