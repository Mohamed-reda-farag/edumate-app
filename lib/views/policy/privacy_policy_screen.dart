import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _PolicyHeader(
            title: 'سياسة الخصوصية',
            subtitle: 'آخر تحديث: مارس 2026',
          ),
          SizedBox(height: 24),

          _PolicySection(
            title: '1. مقدمة',
            content:
                'نرحب بكم في تطبيق EduMate، المنصة التعليمية الهندسية الشاملة. '
                'نحن نُولي خصوصية مستخدمينا أهمية قصوى ونلتزم بحمايتها وفق أعلى المعايير.\n\n'
                'تصف هذه السياسة كيفية جمعنا للبيانات الشخصية، وطريقة استخدامها، وحقوقك كمستخدم. '
                'باستخدامك للتطبيق، فإنك توافق على الشروط الواردة في هذه السياسة.',
          ),

          _PolicySection(
            title: '2. البيانات التي نجمعها',
            content: '',
            subsections: [
              _Subsection(
                title: 'أ) البيانات التي تُقدمها مباشرةً',
                bullets: [
                  'بيانات الحساب: الاسم، عنوان البريد الإلكتروني، وكلمة المرور المشفرة',
                  'بيانات الاستبيان الأولي: المجال الهندسي، مستوى المهارة، أوقات التعلم المفضلة، والأهداف',
                  'بيانات السيرة الذاتية: البيانات الشخصية، الخبرات، التعليم، والمشاريع (اختياري)',
                  'بيانات الجدول الدراسي: المواد، أوقات المحاضرات، وسجلات الحضور',
                  'تقييمات الكورسات والملاحظات الشخصية',
                ],
              ),
              _Subsection(
                title: 'ب) البيانات التي نجمعها تلقائياً',
                bullets: [
                  'بيانات التقدم التعليمي: نسبة إتمام الكورسات والدروس ونتائج اختبارات المهارات',
                  'بيانات الاستخدام: مدة الجلسات والكورسات التي تمت مشاهدتها وعدد مرات الوصول',
                  'بيانات السلوك في الاختبارات: عدد مرات الخروج من التطبيق ومحاولات النسخ/اللصق كمؤشرات تعليمية فقط',
                  'بيانات النظام: نوع الجهاز ونظام التشغيل وإصدار التطبيق',
                  'بيانات الأداء الأكاديمي: معدل الحضور وتقييمات الفهم ونقاط Gamification',
                  'مراجعات الكورسات والتقييمات النجمية التي تختار نشرها',
                ],
              ),
              _Subsection(
                title: 'ج) البيانات التي لا نجمعها أبداً',
                bullets: [
                  'الموقع الجغرافي الدقيق',
                  'بيانات الدفع أو المعلومات المصرفية',
                  'محادثات اختبارات المهارات مع الذكاء الاصطناعي (تُرسل للمعالجة ولا تُخزن)',
                ],
              ),
            ],
          ),

          _PolicySection(
            title: '3. كيفية استخدام البيانات',
            content: 'نستخدم البيانات التي نجمعها للأغراض التالية حصراً:',
            bullets: [
              'تقديم خدمة تعليمية مخصصة وتوليد خطة تعلم مناسبة لمستواك وأهدافك',
              'تتبع تقدمك عبر خرائط المهارات وحساب نقاط الإنجازات ومستوى الـ Gamification',
              'توليد جدول مذاكرة أسبوعي ذكي بناءً على جدولك الدراسي وأولويات مواد كل أسبوع',
              'إرسال إشعارات تذكير بالمحاضرات والمهام وجلسات المذاكرة وفق تفضيلاتك',
              'تطبيق نظام مكافحة الغش بتتبع وقت المشاهدة الفعلي وتقييم سلوك الاختبار',
              'تحسين خوارزميات التوصية وتطوير جودة التطبيق',
              'مساعدتك على بناء سيرة ذاتية احترافية متوافقة مع نظام ATS وتصديرها كـ PDF',
            ],
          ),

          _PolicySection(
            title: '4. مشاركة البيانات',
            content:
                'نحن لا نبيع بياناتك الشخصية لأي طرف ثالث. نشارك البيانات في الحالات التالية فقط:',
            subsections: [
              _Subsection(
                title: 'مزودو الخدمات',
                bullets: [
                  'Google Firebase: لتخزين البيانات والمصادقة وإرسال الإشعارات عبر FCM',
                  'Google Gemini 2.0 Flash: لتشغيل اختبارات المهارات التفاعلية — تُرسل محادثة الاختبار للمعالجة فقط ولا تُخزن لدينا',
                  'منصات التعليم (YouTube, Udemy, Coursera): حين تضغط على رابط كورس، تسري سياسة خصوصيتهم',
                ],
              ),
            ],
          ),

          _PolicySection(
            title: '5. تخزين البيانات وأمانها',
            bullets: [
              'تُخزن جميع بيانات المستخدم في Firebase Firestore محمية بقواعد أمان صارمة (uid-based) تضمن أن كل مستخدم لا يصل إلا لبياناته الخاصة',
              'تُشفَّر كلمات المرور عبر Firebase Authentication ولا يمكن لأحد الاطلاع عليها',
              'تُخزن بعض البيانات مؤقتاً محلياً عبر Hive لدعم التشغيل بدون اتصال (Offline) مع مزامنة فورية عند عودة الإنترنت',
              'بيانات السيرة الذاتية تُحفظ بشكل مستقل تحت مسار آمن خاص ولا تُشارك مع أي طرف ثالث',
              'عند حذف حسابك يتم حذف جميع بياناتك تلقائياً ونهائياً من قاعدة البيانات بما فيها بيانات السيرة الذاتية',
            ],
          ),

          _PolicySection(
            title: '6. حقوقك كمستخدم',
            bullets: [
              'حق الوصول: يمكنك الاطلاع على جميع بياناتك من داخل التطبيق',
              'حق التعديل: يمكنك تعديل أي من بياناتك الشخصية في أي وقت',
              'حق الحذف: يمكنك حذف حسابك وجميع بياناتك المرتبطة به بشكل نهائي',
              'حق الاعتراض: يمكنك إيقاف الإشعارات من إعدادات التطبيق',
            ],
          ),

          _PolicySection(
            title: '7. الخصوصية والأطفال',
            content:
                'تطبيق EduMate موجه للطلاب في المرحلة الجامعية والثانوية. '
                'نحن لا نستهدف الأطفال دون سن 13 عاماً ولا نجمع بياناتهم. '
                'إذا علمنا بأن مستخدماً دون هذا السن قد سجّل في التطبيق، سنحذف حسابه فوراً.',
          ),

          _PolicySection(
            title: '8. التحديثات على هذه السياسة',
            content:
                'قد نُحدّث سياسة الخصوصية بصفة دورية. سنُبلغك بأي تغييرات جوهرية عبر إشعار داخل التطبيق. '
                'استمرارك في استخدام التطبيق بعد نشر التغييرات يُعدّ موافقةً على السياسة المُحدَّثة.',
          ),

          _PolicySection(
            title: '9. التواصل معنا',
            content:
                'إذا كان لديك أي استفسار يتعلق بخصوصيتك، يُرجى التواصل معنا عبر صفحة "تواصل معنا" في التطبيق، '
                'أو عبر البريد الإلكتروني: edumatesupport@gmail.com\n\n'
                'سنرد على جميع الاستفسارات في غضون 72 ساعة عمل.',
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widgets مساعدة
// ═══════════════════════════════════════════════════════════════════════════

class _PolicyHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PolicyHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Divider(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          thickness: 1.5,
        ),
      ],
    );
  }
}

class _Subsection {
  final String title;
  final List<String> bullets;

  const _Subsection({required this.title, required this.bullets});
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  final List<String> bullets;
  final List<_Subsection> subsections;

  const _PolicySection({
    required this.title,
    this.content = '',
    this.bullets = const [],
    this.subsections = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                ),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // النص الرئيسي
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                content,
                style: const TextStyle(fontSize: 14, height: 1.7),
              ),
            ),

          // Bullets مباشرة
          ...bullets.map((b) => _BulletItem(text: b)),

          // Subsections
          ...subsections.map(
            (sub) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...sub.bullets.map((b) => _BulletItem(text: b)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;

  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 10),
            child: CircleAvatar(
              radius: 3,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}