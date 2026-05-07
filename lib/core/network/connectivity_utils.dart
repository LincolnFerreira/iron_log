import 'package:connectivity_plus/connectivity_plus.dart';

/// Normalizes [Connectivity.checkConnectivity] / [Connectivity.onConnectivityChanged]
/// across platforms and `connectivity_plus` versions (single result vs list).
bool isConnectivityLikelyOnline(Object? result) {
  if (result is List<ConnectivityResult>) {
    return result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.ethernet) ||
        result.contains(ConnectivityResult.vpn);
  }
  if (result is ConnectivityResult) {
    return result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn;
  }
  return false;
}

Future<bool> hasLikelyInternet(Connectivity connectivity) async {
  try {
    final result = await connectivity.checkConnectivity();
    return isConnectivityLikelyOnline(result);
  } catch (_) {
    return false;
  }
}
