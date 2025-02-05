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

  Future<void> init() async {
    final client = Client();
    _web3client = Web3Client(rpcUrl, client);
    _prefs = await SharedPreferences.getInstance();
  }

  Future<Map<String, String>> createWallet() async {
    // Generate a random mnemonic (seed phrase)
    final mnemonic = bip39.generateMnemonic();

    // Generate private key from mnemonic
    final seed = bip39.mnemonicToSeed(mnemonic);
    final privateKey = HEX.encode(seed.sublist(0, 32));

    // Generate Ethereum address from private key
    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = credentials.address.hex;

    // Save private key securely
    await _prefs.setString('private_key', privateKey);
    await _prefs.setString('address', address);

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

  Future<String> sendTransaction(
      {required String toAddress,
      required BigInt amount,
      required String privateKey}) async {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final fromAddress = credentials.address;

    // Get the current nonce for the sender address
    final nonce = await _web3client.getTransactionCount(fromAddress);

    // Get current gas price
    final gasPrice = await _web3client.getGasPrice();

    final transaction = Transaction(
      to: EthereumAddress.fromHex(toAddress),
      value: EtherAmount.fromBigInt(EtherUnit.wei, amount),
      maxGas: 21000, // Standard gas limit for ETH transfers
      gasPrice: gasPrice,
      nonce: nonce,
    );

    // Send the transaction
    final txHash = await _web3client.sendTransaction(
      credentials,
      transaction,
      chainId: 11155111, // Sepolia chain ID
    );

    return txHash;
  }

  String? getSavedPrivateKey() {
    return _prefs.getString('private_key');
  }

  String? getSavedAddress() {
    return _prefs.getString('address');
  }
}
