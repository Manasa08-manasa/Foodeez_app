import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

import '../constants/env.dart';

/// Matches restaurant-admin `lib/crypto.ts` encryptPassword().
class CryptoUtils {
  static final _rng = Random.secure();

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  static Uint8List _randomBytes(int n) =>
      Uint8List.fromList(List<int>.generate(n, (_) => _rng.nextInt(256)));

  static String encryptPassword(String password) {
    try {
      final keyBytes = _hexToBytes(Env.passwordEncryptionKeyHex);
      final ivBytes = _randomBytes(16);
      final key = enc.Key(keyBytes);
      final iv = enc.IV(ivBytes);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'));
      final encrypted = encrypter.encrypt(password, iv: iv);
      return '${base64.encode(ivBytes)}:${encrypted.base64}';
    } catch (_) {
      return password;
    }
  }
}
