// ============================================================
// cv_date_field.dart
// حقل التاريخ بصيغة MM/YYYY
// ============================================================

import 'package:flutter/material.dart';

class CVDateField extends StatelessWidget {
  const CVDateField({
    super.key,
    required this.ctrl,
    required this.label,
    this.hint = 'MM/YYYY',
    this.onChanged,
  });

  final TextEditingController ctrl;
  final String label;
  final String hint;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.datetime,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }
}
