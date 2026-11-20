import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_sign_in_web_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_web_button.dart'
    as web_sign_in;

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initialization;
  static GoogleSignInAccount? _webAccount;
  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '974325334309-ppo2mv7utvbq33ivc238r2pu4ac961ds.apps.googleusercontent.com',
  );

  static Future<GoogleSignInAccount?> signInToOpenBook(
    BuildContext context,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    _initialization ??= _googleSignIn.initialize(
      clientId: kIsWeb ? _webClientId : null,
      serverClientId: kIsWeb ? null : _webClientId,
    );
    await _initialization;

    if (!navigator.mounted) return null;
    if (kIsWeb) {
      _webAccount ??= await _signInOnWeb(navigator);
      return _webAccount;
    }

    final existingAccount = await _googleSignIn
        .attemptLightweightAuthentication();
    if (existingAccount != null) return existingAccount;

    try {
      return await _googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  static Future<GoogleSignInAccount?> _signInOnWeb(
    NavigatorState navigator,
  ) async {
    var dialogOpen = true;
    final subscription = _googleSignIn.authenticationEvents.listen(
      (event) {
        if (dialogOpen && event is GoogleSignInAuthenticationEventSignIn) {
          dialogOpen = false;
          navigator.pop(_WebSignInSuccess(event.user));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (dialogOpen) {
          dialogOpen = false;
          navigator.pop(_WebSignInFailure(error, stackTrace));
        }
      },
    );

    try {
      final result = await showDialog<_WebSignInResult>(
        context: navigator.context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Inicia sesión con Google'),
          content: SizedBox(
            width: 280,
            height: 48,
            child: web_sign_in.renderButton(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );

      if (result == null) return null;
      if (result is _WebSignInSuccess) return result.account;
      final failure = result as _WebSignInFailure;
      Error.throwWithStackTrace(failure.error, failure.stackTrace);
    } finally {
      dialogOpen = false;
      await subscription.cancel();
    }
  }
}

sealed class _WebSignInResult {}

class _WebSignInSuccess extends _WebSignInResult {
  _WebSignInSuccess(this.account);

  final GoogleSignInAccount account;
}

class _WebSignInFailure extends _WebSignInResult {
  _WebSignInFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}
