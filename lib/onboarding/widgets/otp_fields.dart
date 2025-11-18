import 'package:flutter/material.dart';
import '../theme/onboarding_theme.dart';

class OtpFields extends StatefulWidget {
  final int length;
  final void Function(String code)? onCompleted;

  const OtpFields({super.key, this.length = 6, this.onCompleted});

  @override
  State<OtpFields> createState() => _OtpFieldsState();
}

class _OtpFieldsState extends State<OtpFields> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        final controller = _controllers[i];
        return SizedBox(
          width: 44,
          child: TextField(
            controller: controller,
            focusNode: _nodes[i],
            onChanged: (v) => _onChanged(i, v),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(fontSize: 20, color: Colors.white),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: OnboardingColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: OnboardingColors.stroke),
              ),
            ),
          ),
        );
      }),
    );
  }
}
