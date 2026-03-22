// ============================================================
// cv_field.dart
// حقل نص موحد مع أيقونة — يُستخدم في جميع شاشات CV Builder
// ============================================================

import 'package:flutter/material.dart';

class CVField extends StatelessWidget {
  const CVField({
    super.key,
    required this.ctrl,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
  });

  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }
}
