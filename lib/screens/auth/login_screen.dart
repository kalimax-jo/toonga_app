import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import 'package:google_sign_in/google_sign_in.dart';

import '../../services/api_client.dart';
import '../../services/auth_api.dart';
import '../../services/fcm_service.dart';
import '../../services/session_manager.dart';
import '../../widgets/toonga_input_field.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

const String _kGoogleServerClientId =
    '425181536010-knk3m6rren7522p8pj2r40t86qr86qh7.apps.googleusercontent.com';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  final AuthApi _authApi = AuthApi();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: _kGoogleServerClientId,
  );
  final SessionManager _sessionManager = SessionManager.instance;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Image.asset('assets/images/logo.png', height: 80),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Let's get you in to Toonga",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          ToongaInputField(
                            controller: _emailController,
                            hintText: 'Your Email',
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              final emailRegex = RegExp(
                                r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          ToongaInputField(
                            controller: _passwordController,
                            hintText: 'Your Password',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SocialButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Sign in with Google',
                      backgroundColor: Colors.white.withOpacity(0.08),
                      loading: _googleLoading,
                      onTap: _handleGoogleSignIn,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text('Create account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final token = response.token;
      if (token != null && token.isNotEmpty) {
        await _sessionManager.saveToken(token);
        await FcmService.instance.ensureDeviceRegistered();
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on ApiException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (error) {
      setState(() => _errorMessage = 'Unable to sign in. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken ?? auth.serverAuthCode;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          message:
              'Failed to retrieve Google token or auth code. Please try again.',
        );
      }

      developer.log('Google ID token retrieved', name: 'auth.google');

      final response = await _authApi.loginWithGoogle(idToken: idToken);
      developer.log('Backend login response received', name: 'auth.google');
      final token = response.token;
      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Backend did not return an auth token',
        );
      }

      await _sessionManager.saveToken(token);
      await FcmService.instance.ensureDeviceRegistered();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } on PlatformException catch (error) {
      final message =
          error.message ?? 'Google sign-in failed. Please try again.';
      developer.log(
        'Google sign-in platform exception',
        name: 'auth.google',
        error: error,
        stackTrace: StackTrace.current,
      );
      debugPrint('Google sign-in PlatformException: (${error.code}) $message');
      debugPrintStack(label: 'PlatformException stack');
      setState(() {
        _errorMessage = message;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error, stackTrace) {
      developer.log(
        'Google sign-in unexpected error',
        name: 'auth.google',
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('Google sign-in unexpected error: $error');
      debugPrintStack(label: 'General sign-in error', stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final bool loading;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(32),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: loading
                ? const Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
