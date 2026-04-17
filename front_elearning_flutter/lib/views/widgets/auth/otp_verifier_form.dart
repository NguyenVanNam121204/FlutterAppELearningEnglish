import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_primary_button.dart';

class OtpVerifierForm extends StatefulWidget {
  const OtpVerifierForm({
    super.key,
    required this.onVerify,
    this.onResend,
    this.verifyLabel = 'Xác minh',
    this.resendLabel = 'Gửi lại mã OTP',
    this.initialSeconds = 120,
    this.loading = false,
  });

  final Future<void> Function(String otpCode) onVerify;
  final Future<void> Function()? onResend;
  final String verifyLabel;
  final String resendLabel;
  final int initialSeconds;
  final bool loading;

  @override
  State<OtpVerifierForm> createState() => _OtpVerifierFormState();
}

class _OtpVerifierFormState extends State<OtpVerifierForm> {
  static const _otpLength = 6;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _startTimer();
    
    for (int i = 0; i < _otpLength; i++) {
      _focusNodes[i].onKeyEvent = (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[i].text.isEmpty && i > 0) {
            _focusNodes[i - 1].requestFocus();
            // We can even clear the previous one for better UX:
            // _controllers[i - 1].clear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes.first.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 0) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  Future<void> _resendOtp() async {
    if (widget.onResend == null || _remainingSeconds > 0 || widget.loading) {
      return;
    }

    await widget.onResend!.call();

    if (!mounted) {
      return;
    }

    _clearOtp();
    setState(() {
      _remainingSeconds = widget.initialSeconds;
    });
    _startTimer();
    _focusNodes.first.requestFocus();
  }

  void _clearOtp() {
    for (final controller in _controllers) {
      controller.clear();
    }
  }

  void _handleChanged(String value, int index) {
    if (value.isEmpty) {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) {
      _controllers[index].clear();
      return;
    }

    final digit = cleaned.substring(cleaned.length - 1);
    
    // Update text and keep cursor at the end
    _controllers[index].value = TextEditingValue(
      text: digit,
      selection: const TextSelection.collapsed(offset: 1),
    );

    if (index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      // Optional: auto submit when all filled
      if (_controllers.every((c) => c.text.isNotEmpty)) {
        _submit();
      }
    }
  }

  Future<void> _submit() async {
    final otpCode = _controllers.map((item) => item.text).join();
    if (otpCode.length != _otpLength ||
        _remainingSeconds <= 0 ||
        widget.loading) {
      return;
    }

    await widget.onVerify(otpCode);
  }

  String _formattedTime() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final canVerify =
        _controllers.every((controller) => controller.text.isNotEmpty) &&
        _remainingSeconds > 0 &&
        !widget.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpLength, (index) {
            return SizedBox(
              width: 48,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                maxLength: 1,
                enabled: !widget.loading,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
                onChanged: (value) => _handleChanged(value, index),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD8DFEB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD8DFEB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          _remainingSeconds > 0
              ? 'Thời gian còn lại: ${_formattedTime()}'
              : 'Mã OTP đã hết hạn. Vui lòng gửi lại mã mới.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _remainingSeconds > 0
                ? const Color(0xFF5E6A80)
                : Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        AuthPrimaryButton(
          label: widget.verifyLabel,
          isLoading: widget.loading,
          onPressed: canVerify ? _submit : null,
        ),
        if (widget.onResend != null) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: (_remainingSeconds > 0 || widget.loading)
                ? null
                : _resendOtp,
            child: Text(widget.resendLabel),
          ),
        ],
      ],
    );
  }
}

