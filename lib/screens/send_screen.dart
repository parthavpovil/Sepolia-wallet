import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wallet_service.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'receive_screen.dart';

class SendScreen extends StatefulWidget {
  final String address;
  final String privateKey;

  const SendScreen({
    super.key,
    required this.address,
    required this.privateKey,
  });

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
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

  Future<void> _sendTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        // Debug prints
        print('Current wallet address: ${widget.address}');
        print('Using private key: ${widget.privateKey}');

        // Convert ETH amount to Wei
        final ethAmount = double.parse(_amountController.text);
        final weiAmount = BigInt.from(ethAmount * pow(10, 18));

        // Print debug information
        print('Sending transaction:');
        print('To: ${_addressController.text}');
        print('Amount (ETH): $ethAmount');
        print('Amount (Wei): $weiAmount');
        print('Private Key: ${widget.privateKey}');

        final txHash = await _walletService.sendTransaction(
          toAddress: _addressController.text,
          amount: weiAmount,
          privateKey: widget.privateKey,
        );

        print('Transaction hash: $txHash');

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction sent! Hash: $txHash'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  final url = 'https://sepolia.etherscan.io/tx/$txHash';
                  launchUrl(Uri.parse(url));
                },
              ),
            ),
          );

          // Clear form
          _addressController.clear();
          _amountController.clear();

          // Don't pop the screen, let user see the result
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Transaction error: $e');
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send ETH'),
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
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Address',
                  hintText: 'Enter ETH address',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter recipient address';
                  }
                  if (!value.startsWith('0x') || value.length != 42) {
                    return 'Invalid ETH address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (ETH)',
                  hintText: 'Enter amount to send',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendTransaction,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
