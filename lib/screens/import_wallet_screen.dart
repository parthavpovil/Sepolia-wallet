import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mnemonicController = TextEditingController();
  final _walletService = WalletService();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWalletService();
  }

  Future<void> _initWalletService() async {
    await _walletService.init();
  }

  Future<void> _importWallet() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final wallet =
            await _walletService.importWallet(_mnemonicController.text);
        if (mounted) {
          Navigator.pop(context, wallet);
        }
      } catch (e) {
        setState(() => _error = 'Invalid seed phrase');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Wallet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _mnemonicController,
                decoration: const InputDecoration(
                  labelText: 'Enter Seed Phrase',
                  hintText: 'Enter your 12-word seed phrase',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your seed phrase';
                  }
                  final words = value.trim().split(' ');
                  if (words.length != 12) {
                    return 'Please enter all 12 words';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _importWallet,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Import Wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
