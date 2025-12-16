import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
        await userCredential.user?.reload();
      }

      return AuthResult(
        success: true,
        user: _auth.currentUser,
        message: 'Account created successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Signed in successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return AuthResult(
          success: false,
          message: 'Google sign-in was cancelled',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Signed in with Google successfully',
      );
    } on PlatformException catch (e) {
      // Common cases: sign_in_canceled, sign_in_failed, network_error, ApiException code 10
      final explained = _explainGoogleSignInPlatformException(e);
      if (kDebugMode) {
        debugPrint(
          '[GoogleSignIn][PlatformException] code=${e.code} message=${e.message} details=${e.details}',
        );
        debugPrint('[GoogleSignIn] Explanation: $explained');
      }
      return AuthResult(success: false, message: explained);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  String _explainGoogleSignInPlatformException(PlatformException e) {
    final code =
        e.code; // e.g., sign_in_failed, sign_in_canceled, network_error
    final msg = e.message ?? '';
    final details = (e.details ?? '').toString();

    // Detect ApiException codes embedded in the message/details
    int? apiCode;
    final match = RegExp(r'ApiException:\s*(\d+)').firstMatch('$msg $details');
    if (match != null) {
      apiCode = int.tryParse(match.group(1) ?? '');
    }

    // Map common scenarios to guidance
    if (apiCode == 10) {
      return 'Google Sign-In failed (ApiException 10). This usually means the app\'s SHA-1/SHA-256 are not added in Firebase for ${_auth.app.name}. Add the debug/release SHA in Firebase Console → Project Settings → Android app (${_auth.app.name}), download the new google-services.json, replace it in android/app, then rebuild.';
    }
    if (apiCode == 7) {
      return 'Google Sign-In failed (ApiException 7: Network error). Please check your internet connection and try again.';
    }

    switch (code) {
      case 'sign_in_canceled':
        return 'Sign-in was cancelled. Please try again.';
      case 'network_error':
        return 'Network error during Google Sign-In. Check your connection and try again.';
      case 'sign_in_failed':
        // Could still be ApiException 10 hidden in message
        if ((msg + details).contains('ApiException: 10')) {
          return 'Google Sign-In failed (ApiException 10). Likely missing SHA-1/SHA-256 in Firebase for your Android app. Add fingerprints in Firebase Console and update google-services.json.';
        }
        return 'Google Sign-In failed. Please try again.';
      default:
        return 'Google Sign-In error (${e.code}): ${e.message ?? 'Unknown error'}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(
        success: true,
        message: 'Password reset email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Send email verification
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'No user is currently signed in',
        );
      }

      if (user.emailVerified) {
        return AuthResult(success: false, message: 'Email is already verified');
      }

      await user.sendEmailVerification();
      return AuthResult(
        success: true,
        message: 'Verification email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Update user profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'No user is currently signed in',
        );
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();

      return AuthResult(
        success: true,
        user: _auth.currentUser,
        message: 'Profile updated successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Delete account
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'No user is currently signed in',
        );
      }

      await user.delete();
      return AuthResult(success: true, message: 'Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is not valid. Please enter a valid email.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }
}

// Result class for authentication operations
class AuthResult {
  final bool success;
  final User? user;
  final String message;

  AuthResult({required this.success, this.user, required this.message});
}
