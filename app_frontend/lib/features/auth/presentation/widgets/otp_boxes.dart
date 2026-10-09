import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';

/// Six 56 dp boxes over one hidden field: paste fills all six, the 6th digit submits.
class OtpBoxes extends StatefulWidget {
  const OtpBoxes({
    required this.onCompleted,
    this.enabled = true,
    this.hasError = false,
    super.key,
  });

  final ValueChanged<String> onCompleted;
  final bool enabled;
  final bool hasError;

  @override
  State<OtpBoxes> createState() => OtpBoxesState();
}

class OtpBoxesState extends State<OtpBoxes> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  void clear() {
    _controller.clear();
    _focus.requestFocus();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    final code = _controller.text;
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 6; i++)
              Semantics(
                label: context.l10n.otpDigit('${i + 1}'),
                child: Container(
                  width: 48,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.hasError
                          ? c.danger
                          : i == code.length && _focus.hasFocus
                          ? c.brand
                          : c.input,
                      width: i == code.length || widget.hasError ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    i < code.length ? code[i] : '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              enableSuggestions: false,
              autocorrect: false,
              showCursor: false,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (v) {
                setState(() {});
                if (v.length == 6) widget.onCompleted(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
