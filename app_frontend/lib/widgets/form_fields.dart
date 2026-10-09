import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/i18n.dart';

InputDecoration hawaInputDecoration({
  required String label,
  String? hint,
  Widget? prefix,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: HawaText.deva(14, color: HawaColors.muted),
    floatingLabelStyle: HawaText.deva(14, color: HawaColors.teal),
    hintStyle: HawaText.sans(15, color: HawaColors.muted),
    prefixIcon: prefix,
    filled: true,
    fillColor: HawaColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(HawaColors.line),
    enabledBorder: border(HawaColors.line),
    focusedBorder: border(HawaColors.teal, 2),
    errorBorder: border(HawaColors.alert),
    focusedErrorBorder: border(HawaColors.alert, 2),
  );
}

/// Indian mobile number input with a fixed `+91` prefix.
class PhoneField extends StatelessWidget {
  const PhoneField({required this.controller, this.validator, super.key});

  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      style: HawaText.mono(17, weight: FontWeight.w500),
      decoration: hawaInputDecoration(
        label: context.tr('मोबाइल नंबर', 'Mobile number'),
        hint: '98100 00012',
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Text(
            '+91',
            style: HawaText.mono(
              17,
              weight: FontWeight.w500,
              color: HawaColors.muted2,
            ),
          ),
        ),
      ).copyWith(prefixIconConstraints: const BoxConstraints()),
    );
  }
}
