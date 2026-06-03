import 'dart:async';
import 'dart:io' show Directory, File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/fine_service.dart';
import '../../../core/services/razorpay_checkout.dart' as razorpay_web;
import '../../../config/routes.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/student_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../widgets/common/amber_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';
import '../../widgets/common/drill_down_icon_button.dart';

class CartScreen extends ConsumerStatefulWidget {
  final bool isStandalone;

  const CartScreen({super.key, this.isStandalone = false});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  // Mobile background — matches desktop scaffold
  static const Color _bg = Color(0xFFF1F5F9);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFE8E7E4);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMedium = Color(0xFF6B6B6B);
  static const Color _textLight = Color(0xFF6B6B6B);

  Razorpay? _razorpay;
  bool _isProcessing = false;
  /// Local loading overlay — replaces showDialog so it auto-clears when widget disposes.
  bool _isPaymentLoading = false;
  String? _loadingMessage; // null = just spinner, non-null = spinner + text
  int? _currentPayId;
  int? _currentCarId;
  String? _currentOrderId;
  List<FeeModel>? _currentPaymentItems;
  /// Fine per dem_id for current payment (keyed by dem_id).
  Map<int, double> _currentFineMap = {};
  /// Captured before opening Razorpay so callbacks can clean up even after widget disposal.
  SupabaseClient? _capturedClient;

  @override
  void initState() {
    super.initState();
    // razorpay_flutter only works on mobile (Android/iOS), not on web
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    final scaffold = DesktopDetailScaffold(
      isNested: true,
      header: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeader(context, ref, cartState),
          const SizedBox(height: 16),
        ],
      ),
      toolbar: Row(
        children: [
          const Expanded(child: BreadcrumbBar(currentLabel: 'Payment Summary')),
          if (cartState.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _showClearCartDialog(context, ref),
                icon: const AppIcon('trash', size: 18),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ),
        ],
      ),
      body: cartState.isEmpty
          ? _buildEmptyState(context)
          : _buildCartContent(context, ref, cartState),
      bottomBar: cartState.isNotEmpty
          ? _buildBottomBar(context, ref, cartState)
          : null,
    );

    // Local loading overlay — lives inside this widget so it auto-clears on dispose,
    // preventing the orphaned global-dialog spinner bug when navigating away.
    if (!_isPaymentLoading) return scaffold;

    return Stack(
      children: [
        scaffold,
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: _loadingMessage != null ? Colors.white : AppColors.primary,
                  ),
                  if (_loadingMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _loadingMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, CartState cartState) {
    final isMobile = !context.isDesktop;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button - Dark theme
          DrillDownIconButton(
            svgPath: 'assets/icons/arrow-left.svg',
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.home);
              }
            },
          ),

          // Title
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Payment Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isMobile ? _textDark : AppColors.textPrimaryC(context),
                  letterSpacing: -0.3,
                ),
              ),
              if (cartState.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '${cartState.items.length} item${cartState.items.length > 1 ? 's' : ''} selected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isMobile ? _textMedium : AppColors.textSecondaryC(context),
                  ),
                ),
              ],
            ],
          ),

          // Clear All Button or Placeholder
          if (cartState.isNotEmpty)
            GestureDetector(
              onTap: () => _showClearCartDialog(context, ref),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AppIcon(
                    'trash',
                    size: 20,
                    color: AppColors.error,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Clear Queue?'),
        content: const Text('Are you sure you want to remove all items from your queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isMobile = !context.isDesktop;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isMobile ? _bg : AppColors.filterBg(context),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon('shopping-cart', size: 48, color: isMobile ? _textLight : AppColors.textHintC(context)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Queue is Empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isMobile ? _textDark : AppColors.textPrimaryC(context),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Select fees from the pending section to add them to your queue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isMobile ? _textMedium : AppColors.textSecondaryC(context),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => context.go(Routes.home),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon('home-2', size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Go to Home',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildDesktopGreetingBanner(
      BuildContext context, CartState cartState) {
    final count = cartState.itemCount;
    final hasItems = count > 0;
    final message = hasItems
        ? "$count ${count == 1 ? 'fee' : 'fees'} ready to pay — review and check out below."
        : 'Your payment queue is empty.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD2913C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTitle(BuildContext context, WidgetRef ref) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final firstName =
        selectedStudent?.name.trim().split(' ').first ?? 'Student';
    final admissionNo = selectedStudent?.admissionNumber ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$firstName's Payment Queue",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryC(context),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ID $admissionNo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textHintC(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStatCards(BuildContext context, CartState cartState) {
    final items = cartState.items;
    final total = items.fold<double>(0, (sum, f) => sum + f.totalAmount);
    final categories = items.map((f) {
      final t = f.demfeetype.toLowerCase();
      if (t.contains('bus') || t.contains('transport') || t.contains('van')) {
        return 'bus';
      }
      if (t.contains('tuition')) return 'tuition';
      if (t.contains('hostel')) return 'hostel';
      if (t.contains('exam')) return 'exam';
      return f.demfeeterm;
    }).toSet().length;
    return Row(
      children: [
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Total to Pay',
            value: '₹${NumberFormat('#,##,###').format(total.toInt())}',
            icon: 'wallet-3',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Items in Queue',
            value: '${items.length}',
            icon: 'shopping-cart',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Categories',
            value: '$categories',
            icon: 'task-square',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Avg. per Item',
            value: items.isEmpty
                ? '—'
                : '₹${NumberFormat('#,##,###').format((total / items.length).toInt())}',
            icon: 'receipt-text',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardTile({
    required BuildContext context,
    required String label,
    required String value,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFD2913C),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryC(context),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, WidgetRef ref, CartState cartState) {
    // Group fees by category type
    final Map<String, List<FeeModel>> feesByCategory = {};

    for (final fee in cartState.items) {
      String category;
      if (_isBusFee(fee.demfeetype)) {
        category = 'Bus Fees';
      } else if (_isTuitionFee(fee.demfeetype)) {
        category = 'Tuition Fees';
      } else if (_isHostelFee(fee.demfeetype)) {
        category = 'Hostel Fees';
      } else if (_isExamFee(fee)) {
        category = 'Exam Fees';
      } else {
        category = '${fee.demfeeterm} (${fee.demfeeyear})';
      }
      feesByCategory.putIfAbsent(category, () => []);
      feesByCategory[category]!.add(fee);
    }

    // Sort categories: Term fees first, then Tuition, Hostel, Bus
    final sortedCategories = feesByCategory.keys.toList()
      ..sort((a, b) {
        // Define category order: regular terms first, then special categories
        int getCategoryOrder(String cat) {
          if (cat == 'Tuition Fees') return 100;
          if (cat == 'Hostel Fees') return 101;
          if (cat == 'Exam Fees') return 102;
          if (cat == 'Bus Fees') return 103;
          return 0; // Term fees first
        }
        final orderA = getCategoryOrder(a);
        final orderB = getCategoryOrder(b);
        if (orderA != orderB) return orderA.compareTo(orderB);
        return a.compareTo(b);
      });

    return ListView(
      padding: context.isDesktop ? const EdgeInsets.all(24) : const EdgeInsets.all(16),
      children: [
        // Dashboard-style header (desktop only)
        if (context.isDesktop) ...[
          _buildDesktopGreetingBanner(context, cartState),
          const SizedBox(height: 18),
          _buildDesktopTitle(context, ref),
          const SizedBox(height: 20),
          _buildDesktopStatCards(context, cartState),
          const SizedBox(height: 20),
        ],

        // Fee Category Cards (sequential: can only remove last term first, backward order)
        ...sortedCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final fees = feesByCategory[category]!;
          // Check if this category can be removed (no later categories in cart)
          // Only enforce sequential removal for term categories (order < 100)
          int getCatOrder(String cat) {
            if (cat == 'Tuition Fees') return 100;
            if (cat == 'Hostel Fees') return 101;
            if (cat == 'Exam Fees') return 102;
            if (cat == 'Bus Fees') return 103;
            return 0; // Term fees
          }
          final isTermCategory = getCatOrder(category) == 0;
          // For term categories: can only remove if no later term categories exist
          final noLaterTerms = !sortedCategories.skip(index + 1).any((c) => getCatOrder(c) == 0);
          final canRemove = !isTermCategory || noLaterTerms;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCategoryCard(context, ref, category, fees, canRemove: canRemove),
          );
        }),

        const SizedBox(height: 24), // Space for bottom bar
      ],
    );
  }

  bool _isBusFee(String feeType) {
    final lowerType = feeType.toLowerCase();
    return lowerType.contains('bus') || lowerType.contains('transport') || lowerType.contains('van');
  }

  bool _isTuitionFee(String feeType) {
    final lowerType = feeType.toLowerCase();
    return lowerType.contains('tuition');
  }

  bool _isHostelFee(String feeType) {
    final lowerType = feeType.toLowerCase();
    return lowerType.contains('hostel');
  }

  bool _isExamFee(FeeModel fee) {
    final lowerType = fee.demfeetype.toLowerCase();
    final lowerGroup = fee.feeGroupName.toLowerCase();
    return lowerType.contains('exam') || lowerGroup.contains('exam');
  }

  Map<String, dynamic> _getCategoryStyle(String category) {
    if (category == 'Bus Fees') {
      return {
        'color': const Color(0xFFF59E0B),
        'svgPath': 'assets/school Icons/van.svg',
        'showMonth': true,
      };
    } else if (category == 'Tuition Fees') {
      return {
        'color': const Color(0xFF8B5CF6),
        'svgPath': 'assets/school Icons/school.svg',
        'showMonth': true,
      };
    } else if (category == 'Hostel Fees') {
      return {
        'color': const Color(0xFF3B82F6),
        'svgPath': 'assets/school Icons/school.svg',
        'showMonth': true,
      };
    } else if (category == 'Exam Fees') {
      return {
        'color': const Color(0xFF06B6D4),
        'svgPath': 'assets/school Icons/exam.svg',
        'showMonth': false,
      };
    } else {
      return {
        'color': AppColors.success,
        'svgPath': 'assets/school Icons/school.svg',
        'showMonth': false,
      };
    }
  }

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, String category, List<FeeModel> fees, {bool canRemove = true}) {
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final categoryStyle = _getCategoryStyle(category);
    final svgPath = categoryStyle['svgPath'] as String;

    final isMobile = !context.isDesktop;
    return Container(
      decoration: BoxDecoration(
        color: isMobile ? _cardBg : AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 12),
        border: isMobile ? null : Border.all(color: AppColors.borderC(context)),
        boxShadow: isMobile
            ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 8))]
            : AppColors.cardShadow(context),
      ),
      child: Column(
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: categoryStyle['color'] as Color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        svgPath,
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Items count
                Text(
                  '${fees.length} item${fees.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isMobile ? _textMedium : AppColors.textSecondaryC(context),
                  ),
                ),
                const SizedBox(width: 12),
                // Remove Button
                GestureDetector(
                  onTap: canRemove ? () => _showRemoveGroupDialog(context, ref, category, fees) : null,
                  child: Opacity(
                    opacity: canRemove ? 1.0 : 0.3,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const AppIcon(
                        'close-circle',
                        size: 16,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: isMobile ? const Color(0xFFF0F0F0) : AppColors.borderC(context)),

          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Particular',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isMobile ? _textDark : AppColors.textPrimaryC(context),
                    ),
                  ),
                ),
                Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isMobile ? _textDark : AppColors.textPrimaryC(context),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: isMobile ? const Color(0xFFF0F0F0) : AppColors.borderC(context)),

          // Fee Items
          ...fees.map((fee) => _buildFeeItem(fee, categoryStyle['showMonth'] as bool)),

          // Total Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMobile ? _bg : AppColors.filterBg(context),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(isMobile ? 20 : 12),
                bottomRight: Radius.circular(isMobile ? 20 : 12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isMobile ? _textDark : AppColors.textPrimaryC(context),
                  ),
                ),
                Text(
                  '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isMobile ? _textDark : AppColors.textPrimaryC(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveGroupDialog(BuildContext context, WidgetRef ref, String category, List<FeeModel> fees) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Remove Group?'),
        content: Text('Remove all ${fees.length} item${fees.length > 1 ? 's' : ''} from $category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              for (final fee in fees) {
                ref.read(cartProvider.notifier).removeFee(fee.id);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$category removed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(FeeModel fee, bool showMonth) {
    final isMobile = !context.isDesktop;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: isMobile ? const Color(0xFFF0F0F0) : AppColors.borderC(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.feeTypeName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isMobile ? _textDark : AppColors.textPrimaryC(context),
                    height: 1.4,
                  ),
                ),
                if (showMonth) ...[
                  const SizedBox(height: 2),
                  Text(
                    _extractMonthFromDate(fee),
                    style: TextStyle(
                      fontSize: 12,
                      color: isMobile ? _textLight : AppColors.textHintC(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isMobile ? _textDark : AppColors.textPrimaryC(context),
            ),
          ),
        ],
      ),
    );
  }

  String _extractMonthFromDate(FeeModel fee) {
    final date = fee.duedate ?? fee.createdat;
    return DateFormat('MMMM yyyy').format(date);
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, CartState cartState) {
    final isMobile = !context.isDesktop;
    final bottomContent = Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 13,
                  color: isMobile ? _textMedium : AppColors.textSecondaryC(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹ ${NumberFormat('#,##,###').format(cartState.totalAmount.toInt())}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isMobile ? _textDark : AppColors.textPrimaryC(context),
                ),
              ),
            ],
          ),
          AmberButton(
            label: 'Pay Now',
            icon: 'arrow-right-1',
            height: 52,
            fullWidth: false,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            onPressed: () => _handleProceedToPayment(),
          ),
        ],
      ),
    );

    // On desktop, DesktopDetailScaffold wraps in a card — return just the inner content
    if (context.isDesktop) return bottomContent;

    // On mobile, soft rounded decoration
    return Container(
      decoration: const BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: bottomContent,
      ),
    );
  }

  Future<void> _handleProceedToPayment() async {
    if (_isProcessing) return;

    final cartState = ref.read(cartProvider);
    final student = ref.read(selectedStudentProvider);
    if (cartState.isEmpty || student == null) return;

    // Block duplicate online attempts while a recent 'I' row exists for this
    // student. Sweep clears orphans only after 5 minutes; within that window
    // we warn the user instead of creating another pending row (matches admin).
    if (await _checkPendingPaymentBlock(student.insId, student.stuId)) return;

    // Calculate fines for overdue items (matches admin's client-side fine calc)
    final rules = await FineService.loadRules(student.insId);
    final fineMap = <int, double>{};
    double totalFine = 0;
    for (final fee in cartState.items) {
      final fine = FineService.calculateFine(
        demfeetype: fee.demfeetype,
        dueDate: fee.dueDate,
        feeAmount: fee.balancedue,
        rules: rules,
      );
      if (fine > 0) {
        fineMap[fee.demId] = fine;
        totalFine += fine;
      }
    }

    if (totalFine > 0) {
      final confirmed = await _showFineConfirmationDialog(
        fineMap: fineMap,
        items: cartState.items,
        baseTotal: cartState.totalAmount,
        totalFine: totalFine,
      );
      if (confirmed != true) return; // User cancelled
    }

    _currentFineMap = fineMap;
    final grandTotal = cartState.totalAmount + totalFine;

    setState(() {
      _isProcessing = true;
      _isPaymentLoading = true;  // Show local overlay (auto-clears if widget disposes)
    });

    try {
      // Step 1: Save cart to database
      debugPrint('PAYMENT STEP 1: Saving cart to database...');
      final carId = await saveCartToDatabase(
        ref: ref,
        items: cartState.items,
        studentId: student.stuId,
      );

      if (carId == null) {
        debugPrint('PAYMENT STEP 1 FAILED: carId is null. Error: $lastCartSaveError');
        if (mounted) setState(() => _isPaymentLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save cart: ${lastCartSaveError ?? "Unknown error"}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      debugPrint('PAYMENT STEP 1 OK: carId=$carId');

      // Step 2: Initiate payment
      debugPrint('PAYMENT STEP 2: Initiating payment...');
      final payId = await initiatePayment(
        ref: ref,
        carId: carId,
        cartItems: cartState.items,
        cartTotal: cartState.totalAmount,
      );

      if (payId == null) {
        debugPrint('PAYMENT STEP 2 FAILED: payId is null. Error: $lastPaymentError');
        if (mounted) setState(() => _isPaymentLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initiate payment: ${lastPaymentError ?? "Unknown error"}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      debugPrint('PAYMENT STEP 2 OK: payId=$payId');

      // Step 3: Create Razorpay order via Edge Function (include fines in total)
      final amountInPaise = (grandTotal * 100).toInt();
      debugPrint('PAYMENT STEP 3: Creating Razorpay order (amount=$amountInPaise paise)...');

      final orderId = await createRazorpayOrder(
        ref: ref,
        payId: payId,
        amountInPaise: amountInPaise,
        receipt: 'PAY-$payId',
      );

      if (orderId == null) {
        debugPrint('PAYMENT STEP 3 FAILED: orderId is null. Error: $lastOrderCreationError');
        // Roll back payment since we can't proceed without an order
        await handlePaymentFailure(
          ref: ref,
          payId: payId,
          carId: carId,
          attemptedDemIds: _currentFineMap.keys.toList(),
        );
        if (mounted) setState(() => _isPaymentLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create payment order: ${lastOrderCreationError ?? "Unknown error"}. Please try again.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      debugPrint('PAYMENT STEP 3 OK: orderId=$orderId');

      // Store payment info for callbacks (captured before Razorpay opens
      // so cleanup can happen even if the widget is disposed when callback fires)
      _currentPayId = payId;
      _currentCarId = carId;
      _currentOrderId = orderId;
      _currentPaymentItems = List.from(cartState.items);
      _capturedClient = ref.read(supabaseClientProvider);

      // Hide loading overlay before opening Razorpay
      if (mounted) setState(() => _isPaymentLoading = false);

      // Step 4: Open Razorpay checkout with order_id
      debugPrint('PAYMENT STEP 4: Opening Razorpay checkout (kIsWeb=$kIsWeb)...');
      final checkoutOptions = {
        'key': 'rzp_test_RQsgJgVFwM7kov',
        'amount': amountInPaise,
        'currency': 'INR',
        'name': 'Krishnasamy Institution',
        'description': 'School Fees Payment',
        'order_id': orderId,
        'prefill': {
          'name': student.stuname,
          'contact': student.stumobile,
          'email': student.stuemail ?? '',
        },
        'theme': {
          'color': '#1A73E8',
        },
        'notes': {
          'pay_id': payId.toString(),
          'car_id': carId.toString(),
          'student_id': student.stuId.toString(),
        },
      };

      if (kIsWeb) {
        // Use JavaScript SDK directly on web
        razorpay_web.openRazorpayWebCheckout(
          options: checkoutOptions,
          onSuccess: (paymentId) {
            debugPrint('Razorpay Web Payment Success: $paymentId');
            _handleWebPaymentSuccess(paymentId);
          },
          onError: (code, description) {
            debugPrint('Razorpay Web Payment Error: $code - $description');
            _handleWebPaymentError(code, description);
          },
        );
      } else if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        // Desktop: open Razorpay in browser + poll for status
        await _openDesktopRazorpayCheckout(
          payId: payId,
          carId: carId,
          orderId: orderId,
          amountInPaise: amountInPaise,
          student: student,
          items: cartState.items,
        );
      } else {
        // Use razorpay_flutter on mobile (Android/iOS)
        _razorpay!.open(checkoutOptions);
      }
      debugPrint('PAYMENT STEP 4: Razorpay checkout opened successfully');
    } catch (e, stackTrace) {
      debugPrint('PAYMENT ERROR: $e');
      debugPrint('PAYMENT STACK: $stackTrace');
      if (mounted) {
        setState(() => _isPaymentLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Handles web Razorpay payment success (called from JS interop callback)
  void _handleWebPaymentSuccess(String paymentId) async {
    _handlePaymentSuccessCore(paymentId);
  }

  /// Handles web Razorpay payment error (called from JS interop callback)
  void _handleWebPaymentError(int code, String description) async {
    debugPrint('Web Payment Error: $code - $description');

    final payId = _currentPayId;
    final carId = _currentCarId;
    final client = _capturedClient;

    // Clear state immediately to prevent duplicate handling
    _currentPayId = null;
    _currentCarId = null;
    _currentOrderId = null;
    _currentPaymentItems = null;
    _capturedClient = null;

    if (payId != null && carId != null) {
      if (mounted) {
        // Widget is still alive — use ref-based cleanup (refreshes providers too)
        try {
          await handlePaymentFailure(
            ref: ref,
            payId: payId,
            carId: carId,
            errorReason: description,
            attemptedDemIds: _currentFineMap.keys.toList(),
          );
        } catch (e) {
          debugPrint('Error in handlePaymentFailure: $e');
        }
      } else if (client != null) {
        // Widget disposed (user navigated away) — use captured client directly
        debugPrint('Widget disposed, cleaning up payment directly via captured client');
        try {
          await Future.wait([
            SupabaseService.fromSchema('payment').update({
              'paystatus': 'F',
              'paymethod': 'razorpay',
              'paydate': DateTime.now().toIso8601String(),
            }).eq('pay_id', payId),
            SupabaseService.fromSchema('shoppingcart').update({
              'carinitiated': 'N',
            }).eq('car_id', carId),
          ]);
          debugPrint('Direct cleanup done: pay_id=$payId marked F, car_id=$carId reset to N');
        } catch (e) {
          debugPrint('Error in direct payment cleanup: $e');
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $description'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Core payment success logic shared by mobile (razorpay_flutter) and web (JS interop)
  void _handlePaymentSuccessCore(String paymentId) async {
    debugPrint('Payment Success: $paymentId');

    final payId = _currentPayId;
    final carId = _currentCarId;
    final items = _currentPaymentItems;

    if (payId == null || carId == null || items == null) return;

    // Immediately clear to prevent duplicate callback execution
    _currentPayId = null;
    _currentCarId = null;
    _currentOrderId = null;
    _currentPaymentItems = null;

    // Show processing overlay (local widget — auto-clears if cart screen disposes)
    if (mounted) {
      setState(() {
        _isPaymentLoading = true;
        _loadingMessage = 'Processing payment...';
      });
    }

    List<int> newPayIds = [];
    if (mounted) {
      try {
        newPayIds = await handlePaymentSuccess(
          ref: ref,
          payId: payId,
          carId: carId,
          paymethod: 'razorpay',
          payreference: paymentId,
          items: items,
          fineMap: _currentFineMap,
        );
      } catch (e) {
        debugPrint('Error in handlePaymentSuccess (widget may be disposed): $e');
      }
    }

    // Hide processing overlay
    if (mounted) setState(() => _isPaymentLoading = false);

    if (newPayIds.isNotEmpty && mounted) {
      // complete_payment_grouped issues one receipt per fee group, so a cart
      // mixing groups (e.g. TUITION + TRANSPORT) returns multiple ids. Single
      // receipt: jump straight to it. Multiple: tell the user and land on the
      // history list so all are visible at once.
      final multi = newPayIds.length > 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(multi
              ? 'Payment successful — ${newPayIds.length} receipts created.'
              : 'Payment successful!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (multi) {
        context.go(Routes.paymentHistory);
      } else {
        context.go('${Routes.transactionDetails}/${newPayIds.first}');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment received but processing failed. Please contact support.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _handlePaymentSuccessCore(response.paymentId ?? '');
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    debugPrint('Payment Error: ${response.code} - ${response.message}');

    // Extract payment_id from Razorpay error response
    String? razorpayPaymentId = response.error?['id']?.toString();
    String? errorReason = response.error?['error_description']?.toString()
        ?? response.error?['description']?.toString();
    debugPrint('Razorpay error map: ${response.error}');

    // If SDK didn't provide payment_id, fetch it from Razorpay API via order_id
    final orderId = _currentOrderId;
    if (razorpayPaymentId == null && orderId != null) {
      debugPrint('Payment ID not in error response, fetching from Razorpay API for order: $orderId');
      razorpayPaymentId = await _fetchPaymentIdFromOrder(orderId);
    }
    debugPrint('Final paymentId: $razorpayPaymentId, errorReason: $errorReason');

    final payId = _currentPayId;
    final carId = _currentCarId;

    if (payId != null && carId != null) {
      await handlePaymentFailure(
        ref: ref,
        payId: payId,
        carId: carId,
        payReference: razorpayPaymentId,
        errorReason: errorReason,
        attemptedDemIds: _currentFineMap.keys.toList(),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Cancelled by user"}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    _currentPayId = null;
    _currentCarId = null;
    _currentOrderId = null;
    _currentPaymentItems = null;
  }

  /// Fetches the Razorpay payment ID by order_id via Edge Function
  Future<String?> _fetchPaymentIdFromOrder(String orderId) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'get-razorpay-payment',
        body: {'order_id': orderId},
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        final paymentId = data['payment_id'] as String?;
        debugPrint('Fetched payment ID from Razorpay API: $paymentId');
        return paymentId;
      }
      debugPrint('Edge function returned status ${response.status}');
      return null;
    } catch (e) {
      debugPrint('Error fetching payment ID from Razorpay: $e');
      return null;
    }
  }

  /// Returns true (and shows a popup) if there's a recent 'I' (in-progress)
  /// payment for this student. Caller should abort the new payment attempt.
  /// Mirrors admin's pending-payment guard.
  Future<bool> _checkPendingPaymentBlock(int insId, int stuId) async {
    try {
      final pending = await SupabaseService.fromSchema('payment')
          .select('pay_id, createdat')
          .eq('ins_id', insId)
          .eq('stu_id', stuId)
          .eq('paystatus', 'I')
          .order('createdat', ascending: false)
          .limit(1)
          .maybeSingle();

      if (pending == null) return false;

      final createdAtStr = pending['createdat']?.toString();
      final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
      if (createdAt == null) return false;

      const blockWindowMin = 15;
      final ageMin = DateTime.now().difference(createdAt).inMinutes;
      if (ageMin >= blockWindowMin) return false;

      final waitMin = blockWindowMin - ageMin;
      final pendingPayId = pending['pay_id'] as int;
      if (!mounted) return true;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 26),
              SizedBox(width: 10),
              Text('Payment in Progress'),
            ],
          ),
          content: Text(
            'A previous payment for this student is still pending.\n\n'
            'Please wait about $waitMin minute${waitMin == 1 ? '' : 's'} and try again, '
            'or check now to see whether it has cleared on Razorpay.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _resolvePendingPayment(insId, pendingPayId);
              },
              child: const Text('Check Status Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Pending-payment check failed: $e');
      return false;
    }
  }

  /// Look up the actual Razorpay status for a single pending 'I' payment and
  /// finalise it: recover (status='C' with real items so paynumber + feedemand
  /// update happen) or mark failed. Mirrors admin's `_resolvePendingPayment`.
  Future<void> _resolvePendingPayment(int insId, int payId) async {
    if (mounted) {
      setState(() {
        _isPaymentLoading = true;
        _loadingMessage = 'Checking payment status...';
      });
    }

    try {
      final pay = await SupabaseService.fromSchema('payment')
          .select('payorderid')
          .eq('pay_id', payId)
          .maybeSingle();
      final orderId = pay?['payorderid']?.toString();

      String? razorpayStatus;
      String? razorpayPaymentId;
      if (orderId != null && orderId.isNotEmpty) {
        try {
          final resp = await SupabaseService.client.functions.invoke(
            'get-razorpay-payment',
            body: {'order_id': orderId},
          );
          if (resp.status == 200 && resp.data is Map<String, dynamic>) {
            final data = resp.data as Map<String, dynamic>;
            razorpayStatus = data['status']?.toString();
            razorpayPaymentId = data['payment_id']?.toString();
          }
        } catch (e) {
          debugPrint('Razorpay status lookup failed: $e');
        }
      }

      if (razorpayStatus == 'captured' || razorpayStatus == 'authorized') {
        // Build the real items from paymentdetails so the RPC takes its normal
        // path (paynumber + feedemand update), not the empty-items short-circuit.
        final details = await SupabaseService.fromSchema('paymentdetails')
            .select('dem_id, transtotalamount')
            .eq('pay_id', payId)
            .eq('activestatus', 1);
        final detailRows = (details as List).cast<Map<String, dynamic>>();
        final demIds = detailRows
            .map((d) => d['dem_id'] is int ? d['dem_id'] as int : int.parse(d['dem_id'].toString()))
            .toList();
        final demands = await SupabaseService.fromSchema('feedemand')
            .select('dem_id, demfeetype')
            .inFilter('dem_id', demIds);
        final typeByDem = <int, String>{};
        for (final row in (demands as List).cast<Map<String, dynamic>>()) {
          final id = row['dem_id'] is int ? row['dem_id'] as int : int.parse(row['dem_id'].toString());
          typeByDem[id] = (row['demfeetype'] as String?) ?? '';
        }
        final rpcItems = detailRows.map((d) {
          final id = d['dem_id'] is int ? d['dem_id'] as int : int.parse(d['dem_id'].toString());
          return {
            'dem_id': id,
            'amount': (d['transtotalamount'] as num?)?.toDouble() ?? 0,
            'demfeetype': typeByDem[id] ?? '',
          };
        }).toList();

        final result = await SupabaseService.client.rpc('complete_payment_grouped', params: {
          'p_pay_id': payId,
          'p_pay_method': 'razorpay',
          'p_pay_reference': razorpayPaymentId ?? orderId ?? 'recovered',
          'p_items': rpcItems,
          'p_ins_id': insId,
          'p_status': 'C',
        });

        final newPayIds = <int>[];
        if (result is List) {
          for (final row in result) {
            final id = row is Map ? row['pay_id'] : null;
            if (id is int) newPayIds.add(id); else if (id is num) newPayIds.add(id.toInt());
          }
        }
        if (newPayIds.isEmpty) newPayIds.add(payId);

        ref.invalidate(feesProvider);
        ref.invalidate(paymentsProvider);
        ref.invalidate(notificationsProvider);
        if (mounted) setState(() => _isPaymentLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recovered — receipt is ready.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (newPayIds.length > 1) {
          context.go(Routes.paymentHistory);
        } else {
          context.go('${Routes.transactionDetails}/${newPayIds.first}');
        }
        return;
      }

      // Not captured — mark failed so the user can retry.
      await handlePaymentFailure(
        ref: ref,
        payId: payId,
        carId: 0,
        payReference: razorpayPaymentId,
      );
      ref.invalidate(paymentsProvider);
      if (mounted) setState(() => _isPaymentLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Previous payment did not complete. You can try again now.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Pending-payment recovery error: $e');
      if (mounted) setState(() => _isPaymentLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not check payment status: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Shows a dialog listing overdue fees and the fine applied to each.
  /// Returns true if the user confirms, false/null otherwise.
  Future<bool?> _showFineConfirmationDialog({
    required Map<int, double> fineMap,
    required List<FeeModel> items,
    required double baseTotal,
    required double totalFine,
  }) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final finedItems = items.where((f) => fineMap.containsKey(f.demId)).toList();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Late Fee Applicable'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following fees are overdue and a late fee will be applied:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 14),
              ...finedItems.map((fee) {
                final fine = fineMap[fee.demId] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fee.demfeetype,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Due: ${DateFormat('dd MMM yyyy').format(fee.dueDate)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+ ${currencyFmt.format(fine)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Fees Total', style: TextStyle(fontSize: 13)),
                  Text(currencyFmt.format(baseTotal),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Late Fee', style: TextStyle(fontSize: 13, color: Colors.orange)),
                  Text('+ ${currencyFmt.format(totalFine)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(currencyFmt.format(baseTotal + totalFine),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('Pay ${currencyFmt.format(baseTotal + totalFine)}'),
          ),
        ],
      ),
    );
  }

  /// Desktop payment: opens Razorpay JS checkout in system browser,
  /// then polls the Edge Function for payment status (same as admin app).
  Future<void> _openDesktopRazorpayCheckout({
    required int payId,
    required int carId,
    required String orderId,
    required int amountInPaise,
    required dynamic student,
    required List<FeeModel> items,
  }) async {
    final studentName = (student.stuname as String).replaceAll("'", "\\'");
    final studentMobile = student.stumobile as String;
    final studentEmail = (student.stuemail as String?) ?? '';

    // Build HTML with Razorpay JS checkout (same as admin app)
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <title>SchoolPay - Fee Payment</title>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f5; }
    .container { text-align: center; padding: 40px; background: white; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .success { color: #4CAF50; font-size: 24px; }
    .failed { color: #F44336; font-size: 24px; }
    .info { color: #666; margin-top: 10px; }
  </style>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
</head>
<body>
  <div class="container" id="status">
    <p>Opening Razorpay Checkout...</p>
  </div>
  <script>
    var options = {
      key: 'rzp_test_RQsgJgVFwM7kov',
      amount: $amountInPaise,
      currency: 'INR',
      name: 'SchoolPay',
      description: 'School Fees Payment',
      order_id: '$orderId',
      prefill: {
        name: '$studentName',
        contact: '$studentMobile',
        email: '$studentEmail'
      },
      theme: { color: '#1A73E8' },
      notes: { pay_id: '$payId', student_id: '${student.stuId}' },
      handler: function(response) {
        document.getElementById('status').innerHTML =
          '<p class="success">Payment Successful!</p>' +
          '<p class="info">Payment ID: ' + response.razorpay_payment_id + '</p>' +
          '<p class="info">You can close this window now.</p>';
      }
    };
    var rzp = new Razorpay(options);
    rzp.on('payment.failed', function(response) {
      document.getElementById('status').innerHTML =
        '<p class="failed">Payment Failed</p>' +
        '<p class="info">' + response.error.description + '</p>' +
        '<p class="info">You can close this window now.</p>';
    });
    rzp.open();
  </script>
</body>
</html>
''';

    // Write temp HTML file and open in browser
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/schoolpay_razorpay_checkout.html');
    await tempFile.writeAsString(html);
    final fileUri = Uri.file(tempFile.path);
    await launchUrl(fileUri);

    // Show polling dialog while waiting for payment
    if (!mounted) return;

    Timer? pollTimer;
    final completer = Completer<String?>();
    List<int> desktopNewPayIds = [];

    pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final response = await SupabaseService.client.functions.invoke(
          'get-razorpay-payment',
          body: {'order_id': orderId},
        );

        if (response.status == 200) {
          final data = response.data as Map<String, dynamic>;
          final status = data['status'] as String?;
          final rpPaymentId = data['payment_id'] as String?;

          if (status == 'captured' || status == 'authorized') {
            timer.cancel();

            // Update payment reference
            await SupabaseService.fromSchema('payment').update({
              'payreference': rpPaymentId,
            }).eq('pay_id', payId);

            desktopNewPayIds = await handlePaymentSuccess(
              ref: ref,
              payId: payId,
              carId: carId,
              paymethod: 'razorpay',
              payreference: rpPaymentId ?? orderId,
              items: items,
              fineMap: _currentFineMap,
            );
            // Signal completion only after the receipt ids are captured so the
            // outer flow can navigate to the correct transaction.
            if (!completer.isCompleted) completer.complete('C');
          } else if (status == 'failed') {
            timer.cancel();
            if (!completer.isCompleted) completer.complete('F');

            await handlePaymentFailure(
              ref: ref,
              payId: payId,
              carId: carId,
              payReference: rpPaymentId,
              attemptedDemIds: _currentFineMap.keys.toList(),
            );
          }
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });

    // Show waiting dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Waiting for Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Complete the payment in your browser.\nThis will update automatically.'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                pollTimer?.cancel();
                if (!completer.isCompleted) completer.complete(null);
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel Payment'),
            ),
          ],
        ),
      ),
    );

    // If dialog dismissed without completion, handle as failure
    final result = completer.isCompleted ? await completer.future : null;
    pollTimer?.cancel();

    if (result == null) {
      await handlePaymentFailure(
        ref: ref,
        payId: payId,
        carId: carId,
        attemptedDemIds: _currentFineMap.keys.toList(),
      );
    }

    if (result == 'C' && mounted) {
      Navigator.of(context).pop(); // Close dialog if still open
      ref.invalidate(feesProvider);
      ref.invalidate(paymentsProvider);
      if (desktopNewPayIds.isNotEmpty) {
        if (desktopNewPayIds.length > 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment successful — ${desktopNewPayIds.length} receipts created.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go(Routes.paymentHistory);
        } else {
          context.go('${Routes.transactionDetails}/${desktopNewPayIds.first}');
        }
      }
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Redirecting to ${response.walletName}...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
