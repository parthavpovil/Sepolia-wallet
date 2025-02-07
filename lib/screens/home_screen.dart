import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import '../services/wallet_service.dart';
import 'send_screen.dart';
import 'transactions_screen.dart';
import 'import_wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  final String address;
  final String privateKey;

  const HomeScreen({
    super.key,
    required this.address,
    required this.privateKey,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  final _pageController = PageController();
  final _walletService = WalletService();
  EtherAmount? _balance;

  @override
  void initState() {
    super.initState();
    _initWalletService();
    _screens = [
      WalletTab(
        address: widget.address,
        privateKey: widget.privateKey,
        balance: _balance,
        onRefresh: _refreshBalance,
      ),
      SendScreen(address: widget.address, privateKey: widget.privateKey),
      TransactionsScreen(address: widget.address),
    ];
  }

  Future<void> _initWalletService() async {
    await _walletService.init();
    _refreshBalance();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshBalance() async {
    final balance = await _walletService.getBalance(widget.address);
    if (mounted) {
      setState(() {
        _balance = balance;
        _screens[0] = WalletTab(
          address: widget.address,
          privateKey: widget.privateKey,
          balance: _balance,
          onRefresh: _refreshBalance,
        );
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: 'Send',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFFCA311),
        unselectedItemColor: const Color(0xFF14213D),
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}

class WalletTab extends StatefulWidget {
  final String address;
  final String privateKey;
  final EtherAmount? balance;
  final VoidCallback onRefresh;

  const WalletTab({
    super.key,
    required this.address,
    required this.privateKey,
    this.balance,
    required this.onRefresh,
  });

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  final WalletService _walletService = WalletService();
  List<Map<String, String>> _wallets = [];

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    await _walletService.init();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets = await _walletService.getAllWallets();
    if (mounted) {
      setState(() {
        _wallets = wallets;
        // Add current wallet if not in the list
        if (!_wallets.any((w) => w['address'] == widget.address)) {
          _wallets.add({
            'address': widget.address,
            'privateKey': widget.privateKey,
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Sepolia Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              widget.onRefresh();
              _loadWallets();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Always show current wallet info
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                title: const Text(
                  'Current Wallet',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Address: ${widget.address}'),
                    Text(
                      'Balance: ${widget.balance?.getValueInUnit(EtherUnit.ether)} ETH',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Rest of the wallets
            if (_wallets.isNotEmpty) ...[
              const Text(
                'All Wallets:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _wallets.length,
                itemBuilder: (context, index) {
                  final wallet = _wallets[index];
                  final isActive = wallet['address'] == widget.address;

                  if (isActive)
                    return const SizedBox.shrink(); // Skip current wallet

                  return Card(
                    child: ListTile(
                      title: Text('Wallet ${index + 1}'),
                      subtitle: Text('Address: ${wallet['address']}'),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(
                                address: wallet['address']!,
                                privateKey: wallet['privateKey']!,
                              ),
                            ),
                          );
                        },
                        child: const Text('Switch'),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportWalletScreen(),
                  ),
                );
                if (result != null) {
                  _loadWallets();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        address: result['address'],
                        privateKey: result['privateKey'],
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Import Another Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
