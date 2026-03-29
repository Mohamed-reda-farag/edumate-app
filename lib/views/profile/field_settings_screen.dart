// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/global_learning_state.dart';
import 'field_selector_screen.dart';
import 'field_skill_levels_screen.dart';
import 'confirmation_dialogs.dart';

/// شاشة إعدادات المجالات — منفصلة عن SettingsScreen الرئيسية.
/// تحتوي على كل منطق إدارة المجال الأساسي والثانوي كما كان في الإعدادات.
class FieldSettingsScreen extends StatefulWidget {
  const FieldSettingsScreen({super.key});

  @override
  State<FieldSettingsScreen> createState() => _FieldSettingsScreenState();
}

class _FieldSettingsScreenState extends State<FieldSettingsScreen> {
  // ═══════════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات المجالات'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<GlobalLearningState>(
        builder: (context, globalState, _) {
          if (globalState.isLoadingUserProfile) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldManagementSection(globalState),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI — إدارة المجالات (منقول كما هو من SettingsScreen)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFieldManagementSection(GlobalLearningState globalState) {
    final primaryFieldId = globalState.primaryField;
    final secondaryFieldId = globalState.secondaryField;
    final primaryField =
        primaryFieldId != null
            ? globalState.getFieldData(primaryFieldId)
            : null;
    final secondaryField =
        secondaryFieldId != null
            ? globalState.getFieldData(secondaryFieldId)
            : null;

    return _buildSection(
      title: 'مجالاتي',
      icon: Icons.dashboard_rounded,
      children: [
        _buildFieldCard(
          title: 'المجال الأساسي',
          fieldName: primaryField?.name ?? 'غير محدد',
          fieldIcon: primaryField?.icon ?? '📚',
          isPrimary: true,
          onChangeTap: () => _changePrimaryField(globalState),
        ),
        const SizedBox(height: 12),
        if (secondaryField != null)
          _buildFieldCard(
            title: 'المجال الثانوي',
            fieldName: secondaryField.name,
            fieldIcon: secondaryField.icon,
            isPrimary: false,
            onChangeTap: () => _changeSecondaryField(globalState),
            onDeleteTap: () => _removeSecondaryField(globalState),
          )
        else
          _buildAddSecondaryFieldCard(globalState),
      ],
    );
  }

  Widget _buildFieldCard({
    required String title,
    required String fieldName,
    required String fieldIcon,
    required bool isPrimary,
    required VoidCallback onChangeTap,
    VoidCallback? onDeleteTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(fieldIcon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fieldName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onChangeTap,
                tooltip: 'تغيير',
              ),
              if (onDeleteTap != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDeleteTap,
                  tooltip: 'حذف',
                  color: Colors.red,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddSecondaryFieldCard(GlobalLearningState globalState) {
    return InkWell(
      onTap: () => _addSecondaryField(globalState),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إضافة مجال ثانوي',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'وسّع معرفتك في مجال إضافي',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI Helper
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions (منقولة كما هي من SettingsScreen)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _ensureAllFieldsLoaded(GlobalLearningState globalState) async {
    const int expectedMinFields = 10;
    if (globalState.allFields.length < expectedMinFields) {
      await globalState.loadAllFields();
    }
  }

  Future<void> _changePrimaryField(GlobalLearningState globalState) async {
    final confirmed = await ConfirmationDialogs.showChangeFieldWarning(
      context,
      isPrimary: true,
    );
    if (!confirmed) return;

    await _ensureAllFieldsLoaded(globalState);
    if (!mounted) return;

    final newFieldId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => FieldSelectorScreen(
          isPrimary: true,
          excludeFields: globalState.selectedFields,
        ),
      ),
    );
    if (newFieldId == null || !mounted) return;

    final fieldName =
        globalState.getFieldData(newFieldId)?.name ?? newFieldId;
    final skillLevels = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => FieldSkillLevelsScreen(
          fieldId: newFieldId,
          fieldName: fieldName,
        ),
      ),
    );
    if (skillLevels == null || !mounted) return;

    try {
      await globalState.changeField(
        isPrimary: true,
        newFieldId: newFieldId,
        skillLevels: Map<String, dynamic>.from(skillLevels),
      );
      if (mounted) {
        ConfirmationDialogs.showSuccessSnackBar(
          context,
          'تم تغيير المجال الأساسي بنجاح',
        );
      }
    } catch (e) {
      if (mounted) {
        ConfirmationDialogs.showErrorSnackBar(
          context,
          'فشل تغيير المجال: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _changeSecondaryField(GlobalLearningState globalState) async {
    final confirmed = await ConfirmationDialogs.showChangeFieldWarning(
      context,
      isPrimary: false,
    );
    if (!confirmed) return;

    await _ensureAllFieldsLoaded(globalState);
    if (!mounted) return;

    final newFieldId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => FieldSelectorScreen(
          isPrimary: false,
          excludeFields: globalState.selectedFields,
        ),
      ),
    );
    if (newFieldId == null || !mounted) return;

    final fieldName =
        globalState.getFieldData(newFieldId)?.name ?? newFieldId;
    final skillLevels = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => FieldSkillLevelsScreen(
          fieldId: newFieldId,
          fieldName: fieldName,
        ),
      ),
    );
    if (skillLevels == null || !mounted) return;

    try {
      await globalState.changeField(
        isPrimary: false,
        newFieldId: newFieldId,
        skillLevels: Map<String, dynamic>.from(skillLevels),
      );
      if (mounted) {
        ConfirmationDialogs.showSuccessSnackBar(
          context,
          'تم تغيير المجال الثانوي بنجاح',
        );
      }
    } catch (e) {
      if (mounted) {
        ConfirmationDialogs.showErrorSnackBar(
          context,
          'فشل تغيير المجال: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _addSecondaryField(GlobalLearningState globalState) async {
    await _ensureAllFieldsLoaded(globalState);
    if (!mounted) return;

    final newFieldId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => FieldSelectorScreen(
          isPrimary: false,
          excludeFields: globalState.selectedFields,
        ),
      ),
    );
    if (newFieldId == null || !mounted) return;

    final fieldName =
        globalState.getFieldData(newFieldId)?.name ?? newFieldId;
    final skillLevels = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => FieldSkillLevelsScreen(
          fieldId: newFieldId,
          fieldName: fieldName,
        ),
      ),
    );
    if (skillLevels == null || !mounted) return;

    try {
      await globalState.addSecondaryField(
        newFieldId,
        skillLevels: Map<String, dynamic>.from(skillLevels),
      );
      if (mounted) {
        ConfirmationDialogs.showSuccessSnackBar(
          context,
          'تم إضافة المجال الثانوي بنجاح',
        );
      }
    } catch (e) {
      if (mounted) {
        ConfirmationDialogs.showErrorSnackBar(
          context,
          'فشل إضافة المجال: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _removeSecondaryField(GlobalLearningState globalState) async {
    final confirmed =
        await ConfirmationDialogs.showRemoveSecondaryFieldWarning(context);
    if (!confirmed) return;

    try {
      await globalState.removeSecondaryField();
      if (mounted) {
        ConfirmationDialogs.showSuccessSnackBar(
          context,
          'تم حذف المجال الثانوي',
        );
      }
    } catch (e) {
      if (mounted) {
        ConfirmationDialogs.showErrorSnackBar(
          context,
          'فشل حذف المجال: ${e.toString()}',
        );
      }
    }
  }
}