import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/wallet_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class Transaction {
  final String hash;
  final String from;
  final String to;
  final String value;
  final DateTime timestamp;
  final bool isIncoming;

  Transaction({
    required this.hash,
    required this.from,
    required this.to,
    required this.value,
    required this.timestamp,
    required this.isIncoming,
  });
}

class TransactionsScreen extends StatefulWidget {
  final String address;

  const TransactionsScreen({
    super.key,
    required this.address,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await http.get(Uri.parse('https://api-sepolia.etherscan.io/api'
              '?module=account'
              '&action=txlist'
              '&address=${widget.address}'
              '&startblock=0'
              '&endblock=99999999'
              '&sort=desc'
              '&apikey=WBH4ID73JK2BTSS55IEHRIIBGWVPJKVT1E'));

      final data = json.decode(response.body);
      if (data['status'] == '1') {
        final List<Transaction> transactions = [];
        for (var tx in data['result']) {
          final value = BigInt.parse(tx['value']);
          final valueInEth = value / BigInt.from(10).pow(18);

          transactions.add(Transaction(
            hash: tx['hash'],
            from: tx['from'],
            to: tx['to'],
            value: valueInEth.toStringAsFixed(6),
            timestamp: DateTime.fromMillisecondsSinceEpoch(
                int.parse(tx['timeStamp']) * 1000),
            isIncoming: tx['to'].toLowerCase() == widget.address.toLowerCase(),
          ));
        }
        setState(() => _transactions = transactions);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching transactions: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openTransactionInExplorer(String hash) async {
    final url = 'https://sepolia.etherscan.io/tx/$hash';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('No transactions found'))
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          tx.isIncoming
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: tx.isIncoming ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          '${tx.isIncoming ? 'Received' : 'Sent'} ${tx.value} ETH',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From: ${tx.from.substring(0, 6)}...${tx.from.substring(tx.from.length - 4)}',
                            ),
                            Text(
                              'To: ${tx.to.substring(0, 6)}...${tx.to.substring(tx.to.length - 4)}',
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy HH:mm')
                                  .format(tx.timestamp),
                            ),
                          ],
                        ),
                        onTap: () => _openTransactionInExplorer(tx.hash),
                      ),
                    );
                  },
                ),
    );
  }
}
