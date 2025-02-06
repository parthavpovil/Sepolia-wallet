import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wallet_service.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:math';

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
        // Convert ETH amount to Wei
        final ethAmount = double.parse(_amountController.text);
        final weiAmount = BigInt.from(ethAmount * pow(10, 18));

        final txHash = await _walletService.sendTransaction(
          toAddress: _addressController.text,
          amount: weiAmount,
          privateKey: widget.privateKey,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction sent! Hash: $txHash'),
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _error = 'Error: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
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
                  hintText: '0x...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  if (!value.startsWith('0x') || value.length != 42) {
                    return 'Please enter a valid Ethereum address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (ETH)',
                  hintText: '0.01',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendTransaction,
                child: _isLoading
                    ? const CircularProgressIndicator()
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
