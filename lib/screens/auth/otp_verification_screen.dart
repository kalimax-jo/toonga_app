import 'package:flutter/material.dart';

import '../../services/phone_auth_service.dart';
import '../../theme/app_colors.dart';
import 'create_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String phone;
  final String verificationId;
  final int? resendToken;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.phone,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final PhoneAuthService _phoneAuthService = PhoneAuthService();
  bool _submitting = false;
  bool _resending = false;
  String? _errorMessage;
  late String _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
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
            child: Container(color: Colors.black.withOpacity(0.92)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Enter verification code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please enter the code sent to ${widget.phone}.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_controllers.length, _buildOtpBox),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resending ? null : _handleResend,
                    child: _resending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend code'),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          right: index == _controllers.length - 1 ? 0 : 8,
        ),
        child: SizedBox(
          height: 70,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < _controllers.length - 1) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != _controllers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full code.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _phoneAuthService.verifySmsCode(
        verificationId: _verificationId,
        smsCode: code,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreatePasswordScreen(email: widget.email),
        ),
      );
    } catch (_) {
      setState(() => _errorMessage = 'Invalid code. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _resending = true;
      _errorMessage = null;
    });

    await _phoneAuthService.verifyPhoneNumber(
      phoneNumber: widget.phone,
      forceResendingToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        setState(() {
          _resending = false;
          _verificationId = verificationId;
          _resendToken = resendToken;
        });
      },
      onAutoVerified: () {
        if (!mounted) return;
        setState(() => _resending = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePasswordScreen(email: widget.email),
          ),
        );
      },
      onFailed: (message) {
        if (!mounted) return;
        setState(() {
          _resending = false;
          _errorMessage = message;
        });
      },
    );
  }
}
