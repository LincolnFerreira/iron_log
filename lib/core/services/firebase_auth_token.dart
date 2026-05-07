import 'package:firebase_auth/firebase_auth.dart';

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
Future<String?> safeGetIdToken(
  User user, {
  bool forceRefresh = false,
}) async {
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
