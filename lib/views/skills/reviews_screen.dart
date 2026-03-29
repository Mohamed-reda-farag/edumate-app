import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../controllers/global_learning_state.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReviewsScreen — شاشة آراء المستخدمين لكورس معين
// يمكن لأي مستخدم مسجل مشاهدة الآراء
// يمكن فقط لمن أكمل الكورس كتابة مراجعة
// ─────────────────────────────────────────────────────────────────────────────
class ReviewsScreen extends StatefulWidget {
  final String fieldId;
  final String skillId;
  final String courseId;
  final String courseTitle;

  const ReviewsScreen({
    super.key,
    required this.fieldId,
    required this.skillId,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  ReviewModel? _myReview;
  bool _loadingMyReview = true;

  @override
  void initState() {
    super.initState();
    _loadMyReview();
  }

  Future<void> _loadMyReview() async {
    final review = await _reviewService.getUserReview(widget.courseId);
    if (mounted) {
      setState(() {
        _myReview = review;
        _loadingMyReview = false;
      });
    }
  }

  bool _isCourseCompleted(GlobalLearningState state) {
    return state
            .getCourseProgress(widget.fieldId, widget.skillId, widget.courseId)
            ?.isCompleted ==
        true;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'آراء المستخدمين',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.courseTitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).appBarTheme.foregroundColor?.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<GlobalLearningState>(
          builder: (context, state, _) {
            final isCompleted = _isCourseCompleted(state);

            return Column(
              children: [
                // قسم مراجعة المستخدم الحالي
                if (!_loadingMyReview)
                  _MyReviewSection(
                    myReview: _myReview,
                    isCompleted: isCompleted,
                    courseId: widget.courseId,
                    onReviewChanged:
                        (review) => setState(() => _myReview = review),
                  ),

                const Divider(height: 1),

                // قائمة جميع المراجعات (Stream)
                Expanded(
                  child: StreamBuilder<List<ReviewModel>>(
                    stream: _reviewService.watchCourseReviews(widget.courseId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allReviews = snapshot.data ?? [];
                      final currentUid = _reviewService.currentUserId;

                      // مراجعات الآخرين فقط (مراجعتي تظهر في قسم منفصل أعلى)
                      final otherReviews =
                          allReviews
                              .where((r) => r.userId != currentUid)
                              .toList();

                      // ── معالجة حالة عدم وجود مراجعات ────────────────────
                      if (otherReviews.isEmpty && _myReview == null) {
                        return _buildEmptyState();
                      }

                      // ── بناء قائمة موحّدة للإحصائيات (بدون تكرار) ────────
                      // نستخدم otherReviews فقط من الـ stream
                      // ونضيف _myReview إذا كانت موجودة وغير موجودة في الـ stream
                      final reviewsForStats = [
                        ...otherReviews,
                        if (_myReview != null &&
                            !otherReviews.any((r) => r.userId == currentUid))
                          _myReview!,
                      ];

                      return Column(
                        children: [
                          _RatingSummary(reviews: reviewsForStats),
                          const Divider(height: 1),
                          Expanded(
                            child:
                                otherReviews.isEmpty
                                    ? _buildOnlyMyReviewState()
                                    : ListView.separated(
                                      padding: const EdgeInsets.only(
                                        bottom: 80,
                                        top: 8,
                                      ),
                                      itemCount: otherReviews.length,
                                      separatorBuilder:
                                          (_, __) => const Divider(
                                            indent: 72,
                                            height: 1,
                                          ),
                                      itemBuilder:
                                          (_, i) => _ReviewCard(
                                            review: otherReviews[i],
                                          ),
                                    ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// يظهر عندما يكون المستخدم الوحيد الذي كتب مراجعة حتى الآن
  Widget _buildOnlyMyReviewState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'كن أول من يُلهم الآخرين!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'مراجعتك موجودة — لا توجد مراجعات أخرى بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد مراجعات بعد',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'كن أول من يشارك رأيه في هذا الكورس!',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// قسم مراجعة المستخدم الحالي
// ─────────────────────────────────────────────────────────────────────────────
class _MyReviewSection extends StatelessWidget {
  final ReviewModel? myReview;
  final bool isCompleted;
  final String courseId;
  final ValueChanged<ReviewModel?> onReviewChanged;

  // instance واحد يُستخدم في جميع عمليات الـ section
  static final _service = ReviewService();

  const _MyReviewSection({
    required this.myReview,
    required this.isCompleted,
    required this.courseId,
    required this.onReviewChanged,
  });

  @override
  Widget build(BuildContext context) {
    // لم يكمل الكورس — عرض رسالة
    if (!isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.grey[500], size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'أكمل الكورس لتتمكن من كتابة مراجعة',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // لديه مراجعة — عرضها مع أزرار تعديل/حذف
    if (myReview != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF6C63FF), size: 18),
                const SizedBox(width: 6),
                const Text(
                  'مراجعتي',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('تعديل'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6C63FF),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _showSheet(context, existing: myReview),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _StarRow(rating: myReview!.rating, size: 18),
            const SizedBox(height: 6),
            Text(
              myReview!.comment,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      );
    }

    // لم يكتب مراجعة بعد
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.rate_review_outlined, size: 18),
          label: const Text('اكتب مراجعتك'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => _showSheet(context),
        ),
      ),
    );
  }

  Future<void> _showSheet(BuildContext context, {ReviewModel? existing}) async {
    final result = await showModalBottomSheet<ReviewModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(courseId: courseId, existing: existing),
    );
    if (result != null) onReviewChanged(result);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('حذف المراجعة'),
              content: const Text(
                'هل أنت متأكد من حذف مراجعتك؟ لا يمكن التراجع.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'حذف',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
    );

    if (confirmed == true && context.mounted) {
      final result = await _service.deleteReview(courseId: courseId);
      if (result.isSuccess) {
        onReviewChanged(null);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف مراجعتك'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet — كتابة / تعديل مراجعة
// ─────────────────────────────────────────────────────────────────────────────
class _WriteReviewSheet extends StatefulWidget {
  final String courseId;
  final ReviewModel? existing;
  const _WriteReviewSheet({required this.courseId, this.existing});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  late double _rating;
  late TextEditingController _ctrl;
  bool _submitting = false;
  String? _errorMsg;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 5.0;
    _ctrl = TextEditingController(text: widget.existing?.comment ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _ctrl.text.trim();
    if (comment.isEmpty) {
      setState(() => _errorMsg = 'يرجى كتابة تعليق');
      return;
    }
    if (comment.length < 10) {
      setState(() => _errorMsg = 'التعليق قصير جداً (10 أحرف على الأقل)');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMsg = null;
    });

    final result =
        _isEditing
            ? await _MyReviewSection._service.updateReview(
              courseId: widget.courseId,
              rating: _rating,
              comment: comment,
            )
            : await _MyReviewSection._service.addReview(
              courseId: widget.courseId,
              rating: _rating,
              comment: comment,
              isCourseCompleted: true,
            );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) {
      Navigator.pop(context, result.review);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? '✅ تم تعديل مراجعتك بنجاح' : '✅ تم نشر مراجعتك بنجاح',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
    } else if (result.isProfanity) {
      // تحذير بارز للألفاظ المسيئة
      await showDialog(
        context: context,
        builder:
            (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 26,
                    ),
                    SizedBox(width: 8),
                    Text('محتوى غير لائق'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تحتوي مراجعتك على ألفاظ مسيئة أو غير لائقة.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سيتم حذف أي مراجعة تحتوي على مثل هذه الكلمات تلقائياً وقد يؤثر ذلك على حسابك.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                    ),
                    child: const Text(
                      'حسناً، سأراجع التعليق',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
      );
    } else {
      setState(() => _errorMsg = result.message ?? 'حدث خطأ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 20,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              _isEditing ? 'تعديل مراجعتك' : 'اكتب مراجعتك',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // النجوم
            const Text(
              'تقييمك:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // التعليق
            const Text(
              'تعليقك:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              maxLength: 500,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'شارك تجربتك مع هذا الكورس...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6C63FF),
                    width: 2,
                  ),
                ),
                errorText: _errorMsg,
              ),
              onChanged: (_) {
                if (_errorMsg != null) setState(() => _errorMsg = null);
              },
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _submitting
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          _isEditing ? 'حفظ التعديل' : 'نشر المراجعة',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ملخص التقييمات + توزيع النجوم
// ─────────────────────────────────────────────────────────────────────────────
class _RatingSummary extends StatelessWidget {
  final List<ReviewModel> reviews;
  const _RatingSummary({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    final avg = reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length;
    final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      dist[r.rating.round()] = (dist[r.rating.round()] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF),
                ),
              ),
              _StarRow(rating: avg, size: 16),
              const SizedBox(height: 4),
              Text(
                '${reviews.length} رأي',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children:
                  [5, 4, 3, 2, 1].map((star) {
                    final count = dist[star] ?? 0;
                    final frac =
                        reviews.isNotEmpty ? count / reviews.length : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text('$star', style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: frac,
                                minHeight: 6,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6C63FF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// بطاقة مراجعة واحدة
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'م';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy', 'ar').format(review.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.12),
            child: Text(
              _initials(review.userName),
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _StarRow(rating: review.rating, size: 14),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  review.comment,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    if (review.isEdited) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(تم التعديل)',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// عرض النجوم (Read-only)
// ─────────────────────────────────────────────────────────────────────────────
class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          half
              ? Icons.star_half_rounded
              : (filled ? Icons.star_rounded : Icons.star_outline_rounded),
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}
