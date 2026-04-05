import 'dart:convert';
import 'package:crypto/crypto.dart';

class PinUtils {
  PinUtils._();

  /// Hash a PIN using SHA-256
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify a PIN against a hash
  static bool verifyPin(String pin, String pinHash) {
    return hashPin(pin) == pinHash;
  }

  /// Validate PIN format (4-6 digits)
  static bool isValidPin(String pin) {
    return RegExp(r'^\d{4,6}$').hasMatch(pin);
  }
}
