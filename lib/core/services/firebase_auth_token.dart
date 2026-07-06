import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Auth errors that should not crash the app when the user is
/// already persisted locally (e.g. airplane mode).
bool isFirebaseAuthNetworkFailure(FirebaseAuthException e) {
  switch (e.code) {
    case 'network-request-failed':
    case 'network_error':
      return true;
    default:
      return false;
  }
}

/// Prefer cached token; on network failure returns `null` instead of throwing.
///
/// Never pass [forceRefresh] `true` from global listeners — it always hits the network.
Future<String?> safeGetIdToken(User user, {bool forceRefresh = false}) async {
  try {
    return await user.getIdToken(forceRefresh);
  } on FirebaseAuthException catch (e) {
    if (!isFirebaseAuthNetworkFailure(e)) rethrow;
    if (forceRefresh) {
      try {
        return await user.getIdToken(false);
      } on FirebaseAuthException catch (e2) {
        if (!isFirebaseAuthNetworkFailure(e2)) rethrow;
      }
    }
    return null;
  }
}

/// Imprime o ID token completo no console — **somente em debug** (Postman/curl).
Future<void> debugLogIdToken(User user) async {
  if (!kDebugMode) return;

  final token = await safeGetIdToken(user);
  if (token == null) {
    debugPrint(
      '🔑 [debug] Firebase ID token indisponível (offline/cache vazio)',
    );
    return;
  }

  if (kDebugMode) {
    log('🔑 [debug] Firebase ID token (cole no Postman → Bearer):\n$token');
  }
}
