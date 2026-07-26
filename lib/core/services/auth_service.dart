/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Authenticates with the device lock: fingerprint / face **or** PIN / pattern / password.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final _auth = LocalAuthentication();

  /// Returns:
  /// - `true` if the user unlocked successfully
  /// - `false` if they cancelled / failed
  /// - `null` if the device has no lock set up
  Future<bool?> authenticate({
    String reason = 'Unlock Solace with fingerprint or PIN',
  }) async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return null;

      /// Prefer biometrics when present; always allow device PIN/pattern/password fallback
      final canCheck = await _auth.canCheckBiometrics;
      final biometrics = canCheck ? await _auth.getAvailableBiometrics() : <BiometricType>[];

      debugPrint(
        'AuthService: supported=$isSupported biometrics=$biometrics',
      );

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          /// false → system shows fingerprint/face and "Use PIN" / device credential
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
    } catch (e) {
      debugPrint('AuthService failed: $e');
      return false;
    }
  }

  /// Whether the device can show a lock prompt (biometrics and/or PIN).
  Future<bool> get hasDeviceLock async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }
}
