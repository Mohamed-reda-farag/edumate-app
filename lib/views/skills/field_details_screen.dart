import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/global_learning_state.dart';
import '../../models/field_model.dart';

class FieldDetailsScreen extends StatefulWidget {
  final String fieldId;
  const FieldDetailsScreen({super.key, required this.fieldId});

  @override
  State<FieldDetailsScreen> createState() => _FieldDetailsScreenState();
}

class _FieldDetailsScreenState extends State<FieldDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadField());
  }

  Future<void> _loadField() async {
    final state = context.read<GlobalLearningState>();
    if (state.getFieldData(widget.fieldId) == null) {
      await state.loadField(widget.fieldId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Consumer<GlobalLearningState>(
        builder: (context, state, _) {
          final field = state.getFieldData(widget.fieldId);

          if (state.isLoadingStaticData && field == null) {
            return const _LoadingScaffold();
          }

          if (field == null) {
            return _ErrorScaffold(
              onRetry: _loadField,
              fieldId: widget.fieldId,
            );
          }

          return _FieldDetailsContent(
            field: field,
            tabController: _tabController,
            fieldId: widget.fieldId,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Content Scaffold
// ─────────────────────────────────────────────────────────────────────────────
class _FieldDetailsContent extends StatelessWidget {
  final FieldModel field;
  final TabController tabController;
  final String fieldId;

  const _FieldDetailsContent({
    required this.field,
    required this.tabController,
    required this.fieldId,
  });

  int _getProgress(GlobalLearningState state) =>
      state.userProfile?.fieldProgress[fieldId]?.overallProgress ?? 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GlobalLearningState>();
    final progress = _getProgress(state);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context, progress),
          _buildTabBar(),
        ],
        body: TabBarView(
          controller: tabController,
          children: [
            _OverviewTab(field: field, fieldId: fieldId),
            _SalaryTab(field: field),
            _CompaniesTab(field: field),
          ],
        ),
      ),
      bottomNavigationBar: _RoadmapButton(fieldId: fieldId),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, int progress) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: const Color(0xFF6C63FF),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'field_${field.id}',
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            field.icon,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                field.nameEn,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _HeaderChip(
                          icon: Icons.trending_up,
                          label: 'طلب ${field.demandLevel}%',
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(width: 8),
                        _HeaderChip(
                          icon: Icons.access_time,
                          label: field.estimatedDuration,
                          color: Colors.orange.shade300,
                        ),
                        const SizedBox(width: 8),
                        _HeaderChip(
                          icon: Icons.psychology,
                          label: '${field.totalSkills} مهارة',
                          color: Colors.blue.shade300,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('$progress%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.white30,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              minHeight: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: tabController,
          indicatorColor: const Color(0xFF6C63FF),
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'الرواتب'),
            Tab(text: 'الشركات'),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeaderChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Overview
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final FieldModel field;
  final String fieldId;

  const _OverviewTab({
    required this.field,
    required this.fieldId,
  });

  int _getActiveSkills(GlobalLearningState state) =>
      state.getActiveSkills(fieldId: fieldId).length;

  int _getCompletedSkills(GlobalLearningState state) {
    final fp = state.userProfile?.fieldProgress[fieldId];
    if (fp == null) return 0;
    return fp.skillsProgress.values
        .where((s) => s.progressPercentage >= 80)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GlobalLearningState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats Cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.psychology,
                title: 'إجمالي المهارات',
                value: '${field.totalSkills}',
                color: const Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.play_circle,
                title: 'نشطة',
                value: '${_getActiveSkills(state)}',
                color: const Color(0xFF4ECDC4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                title: 'مكتملة',
                value: '${_getCompletedSkills(state)}',
                color: const Color(0xFF2ECC71),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Demand Bar
        _SectionCard(
          title: 'الطلب في سوق العمل',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('نسبة الطلب', style: TextStyle(fontSize: 13)),
                  Text(
                    '${field.demandLevel}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2ECC71),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: field.demandLevel / 100,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2ECC71)),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Description
        _SectionCard(
          title: 'عن المجال',
          child: Text(
            field.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Career Paths
        _SectionCard(
          title: 'المسارات الوظيفية',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: field.careerPaths
                .map(
                  (path) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_left,
                            color: Color(0xFF6C63FF), size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            path,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Salary
// ─────────────────────────────────────────────────────────────────────────────
class _SalaryTab extends StatelessWidget {
  final FieldModel field;
  const _SalaryTab({required this.field});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SalaryCard(
          level: 'مبتدئ',
          salary: field.salaryRange.beginner,
          icon: Icons.school_outlined,
          color: const Color(0xFF4ECDC4),
          description: 'خريج جديد أو أقل من سنتين خبرة',
        ),
        const SizedBox(height: 12),
        _SalaryCard(
          level: 'متوسط',
          salary: field.salaryRange.intermediate,
          icon: Icons.work_outline,
          color: const Color(0xFF6C63FF),
          description: 'من 2 إلى 5 سنوات خبرة',
        ),
        const SizedBox(height: 12),
        _SalaryCard(
          level: 'خبير',
          salary: field.salaryRange.expert,
          icon: Icons.workspace_premium,
          color: const Color(0xFFFFB347),
          description: 'أكثر من 5 سنوات خبرة',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الأرقام تقريبية وقد تختلف حسب الشركة والموقع الجغرافي',
                  style:
                      TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalaryCard extends StatelessWidget {
  final String level;
  final String salary;
  final IconData icon;
  final Color color;
  final String description;

  const _SalaryCard({
    required this.level,
    required this.salary,
    required this.icon,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                salary,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Text('شهرياً',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Companies
// ─────────────────────────────────────────────────────────────────────────────
class _CompaniesTab extends StatelessWidget {
  final FieldModel field;
  const _CompaniesTab({required this.field});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CompaniesSection(
          title: 'الشركات المصرية',
          companies: field.egyptianCompanies,
          icon: Icons.flag_outlined,
          color: const Color(0xFF4ECDC4),
        ),
        const SizedBox(height: 16),
        _CompaniesSection(
          title: 'الشركات العالمية',
          companies: field.globalCompanies,
          icon: Icons.public,
          color: const Color(0xFF6C63FF),
        ),
      ],
    );
  }
}

class _CompaniesSection extends StatelessWidget {
  final String title;
  final List<String> companies;
  final IconData icon;
  final Color color;

  const _CompaniesSection({
    required this.title,
    required this.companies,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: companies
                .map((company) => Chip(
                      label: Text(
                        company,
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                      backgroundColor: color.withOpacity(0.08),
                      side: BorderSide(color: color.withOpacity(0.25)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Roadmap Button
// ─────────────────────────────────────────────────────────────────────────────
class _RoadmapButton extends StatelessWidget {
  final String fieldId;
  const _RoadmapButton({required this.fieldId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/roadmap/$fieldId'),
        icon: const Icon(Icons.map_outlined),
        label: const Text(
          'عرض خريطة التعلم',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TabBar Delegate
// ─────────────────────────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / Error Scaffolds
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF6C63FF)),
            const SizedBox(height: 16),
            Text('جارٍ التحميل...',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final VoidCallback onRetry;
  final String fieldId;
  const _ErrorScaffold({required this.onRetry, required this.fieldId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المجال'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 16),
            const Text('لم يتم العثور على المجال',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}