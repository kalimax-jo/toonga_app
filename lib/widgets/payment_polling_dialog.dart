import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PaymentPollingToken {
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  bool get isCancelled => _cancelled;
}

class PaymentPollingDialog extends StatefulWidget {
  final Future<bool> Function(
    ValueChanged<String> onStatus,
    PaymentPollingToken token,
  )
  poller;

  const PaymentPollingDialog({required this.poller});

  @override
  State<PaymentPollingDialog> createState() => _PaymentPollingDialogState();
}

class _PaymentPollingDialogState extends State<PaymentPollingDialog> {
  String _status = 'Waiting for MTN MoMo...';
  final _token = PaymentPollingToken();
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    widget
        .poller(_updateStatus, _token)
        .then((result) {
          if (!mounted || _isClosed) return;
          _isClosed = true;
          Navigator.of(context, rootNavigator: true).pop(result);
        })
        .catchError((_) {
          if (!mounted || _isClosed) return;
          _isClosed = true;
          Navigator.of(context, rootNavigator: true).pop(false);
        });
  }

  void _updateStatus(String value) {
    if (!mounted || _isClosed) return;
    setState(() => _status = value);
  }

  void _cancel() {
    if (_isClosed) return;
    _token.cancel();
    _isClosed = true;
    Navigator.of(context, rootNavigator: true).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: const Color(0xFF0D0D0D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Waiting for MTN MoMo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _cancel,
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
