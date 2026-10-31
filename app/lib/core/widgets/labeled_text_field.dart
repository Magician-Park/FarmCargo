import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 라벨 + 입력 칸. [validator]가 문구를 돌려주면 입력이 있을 때만 오류로 표시한다.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.suffix,
    this.optional = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String value)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final TextInputAction textInputAction;
  final Widget? suffix;
  final bool optional;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(
            text: label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            children: [
              if (optional)
                const TextSpan(
                  text: '  선택',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey),
                ),
            ],
          )),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final text = controller.text;
              final error =
                  text.isEmpty || validator == null ? null : validator!(text);
              return TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                textInputAction: textInputAction,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hint,
                  errorText: error,
                  suffixIcon: suffix,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
