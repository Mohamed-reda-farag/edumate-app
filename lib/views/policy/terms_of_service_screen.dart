import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شروط الاستخدام'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _PolicyHeader(
            title: 'شروط الاستخدام',
            subtitle: 'آخر تحديث: مارس 2026',
          ),
          SizedBox(height: 24),

          _PolicySection(
            title: '1. القبول بالشروط',
            content:
                'باستخدامك تطبيق EduMate أو تسجيلك فيه، فإنك تؤكد أنك قرأت هذه الشروط وفهمتها وتوافق على الالتزام بها. '
                'إذا كنت لا توافق على أي من هذه الشروط، يُرجى عدم استخدام التطبيق.\n\n'
                'نحتفظ بحق تعديل هذه الشروط في أي وقت، وسيُبلَّغ المستخدمون بالتغييرات الجوهرية عبر إشعار داخل التطبيق.',
          ),

          _PolicySection(
            title: '2. وصف الخدمة',
            content: 'EduMate هو تطبيق تعليمي يُقدم:',
            bullets: [
              'خرائط تعلم تفاعلية لـ 30 مجالاً هندسياً مع نظام فتح تدريجي للمهارات',
              'توجيه لكورسات مجانية ومدفوعة من منصات خارجية (YouTube, Udemy, Coursera وغيرها)',
              'اختبارات مهارات تفاعلية مدعومة بـ Gemini 2.0 Flash بحد أقصى 3 محاولات لكل مهارة',
              'نظام إدارة الجدول الدراسي بأنواعه الثلاثة (محاضرة، سيكشن، معمل) مع تتبع الحضور',
              'توليد خطة مذاكرة أسبوعية ذكية مخصصة بناءً على أولويات المواد وتفضيلات المستخدم',
              'نظام نقاط وإنجازات وـ Streak (Gamification) مع أرشفة الفصول الدراسية',
              'أداة بناء السيرة الذاتية المتكاملة (8 خطوات) بتصدير PDF متوافق مع نظام ATS',
              'إشعارات ذكية ومخصصة للمحاضرات والمهام وجلسات المذاكرة',
            ],
          ),

          _PolicySection(
            title: '3. شروط إنشاء الحساب',
            bullets: [
              'يجب أن تكون في سن 13 عاماً أو أكبر لإنشاء حساب في التطبيق',
              'يجب تقديم بيانات صحيحة ودقيقة عند التسجيل',
              'أنت مسؤول عن الحفاظ على سرية بيانات حسابك',
              'حساب واحد لكل شخص — يُحظر إنشاء حسابات متعددة',
              'يُحظر مشاركة بيانات الدخول مع أي شخص آخر',
            ],
          ),

          _PolicySection(
            title: '4. الاستخدام المقبول',
            content: '',
            subsections: [
              _Subsection(
                title: '✅ يُسمح لك بـ',
                bullets: [
                  'استخدام التطبيق لأغراض تعليمية شخصية',
                  'حفظ تقدمك التعليمي وبياناتك الأكاديمية',
                  'تحميل السيرة الذاتية التي تولّدها ومشاركتها',
                  'إرسال ملاحظات واقتراحات لتحسين التطبيق',
                ],
              ),
              _Subsection(
                title: '🚫 يُحظر عليك',
                bullets: [
                  'محاولة التحايل على نظام مكافحة الغش في الكورسات أو التلاعب في بيانات التقدم',
                  'استخدام أدوات آلية (Bots) للتفاعل مع التطبيق',
                  'محاولة اختراق قاعدة البيانات أو الوصول لبيانات مستخدمين آخرين',
                  'نسخ أو إعادة توزيع محتوى التطبيق أو قواعد بيانات المهارات والمجالات',
                  'استخدام التطبيق لأغراض تجارية بدون إذن كتابي مسبق',
                ],
              ),
            ],
          ),

          _PolicySection(
            title: '5. نظام مكافحة الغش',
            content: 'يعتمد EduMate نظاماً متقدماً للتحقق من التعلم الحقيقي:',
            subsections: [
              _Subsection(
                title: 'قفل الدروس الزمني',
                bullets: [
                  'لا يُسجَّل درس كمكتمل إلا بعد مرور الوقت الكافي الذي يعكس مشاهدةً فعلية، مع هامش تسامح 20%',
                  'الحد اليومي للدروس يُحدَّد تلقائياً بناءً على مدة جلستك المفضلة (قصيرة: درس/يوم، متوسطة: درسان، طويلة: 4 دروس)',
                  'الحد الأسبوعي يُحدَّد من عدد أيام التعلم في أسبوعك، مع هامش التسامح حسب مستوى التزامك (خفيف +10%، متوسط +20%، عالي +30%)',
                  'عند التجاوز الأول: تحذير برتقالي مع إتمام العملية. عند التجاوز الثاني: منع تسجيل دروس لبقية اليوم أو الأسبوع',
                ],
              ),
              _Subsection(
                title: 'اختبارات المهارات',
                bullets: [
                  'اختبارات تفاعلية بـ Gemini 2.0 Flash تُقيّم الفهم الحقيقي للمحتوى — ليس الحفظ',
                  'الحد الأقصى 3 محاولات لكل مهارة: انتظار 24 ساعة بعد المحاولة الأولى، و48 ساعة بعد الثانية',
                  'نتيجة الاختبار تؤثر مباشرة على التقدم: ناجح (≥80%) يُثبّت المهارة، يحتاج مراجعة (50-79%) يُعيد الكورس جزئياً، ضعيف (20-49%) يُعيد الكورس بنسبة مكافئة',
                  'نتيجة أقل من 20% (cheating) تُلغي الكورس كاملاً وتُسجَّل في عداد خاص',
                  'مؤشرات سلوكية تُراقَب أثناء الاختبار: الخروج من التطبيق ومحاولات النسخ/اللصق تُحتسب كعقوبة على الدرجة النهائية',
                  'أي محاولة للتحايل الممنهج على هذا النظام قد تُفضي لإيقاف الحساب',
                ],
              ),
            ],
          ),

          _PolicySection(
            title: '6. الكورسات والمحتوى الخارجي',
            content: 'يعمل EduMate كمنصة توجيه ولا يمتلك الكورسات المعروضة:',
            bullets: [
              'الكورسات المجانية على YouTube متاحة عبر روابط خارجية وتخضع لشروط Google/YouTube',
              'الكورسات على Udemy وCoursera وغيرها تخضع لشروط تلك المنصات وقد تكون مدفوعة',
              'EduMate غير مسؤول عن توفر الكورسات الخارجية أو جودتها أو تغيير أسعارها',
              'بيانات الرواتب والمسارات الوظيفية هي لأغراض إرشادية فقط وليست ضماناً',
            ],
          ),

          _PolicySection(
            title: '7. السيرة الذاتية وملكية المحتوى',
            bullets: [
              'السيرة الذاتية التي تُنشئها في التطبيق (عبر 8 خطوات: لغة، بيانات شخصية، ملخص، خبرات، تعليم، مهارات، مشاريع، شهادات/لغات) هي ملكيتك الكاملة',
              'أنت مسؤول عن دقة المعلومات التي تُدرجها في سيرتك الذاتية',
              'بيانات سيرتك الذاتية تُخزن بشكل آمن تحت مسار مستقل في Firestore ولا تُشارك مع أي طرف ثالث',
              'ملف PDF المُصدَّر متوافق مع نظام ATS ويمكن مشاركته مباشرة من التطبيق',
              'عند حذف حسابك تُحذف بيانات السيرة الذاتية تلقائياً قبل حذف الحساب الأب',
            ],
          ),

          _PolicySection(
            title: '8. الاشتراك والتسعير',
            content:
                'التطبيق في وضعه الحالي مجاني بالكامل. قد نُطلق في المستقبل خدمات متميزة (Premium). '
                'في حال ذلك، سيُبلَّغ المستخدمون الحاليون مسبقاً وستبقى الميزات الأساسية متاحة مجاناً.',
          ),

          _PolicySection(
            title: '9. الملكية الفكرية',
            bullets: [
              'خوارزميات توليد خطط التعلم الأسبوعية ونظام الـ Roadmap التفاعلي وخوارزمية حساب الأداء العام وجميع المحتوى الأصلي هي ملكية فكرية خاصة بـ EduMate',
              'قواعد بيانات المجالات والمهارات والكورسات المُنسَّقة ضمن التطبيق محمية ولا يجوز نسخها أو إعادة توزيعها',
              'شعار التطبيق واسمه محميان بحقوق الملكية',
            ],
          ),

          _PolicySection(
            title: '10. إخلاء المسؤولية',
            content: 'EduMate منصة تعليمية إرشادية:',
            bullets: [
              'لا نضمن التوظيف أو الحصول على وظيفة بعد إتمام مسارات التعلم',
              'بيانات الرواتب والشركات هي معلومات عامة وليست عروض توظيف',
              'نتائج اختبارات الذكاء الاصطناعي هي تقديرات تعليمية وليست تقييمات رسمية',
              'التطبيق قد يتعرض لانقطاعات تقنية أحياناً ونسعى لتقليلها قدر الإمكان',
            ],
          ),

          _PolicySection(
            title: '11. إيقاف الحساب',
            content: 'نحتفظ بحق إيقاف أو حذف أي حساب يثبت أنه:',
            bullets: [
              'يخرق شروط الاستخدام أو سياسة الخصوصية',
              'يستخدم التطبيق بطرق تضر بالمستخدمين الآخرين أو بالنظام',
              'يُبدي محاولات متكررة للتحايل على نظام مكافحة الغش',
            ],
          ),

          _PolicySection(
            title: '12. التواصل معنا',
            content:
                'لأي استفسار بشأن شروط الاستخدام، يُرجى التواصل معنا عبر صفحة "تواصل معنا" في التطبيق، '
                'أو عبر البريد الإلكتروني: edumatesupport@gmail.com\n\n',
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widgets مساعدة (نفس ملف سياسة الخصوصية تماماً)
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

          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                content,
                style: const TextStyle(fontSize: 14, height: 1.7),
              ),
            ),

          ...bullets.map((b) => _BulletItem(text: b)),

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