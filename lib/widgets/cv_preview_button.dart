// ============================================================
// cv_preview_button.dart
// زر توليد PDF ومشاركته — يُوضع في AppBar الشاشة الرئيسية
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cv_controller.dart';
import '../../models/cv_model.dart';

class CVPreviewButton extends StatelessWidget {
  const CVPreviewButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CVController>();

    return Obx(
      () => ctrl.isGeneratingPdf.value
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip:
                  ctrl.cvModel.value?.language == CVLanguage.arabic
                      ? 'توليد PDF ومشاركته'
                      : 'Generate & Share PDF',
              onPressed: ctrl.generateAndSharePdf,
            ),
    );
  }
}
