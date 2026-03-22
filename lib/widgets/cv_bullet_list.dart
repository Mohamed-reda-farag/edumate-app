// ============================================================
// cv_bullet_list.dart
// قائمة نقاط ديناميكية قابلة للإضافة والحذف
// ============================================================

import 'package:flutter/material.dart';

class CVBulletList extends StatefulWidget {
  const CVBulletList({
    super.key,
    required this.items,
    required this.label,
    required this.hint,
    required this.isArabic,
    required this.onChanged,
  });

  final List<String> items;
  final String label;
  final String hint;
  final bool isArabic;
  final void Function(List<String>) onChanged;

  @override
  State<CVBulletList> createState() => _CVBulletListState();
}

class _CVBulletListState extends State<CVBulletList> {
  late final List<TextEditingController> _controllers;
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    if (_items.isEmpty) _items.add('');
    _controllers =
        _items.map((i) => TextEditingController(text: i)).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() {
    final values =
        _controllers.map((c) => c.text.trim()).toList();
    widget.onChanged(values);
  }

  void _addItem() {
    setState(() {
      _items.add('');
      _controllers.add(TextEditingController());
    });
  }

  void _removeItem(int index) {
    if (_controllers.length == 1) {
      _controllers[0].clear();
      _notify();
      return;
    }
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      _items.removeAt(index);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        for (int i = 0; i < _controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, right: 4),
                  child: Text(
                    '•',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _controllers[i],
                    textDirection: widget.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: i == 0 ? widget.hint : '',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (_) => _notify(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red.shade300,
                    size: 18,
                  ),
                  onPressed: () => _removeItem(i),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add, size: 16),
          label:
              Text(widget.isArabic ? 'إضافة نقطة' : 'Add bullet'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ),
      ],
    );
  }
}
