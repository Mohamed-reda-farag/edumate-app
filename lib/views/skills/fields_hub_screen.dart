import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/global_learning_state.dart';
import 'my_fields_screen.dart';
import 'active_skills_screen.dart';
import 'active_courses_screen.dart';
import '../../router.dart';

/// 🎯 شاشة Hub المركزية للمجالات والمهارات والكورسات
class FieldsHubScreen extends StatefulWidget {
  final int initialTab;

  const FieldsHubScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<FieldsHubScreen> createState() => _FieldsHubScreenState();
}

class _FieldsHubScreenState extends State<FieldsHubScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.clamp(0, 2);
    _pageController = PageController(initialPage: _currentIndex);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _currentIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_currentIndex != _tabController.index) {
        setState(() => _currentIndex = _tabController.index);
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      _tabController.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: [
            _TabWrapper(child: MyFieldsContent()),
            _TabWrapper(child: ActiveSkillsContent(key: _skillsKey)),
            _TabWrapper(child: ActiveCoursesContent(key: _coursesKey)),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF6C63FF),
      title: null,
      titleSpacing: 0,
      actions: _buildActions(),
      // ✅ TabBar موضوعة في bottom الخاص بـ AppBar — هذا هو المكان الصحيح
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kTextTabBarHeight + 20),
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Consumer<GlobalLearningState>(
      builder: (context, state, _) {
        final activeSkillsCount = state.getActiveSkills().length;
        final activeCoursesCount = state.getActiveCourses().length;

        return TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 2.5,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          tabs: [
            const Tab(
              icon: Icon(Icons.map_outlined, size: 18),
              iconMargin: EdgeInsets.only(bottom: 2),
              text: 'مجالاتي',
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology_outlined, size: 18),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('المهارات'),
                      if (activeSkillsCount > 0) ...[
                        const SizedBox(width: 4),
                        _buildTabBadge(activeSkillsCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined, size: 18),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('الكورسات'),
                      if (activeCoursesCount > 0) ...[
                        const SizedBox(width: 4),
                        _buildTabBadge(activeCoursesCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // مفاتيح للوصول إلى state الشاشات الفرعية
  final GlobalKey<ActiveSkillsContentState> _skillsKey = GlobalKey();
  final GlobalKey<ActiveCoursesContentState> _coursesKey = GlobalKey();

  List<Widget> _buildActions() {
    switch (_currentIndex) {
      case 0:
        return [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showSystemInfo,
            tooltip: 'معلومات النظام',
          ),
        ];
      case 1:
        return [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () => _skillsKey.currentState?.showSortOptions(),
            tooltip: 'ترتيب',
          ),
        ];
      case 2:
        return [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () => _coursesKey.currentState?.showSortOptions(),
            tooltip: 'ترتيب',
          ),
        ];
      default:
        return [];
    }
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => AppNavigation.goToLearnedSkills(),
          icon: const Icon(Icons.check_circle),
          label: const Text('المهارات المتعلمة'),
          backgroundColor: Colors.green,
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: () => AppNavigation.goToCompletedCourses(),
          icon: const Icon(Icons.check_circle),
          label: const Text('الكورسات المكتملة'),
          backgroundColor: Colors.green,
        );
      default:
        return null;
    }
  }

  void _showSystemInfo() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Color(0xFF6C63FF)),
              SizedBox(width: 8),
              Text('نظام المجالات'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '📚 كيف يعمل النظام؟',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  '• اختر مجالاً واحداً أو أكثر للتخصص فيه\n'
                  '• كل مجال يحتوي على مهارات متدرجة\n'
                  '• كل مهارة تحتوي على كورسات تعليمية\n'
                  '• تابع تقدمك في كل مجال ومهارة\n'
                  '• أكمل الكورسات لتحسين نسبة إتقانك',
                  style: TextStyle(height: 1.6),
                ),
                SizedBox(height: 16),
                Text(
                  '🎯 نصائح للنجاح:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  '• ركّز على مهارة واحدة في كل مرة\n'
                  '• خصص وقتاً يومياً للتعلم\n'
                  '• طبّق ما تتعلمه عملياً\n'
                  '• راجع المواد بشكل دوري',
                  style: TextStyle(height: 1.6),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('فهمت'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab Wrapper للحفاظ على حالة كل تبويب
// ═══════════════════════════════════════════════════════════════════════════
class _TabWrapper extends StatefulWidget {
  final Widget child;
  const _TabWrapper({required this.child});

  @override
  State<_TabWrapper> createState() => _TabWrapperState();
}

class _TabWrapperState extends State<_TabWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Content Widgets
// ═══════════════════════════════════════════════════════════════════════════

class MyFieldsContent extends StatelessWidget {
  const MyFieldsContent({super.key});
  @override
  Widget build(BuildContext context) => const MyFieldsScreen(embedded: true);
}

class ActiveSkillsContent extends StatefulWidget {
  const ActiveSkillsContent({super.key});

  @override
  State<ActiveSkillsContent> createState() => ActiveSkillsContentState();
}

class ActiveSkillsContentState extends State<ActiveSkillsContent> {
  final _key = GlobalKey<ActiveSkillsScreenState>();

  void showSortOptions() => _key.currentState?.showSortOptions();

  @override
  Widget build(BuildContext context) =>
      ActiveSkillsScreen(key: _key, embedded: true);
}

class ActiveCoursesContent extends StatefulWidget {
  const ActiveCoursesContent({super.key});

  @override
  State<ActiveCoursesContent> createState() => ActiveCoursesContentState();
}

class ActiveCoursesContentState extends State<ActiveCoursesContent> {
  final _key = GlobalKey<ActiveCoursesScreenState>();

  void showSortOptions() => _key.currentState?.showSortOptions();

  @override
  Widget build(BuildContext context) =>
      ActiveCoursesScreen(key: _key, embedded: true);
}