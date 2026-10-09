import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';

/// Fixed +91 prefix and 10 digits (starting 6–9); the numeric keypad opens automatically.
class PhoneField extends StatelessWidget {
  const PhoneField({
    required this.controller,
    required this.onSubmitted,
    this.errorText,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.send,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      maxLength: 10,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      style: const TextStyle(fontSize: 22, letterSpacing: 1.5, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: context.l10n.phoneFieldLabel,
        counterText: '',
        errorText: errorText,
        prefixIcon: Container(
          width: 64,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: c.input)),
          ),
          child: const Text('+91', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
