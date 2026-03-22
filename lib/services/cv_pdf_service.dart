// ============================================================
// cv_pdf_service.dart
// توليد ملف PDF متوافق مع نظام ATS ومشاركته
// ============================================================
//
// pubspec.yaml dependencies needed:
//   pdf: ^3.11.1
//   path_provider: ^2.1.3
//   share_plus: ^9.0.0
// ============================================================

import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/cv_model.dart';

class CVPdfService {
  // ── ATS-Safe Colors ───────────────────────────────────────
  static const _primaryColor = PdfColor(0.11, 0.27, 0.52);   // Deep Navy
  static const _accentColor  = PdfColor(0.18, 0.42, 0.74);   // Blue
  static const _dividerColor = PdfColor(0.75, 0.75, 0.75);
  static const _textColor    = PdfColor(0.10, 0.10, 0.10);
  static const _subTextColor = PdfColor(0.40, 0.40, 0.40);

  // ── Main Entry ────────────────────────────────────────────
  // ── Share Only (بدون تحميل) ───────────────────────────────
  Future<void> generateAndShare(CVModel cv) async {
    debugPrint('[CVPdf] Starting share...');
    try {
      final pdf      = await _buildPdf(cv);
      final bytes    = await pdf.save();
      final fileName = '${_sanitizeFileName(cv.personalInfo.fullName)}_CV.pdf';

      final tempDir  = await getApplicationDocumentsDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);
      debugPrint('[CVPdf] Temp file ready: ${tempFile.path}');

      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'application/pdf')],
        subject: '${cv.personalInfo.fullName} - CV',
      );
      debugPrint('[CVPdf] Share sheet opened');
    } catch (e, stack) {
      debugPrint('[CVPdf] ❌ Share error: $e');
      debugPrint('[CVPdf] Stack: $stack');
      rethrow;
    }
  }

  // ── Save to Device Only (بدون share sheet) ────────────────
  // يرجع المسار الكامل للملف عند النجاح، أو null عند الفشل
  Future<String?> saveToDevice(CVModel cv) async {
    debugPrint('[CVPdf] Starting download...');
    try {
      final pdf      = await _buildPdf(cv);
      final bytes    = await pdf.save();
      final fileName = '${_sanitizeFileName(cv.personalInfo.fullName)}_CV.pdf';

      final path = await _saveToDownloads(bytes, fileName);
      debugPrint('[CVPdf] ✅ Saved to: $path');
      return path;
    } catch (e, stack) {
      debugPrint('[CVPdf] ❌ Download error: $e');
      debugPrint('[CVPdf] Stack: $stack');
      rethrow;
    }
  }

  // ── Save to Downloads ─────────────────────────────────────
  Future<String?> _saveToDownloads(List<int> bytes, String fileName) async {
    try {
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final rootPath = extDir.path.split('Android').first;
          downloadsDir = Directory('${rootPath}Download');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
        }
      }

      // Fallback: internal app documents directory
      downloadsDir ??= await getApplicationDocumentsDirectory();

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      debugPrint('[CVPdf] ✅ CV saved to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[CVPdf] ⚠️ Could not save to Downloads: $e');
      return null;
    }
  }

  // ── Build PDF Document ────────────────────────────────────
  Future<pw.Document> _buildPdf(CVModel cv) async {
    final doc = pw.Document(
      title: '${cv.personalInfo.fullName} - CV',
      author: cv.personalInfo.fullName,
      creator: 'EduApp CV Builder',
    );

    final isArabic = cv.language == CVLanguage.arabic;
    final textDirection = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    // ── Font selection ────────────────────────────────────────
    // English: Helvetica (built-in, no embedding needed)
    // Arabic:  Cairo (must be in assets/fonts/)
    //
    // لتفعيل الخط العربي، أضف في pubspec.yaml:
    //   flutter:
    //     assets:
    //       - assets/fonts/Cairo-Regular.ttf
    //       - assets/fonts/Cairo-Bold.ttf
    //
    // ثم حمّل ملفات الخط من Google Fonts:
    //   https://fonts.google.com/specimen/Cairo
    //   واضعهم في: assets/fonts/Cairo-Regular.ttf و Cairo-Bold.ttf
    pw.Font baseFont;
    pw.Font boldFont;
    pw.Font italicFont;

    if (isArabic) {
      final regularData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final boldData    = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      baseFont   = pw.Font.ttf(regularData);
      boldFont   = pw.Font.ttf(boldData);
      italicFont = pw.Font.ttf(regularData); // Cairo لا يملك italic — نستخدم Regular
    } else {
      baseFont   = pw.Font.helvetica();
      boldFont   = pw.Font.helveticaBold();
      italicFont = pw.Font.helveticaOblique();
    }

    final theme = pw.ThemeData(
      defaultTextStyle: pw.TextStyle(
        font: baseFont,
        fontSize: 10,
        color: _textColor,
      ),
    );

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        textDirection: textDirection,
        build: (context) => [
          _buildHeader(cv, boldFont, baseFont, italicFont, isArabic),
          pw.SizedBox(height: 10),
          if (cv.personalInfo.summary?.isNotEmpty == true)
            ..._buildSummary(cv, boldFont, baseFont, italicFont, isArabic),
          if (cv.experiences.isNotEmpty)
            ..._buildExperiences(cv, boldFont, baseFont, italicFont, isArabic),
          if (cv.educations.isNotEmpty)
            ..._buildEducations(cv, boldFont, baseFont, italicFont, isArabic),
          if (cv.skills.isNotEmpty)
            ..._buildSkills(cv, boldFont, baseFont, isArabic),
          if (cv.projects.isNotEmpty)
            ..._buildProjects(cv, boldFont, baseFont, italicFont, isArabic),
          if (cv.certificates.isNotEmpty)
            ..._buildCertificates(cv, boldFont, baseFont, italicFont, isArabic),
          if (cv.languages.isNotEmpty)
            ..._buildLanguages(cv, boldFont, baseFont, isArabic),
        ],
      ),
    );

    return doc;
  }

  // ── Header ────────────────────────────────────────────────
  pw.Widget _buildHeader(
    CVModel cv,
    pw.Font bold,
    pw.Font base,
    pw.Font italic,
    bool isArabic,
  ) {
    final info = cv.personalInfo;
    final contactParts = <String>[];
    if (info.email.isNotEmpty) contactParts.add(info.email);
    if (info.phone.isNotEmpty) contactParts.add(info.phone);
    if (info.city.isNotEmpty && info.country.isNotEmpty) {
      contactParts.add('${info.city}, ${info.country}');
    } else if (info.city.isNotEmpty) {
      contactParts.add(info.city);
    }

    final linkParts = <String>[];
    if (info.linkedIn?.isNotEmpty == true) linkParts.add(info.linkedIn!);
    if (info.github?.isNotEmpty == true) linkParts.add(info.github!);
    if (info.portfolio?.isNotEmpty == true) linkParts.add(info.portfolio!);

    return pw.Column(
      crossAxisAlignment: isArabic
          ? pw.CrossAxisAlignment.end
          : pw.CrossAxisAlignment.start,
      children: [
        // Name
        pw.Text(
          info.fullName,
          style: pw.TextStyle(
            font: bold,
            fontSize: 16, // ATS-safe: max recommended is 16
            color: _primaryColor,
          ),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        if (info.jobTitle.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            info.jobTitle,
            style: pw.TextStyle(
              font: base,
              fontSize: 12,
              color: _accentColor,
            ),
          ),
        ],
        pw.SizedBox(height: 6),
        // Divider line in accent color
        pw.Container(
          height: 2,
          color: _primaryColor,
        ),
        pw.SizedBox(height: 5),
        // Contact info (ATS reads plain text)
        if (contactParts.isNotEmpty)
          pw.Text(
            contactParts.join('  |  '),
            style: pw.TextStyle(font: base, fontSize: 10, color: _subTextColor),
          ),
        if (linkParts.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            linkParts.join('  |  '),
            style: pw.TextStyle(font: base, fontSize: 10, color: _subTextColor),
          ),
        ],
      ],
    );
  }

  // ── Section Title ─────────────────────────────────────────
  List<pw.Widget> _sectionTitle(
    String title,
    pw.Font bold,
    bool isArabic,
  ) =>
      [
        pw.SizedBox(height: 12),
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            font: bold,
            fontSize: 10,
            color: _primaryColor,
            letterSpacing: 1.2,
          ),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        pw.SizedBox(height: 3),
        pw.Container(height: 1, color: _dividerColor),
        pw.SizedBox(height: 6),
      ];

  // ── Summary ───────────────────────────────────────────────
  List<pw.Widget> _buildSummary(
    CVModel cv,
    pw.Font bold,
    pw.Font base,
    pw.Font italic,
    bool isArabic,
  ) {
    final label = isArabic ? 'الملخص المهني' : 'PROFESSIONAL SUMMARY';
    return [
      ..._sectionTitle(label, bold, isArabic),
      pw.Text(
        cv.personalInfo.summary!,
        style: pw.TextStyle(font: base, fontSize: 10, lineSpacing: 3),
        textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.justify,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
    ];
  }

  // ── Experience ────────────────────────────────────────────
  List<pw.Widget> _buildExperiences(
    CVModel cv,
    pw.Font bold,
    pw.Font base,
    pw.Font italic,
    bool isArabic,
  ) {
    final label = isArabic ? 'الخبرة العملية' : 'WORK EXPERIENCE';
    final widgets = <pw.Widget>[..._sectionTitle(label, bold, isArabic)];

    for (final exp in cv.experiences) {
      final endLabel = exp.isCurrent
          ? (isArabic ? 'حتى الآن' : 'Present')
          : (exp.endDate ?? '');
      final dateRange = '${exp.startDate} - $endLabel';
      final location = [exp.city, exp.country]
          .where((s) => s.isNotEmpty)
          .join(', ');

      widgets.addAll([
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              exp.jobTitle,
              style: pw.TextStyle(font: bold, fontSize: 10.5),
            ),
            pw.Text(
              dateRange,
              style: pw.TextStyle(
                  font: italic, fontSize: 9, color: _subTextColor),
            ),
          ],
        ),
        pw.SizedBox(height: 1),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              exp.company,
              style: pw.TextStyle(
                  font: italic, fontSize: 10, color: _accentColor),
            ),
            if (location.isNotEmpty)
              pw.Text(
                location,
                style:
                    pw.TextStyle(font: base, fontSize: 9, color: _subTextColor),
              ),
          ],
        ),
        pw.SizedBox(height: 4),
        for (final resp in exp.responsibilities)
          _bulletPoint(resp, base, isArabic),
        pw.SizedBox(height: 8),
      ]);
    }

    return widgets;
  }

  // ── Education ─────────────────────────────────────────────
  List<pw.Widget> _buildEducations(
    CVModel cv,
    pw.Font bold,
    pw.Font base,
    pw.Font italic,
    bool isArabic,
  ) {
    final label = isArabic ? 'التعليم' : 'EDUCATION';
    final widgets = <pw.Widget>[..._sectionTitle(label, bold, isArabic)];

    for (final edu in cv.educations) {
      final dateRange = '${edu.startDate} - ${edu.endDate}';
      final location = [edu.city, edu.country]
          .where((s) => s.isNotEmpty)
          .join(', ');

      widgets.addAll([
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${edu.degree} ${isArabic ? 'في' : 'in'} ${edu.major}',
              style: pw.TextStyle(font: bold, fontSize: 10.5),
            ),
            pw.Text(
              dateRange,
              style: pw.TextStyle(
                  font: italic, fontSize: 9, color: _subTextColor),
            ),
          ],
        ),
        pw.SizedBox(height: 1),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              edu.institution,
              style: pw.TextStyle(
                  font: italic, fontSize: 10, color: _accentColor),
            ),
            if (location.isNotEmpty)
              pw.Text(
                location,
                style:
                    pw.TextStyle(font: base, fontSize: 9, color: _subTextColor),
              ),
          ],
        ),
        if (edu.gpa?.isNotEmpty == true) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            '${isArabic ? 'المعدل:' : 'GPA:'} ${edu.gpa}',
            style: pw.TextStyle(font: base, fontSize: 9, color: _subTextColor),
          ),
        ],
        for (final ach in edu.achievements) _bulletPoint(ach, base, isArabic),
        pw.SizedBox(height: 8),
      ]);
    }

    return widgets;
  }

  // ── Skills ────────────────────────────────────────────────
  List<pw.Widget> _buildSkills(
    CVModel cv,
    pw.Font bold,
    pw.Font base,
    bool isArabic,
  ) {
    final label = isArabic ? 'المهارات' : 'SKILLS';
    final widgets = <pw.Widget>[..._sectionTitle(label, bold, isArabic)];

    // Group by category
    final grouped = <String, List<CVSkill>>{};
    for (final skill in cv.skills) {
      final cat = skill.category.isNotEmpty
          ? skill.category
          : (isArabic ? 'عام' : 'General');
      grouped.putIfAbsent(cat, () => []).add(skill);
    }

    for (final entry in grouped.entries) {
      // ATS reads plain keywords — no parentheses or level labels inline
      // Level info removed from keyword list to avoid confusing ATS parsers
      final skillsList = entry.value.map((s) => s.name).join(' / ');
      widgets.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 110,
              child: pw.Text(
                '${entry.key}:',
                style: pw.TextStyle(font: bold, fontSize: 10),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                skillsList,
                style: pw.TextStyle(font: base, fontSize: 10),
              ),
            ),
          ],
        ),
      );
      widgets.add(pw.SizedBox(height: 4));
    }

    return widgets;
  }

  // ── Projects ──────────────────────────────────────────────
  List<pw.Widget> _buildProjects(
    CVModel cv,
    pw.Font bold,
    pw.Font base,
    pw.Font italic,
    bool isArabic,
  ) {
    final label = isArabic ? 'المشاريع' : 'PROJECTS';
    final widgets = <pw.Widget>[..._sectionTitle(label, bold, isArabic)];

    for (final proj in cv.projects) {
      final techLine = proj.technologies.isNotEmpty
          ? '${isArabic ? 'التقنيات:' : 'Tech:'} ${proj.technologies.join(', ')}'
          : '';
      final dateLine = [proj.startDate, proj.endDate]
          .where((s) => s?.isNotEmpty == true)
          .join(' - ');

      widgets.addAll([
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(proj.name,
                style: pw.TextStyle(font: bold, fontSize: 10.5)),
            if (dateLine.isNotEmpty)
              pw.Text(dateLine,
                  style: pw.TextStyle(
                      font: italic, fontSize: 9, color: _subTextColor)),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          proj.description,
          style: pw.TextStyle(font: base, fontSize: 10, lineSpacing: 2),
          textDirection:
              isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        if (techLine.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            techLine,
            style:
                pw.TextStyle(font: italic, fontSize: 9, color: _subTextColor),
          ),
        ],
        if (proj.link?.isNotEmpty == true) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            proj.link!,
            style: pw.TextStyle(font: base, fontSize: 9, color: _accentColor),
          ),
        ],
        pw.SizedBox(height: 8),
      ]);
    }

    return widgets;
  }

  // ── Certificates ──────────────────────────────────────────
  List<pw.Widget> _buildCertificates(
    CVModel cv,
    pw.Font bold,
    pw.Font base,
    pw.Font italic,
    bool isArabic,
  ) {
    final label = isArabic ? 'الشهادات والدورات' : 'CERTIFICATIONS';
    final widgets = <pw.Widget>[..._sectionTitle(label, bold, isArabic)];

    for (final cert in cv.certificates) {
      final expiry = cert.expiryDate != null
          ? ' - ${isArabic ? 'تنتهي:' : 'Expires:'} ${cert.expiryDate}'
          : '';
      final credText = cert.credentialId != null
          ? '${isArabic ? 'رقم الاعتماد:' : 'Credential ID:'} ${cert.credentialId}'
          : '';

      widgets.addAll([
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(cert.name,
                style: pw.TextStyle(font: bold, fontSize: 10.5)),
            pw.Text(
              '${cert.issueDate}$expiry',
              style: pw.TextStyle(
                  font: italic, fontSize: 9, color: _subTextColor),
            ),
          ],
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          cert.issuer,
          style:
              pw.TextStyle(font: italic, fontSize: 10, color: _accentColor),
        ),
        if (credText.isNotEmpty) ...[
          pw.SizedBox(height: 1),
          pw.Text(credText,
              style:
                  pw.TextStyle(font: base, fontSize: 9, color: _subTextColor)),
        ],
        pw.SizedBox(height: 7),
      ]);
    }

    return widgets;
  }

  // ── Languages ─────────────────────────────────────────────
  List<pw.Widget> _buildLanguages(
    CVModel cv,
    pw.Font bold,
    pw.Font base,
    bool isArabic,
  ) {
    final label = isArabic ? 'اللغات' : 'LANGUAGES';
    final widgets = <pw.Widget>[..._sectionTitle(label, bold, isArabic)];

    final langLine = cv.languages
        .map((l) => '${l.language}: ${l.proficiency.label(cv.language)}')
        .join('    ');

    widgets.add(
      pw.Text(langLine,
          style: pw.TextStyle(font: base, fontSize: 10),
          textDirection:
              isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr),
    );

    return widgets;
  }

  // ── Bullet Point ──────────────────────────────────────────
  pw.Widget _bulletPoint(String text, pw.Font base, bool isArabic) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2, left: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('- ', style: pw.TextStyle(font: base, fontSize: 10)),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(font: base, fontSize: 10, lineSpacing: 2),
              textDirection:
                  isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filename sanitizer ────────────────────────────────────
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
}