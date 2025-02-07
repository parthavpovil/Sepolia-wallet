import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  static const String rpcUrl =
      'https://sepolia.infura.io/v3/75e1ccf8e39e4f67b34e691671471204';
  static const String wsUrl =
      'wss://sepolia.infura.io/ws/v3/75e1ccf8e39e4f67b34e691671471204';

  late Web3Client _web3client;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final client = Client();
    _web3client = Web3Client(rpcUrl, client);
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  Future<void> clearOldWalletData() async {
    await _prefs.remove('private_key');
    await _prefs.remove('address');
  }

  Future<Map<String, String>> createWallet() async {
    // Clear old wallet data first
    await clearOldWalletData();

    final mnemonic = bip39.generateMnemonic();
    final seed = bip39.mnemonicToSeed(mnemonic);
    final privateKey = HEX.encode(seed.sublist(0, 32));
    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = credentials.address.hex;

    await _prefs.setString('private_key', privateKey);
    await _prefs.setString('address', address);

    await addWallet(address, privateKey);

    return {
      'mnemonic': mnemonic,
      'privateKey': privateKey,
      'address': address,
    };
  }

  Future<EtherAmount> getBalance(String address) async {
    final ethAddress = EthereumAddress.fromHex(address);
    return await _web3client.getBalance(ethAddress);
  }

  Future<String> sendTransaction({
    required String toAddress,
    required BigInt amount,
    required String privateKey,
  }) async {
    try {
      // Print debug info to verify the correct account
      print('Sending from private key: $privateKey');

      final credentials = EthPrivateKey.fromHex(privateKey);
      final fromAddress = credentials.address;

      print('Sending from address: ${fromAddress.hex}');

      final gasPrice = await _web3client.getGasPrice();
      final nonce = await _web3client.getTransactionCount(fromAddress);

      // Estimate gas
      final gasLimit = await _web3client.estimateGas(
        sender: fromAddress,
        to: EthereumAddress.fromHex(toAddress),
        value: EtherAmount.fromBigInt(EtherUnit.wei, amount),
      );

      final transaction = Transaction(
        to: EthereumAddress.fromHex(toAddress),
        value: EtherAmount.fromBigInt(EtherUnit.wei, amount),
        maxGas: gasLimit.toInt(),
        gasPrice: gasPrice,
        nonce: nonce,
      );

      final txHash = await _web3client.sendTransaction(
        credentials,
        transaction,
        chainId: 11155111,
      );

      // Verify transaction was sent from correct address
      print('Transaction sent with hash: $txHash');
      return txHash;
    } catch (e) {
      print('Error sending transaction: $e');
      rethrow;
    }
  }

  String? getSavedPrivateKey() {
    return _prefs.getString('private_key');
  }

  String? getSavedAddress() {
    return _prefs.getString('address');
  }

  Future<Map<String, String>> importWallet(String mnemonic) async {
    // Clear old wallet data first
    await clearOldWalletData();

    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic');
    }

    final seed = bip39.mnemonicToSeed(mnemonic);
    final privateKey = HEX.encode(seed.sublist(0, 32));
    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = credentials.address.hex;

    await _prefs.setString('private_key', privateKey);
    await _prefs.setString('address', address);

    await addWallet(address, privateKey);

    return {
      'privateKey': privateKey,
      'address': address,
    };
  }

  Future<void> dispose() async {
    await _web3client.dispose();
  }

  Future<List<Map<String, String>>> getAllWallets() async {
    final List<String> walletKeys = _prefs.getStringList('wallet_list') ?? [];
    List<Map<String, String>> wallets = [];

    for (String key in walletKeys) {
      final address = _prefs.getString('address_$key');
      final privateKey = _prefs.getString('private_key_$key');
      if (address != null && privateKey != null) {
        wallets.add({
          'address': address,
          'privateKey': privateKey,
        });
      }
    }
    return wallets;
  }

  Future<void> addWallet(String address, String privateKey) async {
    final List<String> walletKeys = _prefs.getStringList('wallet_list') ?? [];
    final String walletKey = DateTime.now().millisecondsSinceEpoch.toString();

    await _prefs.setString('address_$walletKey', address);
    await _prefs.setString('private_key_$walletKey', privateKey);

    walletKeys.add(walletKey);
    await _prefs.setStringList('wallet_list', walletKeys);
  }
}
