import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneAuthService {
  PhoneAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    int? forceResendingToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required VoidCallback onAutoVerified,
    required void Function(String message) onFailed,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
        verificationCompleted: (credential) async {
          try {
            await _auth.signInWithCredential(credential);
            onAutoVerified();
            await _auth.signOut();
          } catch (error) {
            onFailed(
              'Auto verification failed. Please enter the code manually.',
            );
          }
        },
        verificationFailed: (exception) {
          onFailed(exception.message ?? 'Phone verification failed.');
        },
        codeSent: (verificationId, resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } on FirebaseAuthException catch (error) {
      onFailed(error.message ?? 'Phone verification failed.');
    } catch (_) {
      onFailed('Unable to start verification. Please try again.');
    }
  }

  Future<void> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
    await _auth.signOut();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
