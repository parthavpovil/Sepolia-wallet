import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import '../services/wallet_service.dart';
import 'send_screen.dart';
import 'transactions_screen.dart';

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

class WalletTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Sepolia Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                            address,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: address));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Address copied to clipboard'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Balance: ${balance?.getValueInUnit(EtherUnit.ether)} ETH',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14213D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
