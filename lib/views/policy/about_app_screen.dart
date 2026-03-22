import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            title: const Text('حول التطبيق'),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroHeader(colorScheme: colorScheme),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // ── ما هو EduMate؟ ──────────────────────────────────
                  _SectionTitle(
                    title: 'ما هو EduMate؟',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _DescCard(
                    isDark: isDark,
                    colorScheme: colorScheme,
                    child: const Text(
                      'EduMate هو رفيقك في رحلة التعلم الهندسي — منصة شاملة تجمع كل ما تحتاجه '
                      'في مكان واحد: من أول خطوة في تعلم مهارة جديدة، وصولاً إلى الاحتراف في '
                      'مجالك، وبناء سيرتك الذاتية والتقدم لوظيفة أحلامك.\n\n'
                      'يساعدك على الوصول من الصفر إلى الاحتراف في 30 مجالاً هندسياً، '
                      'مع نظام متقدم لإدارة الجدول الدراسي، تتبع التقدم، وتحفيز مستمر '
                      'من خلال المهام والإشعارات الذكية.\n\n'
                      'صُمِّم خصيصاً لطلاب الهندسة العرب الذين يريدون التعلم بذكاء، '
                      'وليس فقط بجهد.',
                      style: TextStyle(fontSize: 15, height: 1.8),
                      textDirection: TextDirection.rtl,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── ماذا يقدم لك؟ ────────────────────────────────────
                  _SectionTitle(
                    title: 'ماذا يقدم لك EduMate؟',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),

                  _FeatureCard(
                    colorScheme: colorScheme,
                    isDark: isDark,
                    emoji: '🗺️',
                    color: const Color(0xFF1565C0),
                    title: 'خرائط تعلم تفاعلية',
                    description:
                        '30 مجالاً هندسياً كاملاً — من برمجة التطبيقات وأمن المعلومات '
                        'والذكاء الاصطناعي حتى الشبكات والأنظمة المدمجة. '
                        'كل مجال فيه خريطة مهارات تفاعلية تُريك بدقة: أين أنت الآن وإلى أين ستصل.',
                  ),

                  _FeatureCard(
                    colorScheme: colorScheme,
                    isDark: isDark,
                    emoji: '🎓',
                    color: const Color(0xFF6A1B9A),
                    title: 'آلاف الكورسات المجانية',
                    description:
                        'نجمع لك أفضل الكورسات من YouTube وUdemy وCoursera في مكان واحد '
                        'مع التقييمات والمدة وعدد المتعلمين — تختار ما يناسبك وتبدأ فوراً.',
                  ),

                  _FeatureCard(
                    colorScheme: colorScheme,
                    isDark: isDark,
                    emoji: '🤖',
                    color: const Color(0xFF00695C),
                    title: 'اختبارات ذكاء اصطناعي',
                    description:
                        'بعد كل مهارة، يتحدث معك نموذج Gemini AI في اختبار تفاعلي '
                        'يقيس فهمك الحقيقي — ليس حفظاً، بل فهماً واستيعاباً.',
                  ),

                  _FeatureCard(
                    colorScheme: colorScheme,
                    isDark: isDark,
                    emoji: '📅',
                    color: const Color(0xFFE65100),
                    title: 'جدول ذكي لمذاكرتك',
                    description:
                        'سجّل جدول محاضراتك وحضورك، وسيولّد التطبيق لك تلقائياً '
                        'خطة مذاكرة أسبوعية مبنية على أولويات مواد كل أسبوع.',
                  ),

                  _FeatureCard(
                    colorScheme: colorScheme,
                    isDark: isDark,
                    emoji: '📄',
                    color: const Color(0xFF558B2F),
                    title: 'مُنشئ سيرة ذاتية احترافية',
                    description:
                        'أنشئ سيرتك الذاتية داخل التطبيق خطوةً بخطوة — من البيانات الشخصية '
                        'والملخص المهني، مروراً بالخبرات والمشاريع والمهارات، وصولاً إلى الشهادات واللغات. '
                        'صدّرها كـ PDF جاهز للتقديم، متوافق مع نظام ATS الذي تستخدمه الشركات الكبرى لفرز المتقدمين.',
                  ),

                  _FeatureCard(
                    colorScheme: colorScheme,
                    isDark: isDark,
                    emoji: '🏆',
                    color: const Color(0xFFC62828),
                    title: 'نظام نقاط وإنجازات',
                    description:
                        'كل درس تُكمله، كل حضور تسجّله، كل مهارة تتقنها — '
                        'تحصل على نقاط وتفتح إنجازات جديدة. التعلم يجب أن يكون ممتعاً.',
                  ),

                  _FeatureCard(
                    colorScheme: colorScheme,
                    isDark: isDark,
                    emoji: '🔔',
                    color: const Color(0xFF00838F),
                    title: 'إشعارات ذكية ومخصصة',
                    description:
                        'يرسل لك التطبيق إشعارات مبنية على تفضيلاتك وأوقات تعلمك المفضلة — '
                        'تذكيرات بالمهام، تحفيز على الاستمرار، وتنبيهات بالمحاضرات القادمة.',
                  ),

                  _FeatureCard(
                    colorScheme: colorScheme,
                    isDark: isDark,
                    emoji: '📶',
                    color: const Color(0xFF4527A0),
                    title: 'دعم Offline ومزامنة فورية',
                    description:
                        'يعمل التطبيق بكفاءة حتى بدون إنترنت بفضل Cache الذكي، '
                        'وعند الاتصال تُزامَن بياناتك فوراً مع Firebase في الوقت الحقيقي.',
                  ),

                  const SizedBox(height: 28),

                  // ── مُنشئ السيرة الذاتية — تفاصيل ──────────────────────
                  _SectionTitle(
                    title: 'مُنشئ السيرة الذاتية — ماذا يشمل؟',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _CvStepsCard(colorScheme: colorScheme, isDark: isDark),

                  const SizedBox(height: 28),

                  // ── مبدأ التطبيق ─────────────────────────────────────
                  _SectionTitle(
                    title: 'مبدأنا في مكافحة الغش',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _DescCard(
                    isDark: isDark,
                    colorScheme: colorScheme,
                    accentColor: const Color(0xFF1565C0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'التطبيق لا يسمح بتسجيل إكمال درس إلا بعد مرور الوقت الفعلي للمشاهدة. '
                            'نحن نؤمن أن القيمة الحقيقية هي في التعلم الفعلي، '
                            'وليس في مجرد الأرقام والإحصائيات.',
                            style: TextStyle(fontSize: 14, height: 1.7),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── إحصائيات سريعة ──────────────────────────────────
                  _SectionTitle(title: 'بالأرقام', colorScheme: colorScheme),
                  const SizedBox(height: 16),
                  _StatsRow(colorScheme: colorScheme, isDark: isDark),

                  const SizedBox(height: 28),

                  // ── لمن هذا التطبيق؟ ────────────────────────────────
                  _SectionTitle(
                    title: 'لمن هذا التطبيق؟',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _AudienceChips(colorScheme: colorScheme),

                  const SizedBox(height: 32),

                  // ── Footer ───────────────────────────────────────────
                  _Footer(colorScheme: colorScheme, isDark: isDark),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Hero Header
// ═════════════════════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  final ColorScheme colorScheme;

  const _HeroHeader({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.85),
            colorScheme.tertiary.withOpacity(0.9),
          ],
        ),
      ),
      child: Stack(
        children: [
          // دوائر زخرفية خلفية
          Positioned(
            top: -30,
            left: -30,
            child: _Circle(size: 160, opacity: 0.07),
          ),
          Positioned(
            bottom: -20,
            right: -20,
            child: _Circle(size: 120, opacity: 0.1),
          ),
          Positioned(
            top: 60,
            right: 40,
            child: _Circle(size: 60, opacity: 0.08),
          ),

          // المحتوى
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Text('⚙️', style: TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EduMate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'المنصة التعليمية الهندسية',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF69F0AE),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'الإصدار 1.0.0  •  مجاني بالكامل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;

  const _Circle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Section Title
// ═════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;

  const _SectionTitle({required this.title, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Desc Card (للنصوص الوصفية العامة)
// ═════════════════════════════════════════════════════════════════════════════

class _DescCard extends StatelessWidget {
  final Widget child;
  final ColorScheme colorScheme;
  final bool isDark;
  final Color? accentColor;

  const _DescCard({
    required this.child,
    required this.colorScheme,
    required this.isDark,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (accentColor ?? colorScheme.primary).withOpacity(0.15),
        ),
      ),
      child: child,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Feature Card
// ═════════════════════════════════════════════════════════════════════════════

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final ColorScheme colorScheme;
  final bool isDark;

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط اللون الجانبي + الإيموجي
            Container(
              width: 58,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [Text(emoji, style: const TextStyle(fontSize: 26))],
              ),
            ),
            // النص
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.65,
                        color: colorScheme.onSurface.withOpacity(0.75),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CV Steps Card — خطوات مُنشئ السيرة الذاتية
// ═════════════════════════════════════════════════════════════════════════════

class _CvStepsCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isDark;

  const _CvStepsCard({required this.colorScheme, required this.isDark});

  static const _steps = [
    ('🌐', 'اختيار اللغة', 'عربي أو إنجليزي — مع نصيحة ATS توضح الفرق'),
    ('👤', 'البيانات الشخصية', 'الاسم، التواصل، LinkedIn، GitHub، Portfolio'),
    ('📝', 'الملخص المهني', 'قوالب جاهزة بأسلوب ATS + نصائح تفاعلية'),
    ('💼', 'الخبرات العملية', 'بطاقات قابلة للسحب وإعادة الترتيب مع Bullet Points'),
    ('🎓', 'التعليم', 'الجامعة، التخصص، GPA، والإنجازات الأكاديمية'),
    ('⚡', 'المهارات', 'مصنّفة تلقائياً لأفضل قراءة من نظام ATS'),
    ('🚀', 'المشاريع', 'Chips للتقنيات المستخدمة + رابط GitHub'),
    ('📜', 'الشهادات واللغات', 'الدورات، الاعتمادات، ومستويات إتقان اللغات'),
  ];

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF558B2F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ATS badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined, size: 14, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  'متوافق مع نظام ATS • يُصدَّر كـ PDF احترافي',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == _steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العمود الأيسر: الرقم + الخط الرابط
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withOpacity(0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$index',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 32,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: accentColor.withOpacity(0.2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // المحتوى
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              step.$1,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              step.$2,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.$3,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Stats Row
// ═════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isDark;

  const _StatsRow({required this.colorScheme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          value: '30',
          label: 'مجالاً هندسياً',
          emoji: '🏗️',
          colorScheme: colorScheme,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _StatBox(
          value: 'آلاف',
          label: 'الكورسات المجانية',
          emoji: '🎓',
          colorScheme: colorScheme,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _StatBox(
          value: '100%',
          label: 'مجاني',
          emoji: '🎁',
          colorScheme: colorScheme,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;
  final ColorScheme colorScheme;
  final bool isDark;

  const _StatBox({
    required this.value,
    required this.label,
    required this.emoji,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color:
              isDark
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.primaryContainer.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Audience Chips
// ═════════════════════════════════════════════════════════════════════════════

class _AudienceChips extends StatelessWidget {
  final ColorScheme colorScheme;

  const _AudienceChips({required this.colorScheme});

  static const _items = [
    ('👨‍🎓', 'طلاب الجامعة'),
    ('🔰', 'المبتدئون'),
    ('💼', 'طالبو التوظيف'),
    ('📈', 'المطورون'),
    ('🏫', 'طلاب الثانوية'),
    ('🔄', 'المحولون لمجال جديد'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          _items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.$1, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Footer
// ═════════════════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isDark;

  const _Footer({required this.colorScheme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(isDark ? 0.2 : 0.08),
            colorScheme.tertiary.withOpacity(isDark ? 0.15 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text('🚀', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            'صُنع بشغف لطلاب الهندسة العرب',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'نسعى لجعل التعلم الهندسي أكثر وضوحاً،\nأكثر تنظيماً، وأكثر متعةً.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: colorScheme.primary.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text(
            'الإصدار 1.0.0',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}