import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uses the package's single instance API.
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  /// Performs native Google Sign-In on mobile:
  /// 1. Optionally clears previous GoogleSignIn session
  /// 2. Launches account selector (interactive authenticate)
  /// 3. Exchanges tokens for Firebase credential
  /// 4. Signs in with `signInWithCredential`
  /// If [serverClientId] is provided it will be used to initialize the
  /// underlying `GoogleSignIn` instance (required on Android when requesting
  /// ID tokens). If null, the method will throw on Android with a helpful
  /// message explaining how to obtain and provide the value.
  Future<UserCredential?> signInWithGoogle({
    bool clearSession = true,
    String? serverClientId,
  }) async {
    try {
      // Web: use Firebase Auth popup flow to avoid google_sign_in web quirks
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await FirebaseAuth.instance.signInWithPopup(provider);
      }

      if (clearSession) {
        await _googleSignIn.signOut();
      }

      // On Android, the plugin requires either initialization with a
      // serverClientId (web client id) or the value present in the
      // configuration. If we don't have it, surface a clear error.
      final isAndroid =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      if (isAndroid && (serverClientId == null)) {
        throw Exception(
          'Google Sign-In on Android requires a serverClientId (the Web OAuth\n'
          'Client ID). Obtain it from Google Cloud Console (OAuth 2.0 Client IDs)\n'
          'or Firebase Project Settings -> OAuth 2.0 Client IDs, then pass it to\n'
          '`GoogleAuthService.signInWithGoogle(serverClientId: "YOUR_WEB_CLIENT_ID")`\n'
          'or call `GoogleSignIn.instance.initialize(serverClientId: ...)` at app startup.',
        );
      }

      if (serverClientId != null) {
        await _googleSignIn.initialize(serverClientId: serverClientId);
      }

      // `authenticate` is the interactive sign-in method in newer versions
      final googleUser = await _googleSignIn.authenticate();

      // Per package docs, `GoogleSignInAccount.authentication` returns
      // a `GoogleSignInAuthentication` object that currently only contains
      // an `idToken` (no accessToken). Do not `await` it.
      final googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('Google idToken is null');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }

    await _auth.signOut();
  }
}
