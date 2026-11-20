import 'dart:async';
import 'dart:io' show Directory, File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_ui.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/paytm_service.dart';
import '../../../core/services/online_payment_service.dart';
import '../../widgets/common/gateway_checkout_page.dart';
import '../../../config/routes.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/student_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../widgets/common/app_action_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/app_icon_circle_button.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';

/// The old phone-side Paytm flow. Off for good: payments go through the
/// school's gateway on the server (pay-create / pay-status).
const bool kLegacyClientPaytm = false;

class CartScreen extends ConsumerStatefulWidget {
  final bool isStandalone;

  const CartScreen({super.key, this.isStandalone = false});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  // Mobile background — matches desktop scaffold
  static const Color _bg = Color(0xFFF5F1E8);
  static const Color _textDark = Color(0xFF17232B);
  static const Color _textMedium = Color(0xFF4A5A63);
  static const Color _textLight = Color(0xFF4A5A63);

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

  /// dem_id(as string) -> {payable, partial_allowed, ...} from the database.
  /// Which fee types accept a part payment is configured per fee type in the
  /// admin app, so it is not decided here.
  Map<String, Map<String, dynamic>> _payOrder = const {};

  /// Clearance rank: LOWER is paid first. Unknown sorts last and blocks nothing.
  static const int _unranked = 1 << 30;
  int _rankOf(FeeModel f) =>
      (_payOrder[f.id]?['rank'] as num?)?.toInt() ?? _unranked;

  /// Cart items that would become unpayable if [removing] were taken out.
  ///
  /// Measured BEFORE and AFTER rather than absolutely, so a cart that was
  /// already inconsistent -- a blocker given a priority only after the fee was
  /// added, say -- is not blamed on this removal. Only what THIS removal
  /// strands is named, and the parent is never trapped by a state they could
  /// not have caused.
  List<String> _strandedByRemoving(List<FeeModel> items, Set<String> removing) {
    Set<String> unmetIn(Set<String> present) {
      final bad = <String>{};
      for (final id in present) {
        final r = (_payOrder[id]?['rank'] as num?)?.toInt();
        if (r == null) continue;
        _payOrder.forEach((otherId, other) {
          final o = (other['rank'] as num?)?.toInt();
          if (o == null || o >= r) return;
          if (!present.contains(otherId)) bad.add(id);
        });
      }
      return bad;
    }

    final all = items.map((f) => f.id).toSet();
    final newly = unmetIn(all.difference(removing))
        .difference(unmetIn(all))
        .difference(removing);
    final names = <String>{};
    for (final id in newly) {
      final n = (_payOrder[id]?['demfeetype'] ?? '').toString().trim();
      names.add(n.isEmpty ? 'a later fee' : n);
    }
    return names.toList()..sort();
  }

  Future<void> _loadPayOrder() async {
    final student = ref.read(selectedStudentProvider);
    if (student == null) return;
    final map = await SupabaseService.checkFeePaymentOrder(
        student.insId, student.stuId);
    if (mounted) setState(() => _payOrder = map);
  }

  /// Captured before opening the gateway so callbacks can clean up even after widget disposal.
  SupabaseClient? _capturedClient;

  @override
  void initState() {
    super.initState();
    // Clearance ranks, for the removal guard below. Post-frame because it
    // reads a provider. The part-payment amount itself is chosen on the fees
    // screen, not here.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPayOrder());
  }

  @override
  void dispose() {
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
          // Back Button — amber circle + state handling
          AppIconCircleButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.home);
              }
            },
            icon: SvgPicture.asset(
              'assets/icons/arrow-left.svg',
              width: 20,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),

          // Title
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Payment summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isMobile ? AppUi.ink : AppColors.textPrimaryC(context),
                  letterSpacing: -0.3,
                ),
              ),
              if (cartState.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '${cartState.items.length} item${cartState.items.length > 1 ? 's' : ''} selected',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color:
                        isMobile ? AppUi.inkMuted : AppColors.textSecondaryC(context),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppUi.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppUi.line),
                ),
                child: const Center(
                  child: AppIcon(
                    'trash',
                    size: 19,
                    color: AppUi.failInk,
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
        color: const Color(0xFF121212),
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
          style: TextStyle(fontFamily: AppFonts.headingFamily, 
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
                  color: AppColors.secondary,
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
      if (fee.isArrear) {
        // Arrear is the ONLY special-cased (virtual) group.
        category = 'Arrear Fees';
      } else if (fee.feeGroupName.trim().isNotEmpty) {
        // Everything else groups by its REAL fee group from the feegroup table
        // (e.g. "College Fees"). Any newly added group gets its own card
        // automatically — no code change / no hardcoded type buckets.
        category = fee.feeGroupName.trim();
      } else {
        category = '${fee.demfeeterm} (${fee.demfeeyear})';
      }
      feesByCategory.putIfAbsent(category, () => []);
      feesByCategory[category]!.add(fee);
    }

    // Clearance order first -- a group is ranked by its earliest-clearing fee,
    // so the cart reads top-to-bottom in the order the money must actually be
    // applied. Arrear-first and then alphabetical remain the tie-breakers, so
    // with no priorities configured the cart looks exactly as it did before.
    int groupRank(String cat) => (feesByCategory[cat] ?? const <FeeModel>[])
        .map(_rankOf)
        .fold(_unranked, (a, b) => a < b ? a : b);

    final sortedCategories = feesByCategory.keys.toList()
      ..sort((a, b) {
        final gr = groupRank(a).compareTo(groupRank(b));
        if (gr != 0) return gr;
        int order(String cat) => cat.toLowerCase().contains('arrear') ? -100 : 0;
        final orderA = order(a);
        final orderB = order(b);
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

        // One card per fee group; each is freely removable.
        ...sortedCategories.map((category) {
          final fees = feesByCategory[category]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCategoryCard(context, ref, category, fees),
          );
        }),

        // Adding more is a normal thing to want here, and it was only
        // reachable by going back. The cart holds ONE fee group, so this
        // returns to that group's fee list rather than the full list.
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final group = cartState.groupName;
              context.push(group == null
                  ? Routes.allPendingFees
                  : '${Routes.allPendingFees}?group=${Uri.encodeComponent(group)}');
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon('add', size: 17, color: AppUi.link),
                  SizedBox(width: 7),
                  Text(
                    'Add more fees',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppUi.link),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon('lock', size: 13, color: AppUi.inkFaint),
              SizedBox(width: 6),
              Text(
                'Payments are processed securely',
                style: TextStyle(fontSize: 12.5, color: AppUi.inkFaint),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24), // Space for bottom bar
      ],
    );
  }

  Map<String, dynamic> _getCategoryStyle(String category) {
    // Keyword-based so it works for real fee-group names (e.g. "College Fees",
    // "Transport Fees") as well as the legacy fixed buckets.
    final c = category.toLowerCase();
    if (c.contains('arrear')) {
      return {
        'color': const Color(0xFFB7701A),
        'svgPath': 'assets/icons/linear/clock-1.svg',
        'showMonth': false,
      };
    } else if (c.contains('bus') || c.contains('van') || c.contains('transport')) {
      return {
        'color': const Color(0xFFF0A43A),
        'svgPath': 'assets/school Icons/van.svg',
        'showMonth': true,
      };
    } else if (c.contains('hostel')) {
      return {
        'color': const Color(0xFF0F6B63),
        'svgPath': 'assets/school Icons/school.svg',
        'showMonth': true,
      };
    } else if (c.contains('exam') || c.contains('test')) {
      return {
        'color': const Color(0xFF2F7FB5),
        'svgPath': 'assets/school Icons/exam.svg',
        'showMonth': false,
      };
    } else if (c.contains('tuition')) {
      return {
        'color': const Color(0xFF6B4FA0),
        'svgPath': 'assets/school Icons/school.svg',
        'showMonth': true,
      };
    } else if (c.contains('college') || c.contains('school')) {
      return {
        'color': AppColors.success,
        'svgPath': 'assets/school Icons/school.svg',
        'showMonth': false,
      };
    } else {
      // Any other / newly-added group: pick a stable, distinct colour from a
      // palette (hashed by name) so each new group card stands apart.
      const palette = [
        Color(0xFF6B4FA0), // indigo
        Color(0xFF2F7FB5), // sky
        Color(0xFF0F6B63), // emerald
        Color(0xFFC8453A), // rose
        Color(0xFF6B4FA0), // purple
        Color(0xFF2F7FB5), // teal
      ];
      return {
        'color': palette[category.hashCode.abs() % palette.length],
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
    final years = fees
        .map((f) => f.demfeeyear.trim())
        .where((y) => y.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isMobile ? AppUi.card : AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(isMobile ? 14 : 12),
        border: Border.all(
            color: isMobile ? AppUi.line : AppColors.borderC(context)),
      ),
      child: Column(
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (categoryStyle['color'] as Color)
                        .withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      svgPath,
                      width: 17,
                      height: 17,
                      colorFilter: ColorFilter.mode(
                        categoryStyle['color'] as Color,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isMobile
                              ? AppUi.ink
                              : AppColors.textPrimaryC(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (years.isNotEmpty) 'AY ${years.join(', ')}',
                          '${fees.length} item${fees.length > 1 ? 's' : ''}',
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppUi.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // "Remove" spelled out: a bare x on a money screen reads as
                // ambiguous -- remove the group, or close the card?
                Opacity(
                  opacity: canRemove ? 1.0 : 0.35,
                  child: GestureDetector(
                    onTap: canRemove
                        ? () => _showRemoveGroupDialog(context, ref, category, fees)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppUi.failInk.withValues(alpha: 0.35)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon('trash', size: 14, color: AppUi.failInk),
                          SizedBox(width: 6),
                          Text(
                            'Remove',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppUi.failInk),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
              height: 1,
              color: isMobile ? AppUi.lineSoft : AppColors.borderC(context)),

          // Fee Items
          ...fees.map((fee) => _buildFeeItem(fee, categoryStyle['showMonth'] as bool)),

          // Total Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMobile ? AppUi.fill : AppColors.filterBg(context),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isMobile
                        ? AppUi.inkMuted
                        : AppColors.textPrimaryC(context),
                  ),
                ),
                Text(
                  '₹${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isMobile ? AppUi.ink : AppColors.textPrimaryC(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
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
    // A fee that something else in the cart is riding on cannot be pulled out
    // from under it. Checked BEFORE the confirm dialog, so the parent is told
    // why rather than confirming an action that then does nothing.
    final stranded = _strandedByRemoving(
        ref.read(cartProvider).items, fees.map((f) => f.id).toSet());
    if (stranded.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Remove ${stranded.join(', ')} first -- it can only be '
            'paid together with $category.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
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
          bottom: BorderSide(color: isMobile ? const Color(0xFFEFE9DC) : AppColors.borderC(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.feeTypeName,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: isMobile ? AppUi.ink : AppColors.textPrimaryC(context),
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
          Builder(builder: (context) {
            final cart = ref.watch(cartProvider);
            final amount = cart.amountFor(fee);
            final isPart = amount < fee.balancedue;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${NumberFormat('#,##,###').format(amount.toInt())}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isMobile ? AppUi.ink : AppColors.textPrimaryC(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                // The part amount is chosen on the fees screen, where the fee
                // is picked. The cart only REPORTS it -- one place to set a
                // figure means the cart can never disagree with the screen the
                // parent decided on.
                if (isPart)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'part of ₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryC(context),
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

  String _extractMonthFromDate(FeeModel fee) {
    final date = fee.duedate ?? fee.createdat;
    return DateFormat('MMMM yyyy').format(date);
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, CartState cartState) {
    final isMobile = !context.isDesktop;
    final bottomContent = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // WHY THIS LINE IS HERE. On 12-10-2026 a parent sent Rs 2,700 by
          // UPI straight to the college's Paytm account instead of paying
          // here. The money arrived; nothing identified it, because a UPI
          // transfer carries an amount and a payer and no student. It took a
          // morning to work out whose it was, and she carried a paid fee as
          // outstanding for a day.
          //
          // Nothing in any app can stop that -- we are not in the
          // transaction. Saying so at the moment of paying is the only
          // prevention there is, and it is aimed squarely at the parent who
          // has never used this screen before.
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 15,
                    color: isMobile
                        ? AppUi.inkMuted
                        : AppColors.textSecondaryC(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Please pay here only. Money sent directly by UPI or QR '
                    'cannot be matched to your account and will not produce a '
                    'receipt.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: isMobile
                          ? AppUi.inkMuted
                          : AppColors.textSecondaryC(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total to pay',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isMobile ? AppUi.inkMuted : AppColors.textSecondaryC(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${NumberFormat('#,##,###').format(cartState.totalAmount.toInt())}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: isMobile ? AppUi.ink : AppColors.textPrimaryC(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          AppActionButton(
            onPressed: () => _handleProceedToPayment(),
            label: 'Pay now',
            borderRadius: 12,
            fullWidth: false,
            horizontalPadding: 28,
            trailing: const AppIcon(
              'arrow-right-1',
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
          ),
        ],
      ),
    );

    // On desktop, DesktopDetailScaffold wraps in a card — return just the inner content
    if (context.isDesktop) return bottomContent;

    // On mobile, soft rounded decoration
    return Container(
      decoration: const BoxDecoration(
        color: AppUi.card,
        border: Border(top: BorderSide(color: AppUi.line)),
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

    // COOLDOWN AFTER AN ATTEMPT THAT DID NOT SUCCEED.
    //
    // Each attempt opens its own Paytm transaction, and one that looks failed
    // here may still be settling at the bank. Retrying straight away can put
    // two live transactions against the same dues and debit the family twice
    // for one set of fees. See kPaymentRetryCooldown.
    final wait = await paymentRetryWait(student.stuId);
    if (wait != null) {
      if (!mounted) return;
      final mins = wait.inMinutes;
      final secs = wait.inSeconds % 60;
      final left = mins > 0 ? '$mins min ${secs}s' : '${secs}s';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const AppIcon('clock', color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your last payment is still being confirmed by the bank. '
                  'Please wait $left before trying again, so you are not '
                  'charged twice.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Arrear-first: regular fees can't be paid while the student still has
    // outstanding arrear dues. An arrear-only cart is always allowed; a cart
    // containing regular fees is blocked until every arrear is cleared.
    final pendingFees = ref.read(pendingFeesProvider);
    final cartHasRegular = cartState.items.any((f) => !f.isArrear);
    final anyArrearOutstanding = pendingFees.any((f) => f.isArrear);
    if (cartHasRegular && anyArrearOutstanding) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              AppIcon('warning-2', color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Clear the arrear dues first — pay arrears before regular fees.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // (One-year-per-payment is enforced up front at Add-to-Cart, so a mixed-year
    // cart can't be built in the first place.)

    // Block duplicate online attempts while a recent 'I' row exists for this
    // student. Sweep clears orphans only after 5 minutes; within that window
    // we warn the user instead of creating another pending row (matches admin).
    // Load fine rules concurrently with the pending-payment check (independent),
    // so we don't pay for both round-trips one after another.
    if (await _checkPendingPaymentBlock(student.insId, student.stuId)) return;

    // The late fine comes from the school's server (fee_fine_quote): its Fine
    // Rules, the fee type's Fine Applicable switch, a fine set by the office,
    // less fines already paid. The server refuses a payment with any other
    // fine, so nothing is guessed here.
    final Map<int, double> quote;
    try {
      quote = await OnlinePaymentService.fineQuote(
          student.stuId, [for (final f in cartState.items) f.demId]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not check late fines. Please check your connection and try again.'),
          backgroundColor: AppColors.error,
        ));
      }
      return;
    }
    final fineMap = <int, double>{};
    double totalFine = 0;
    for (final fee in cartState.items) {
      // A PART payment carries no fine. complete_payment_grouped applies the
      // whole amount it is handed to balancedue and never writes fineamount,
      // so a fine folded into a part line would pay down the FEE by the fine
      // and then fall due again on the next instalment. The fine is settled
      // with the closing payment, where the amount and the balance agree.
      //
      // Skipping it HERE and not only at the posting step is the point: this
      // loop feeds the confirmation dialog and grandTotal, which is the figure
      // the gateway actually charges. Dropping it downstream alone would
      // collect the fine from the parent and record it nowhere.
      if (cartState.amountFor(fee) < fee.balancedue) continue;
      final fine = quote[fee.demId] ?? 0;
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

    // The school's own gateway (office app > Setup > Payment Gateways): the
    // server checks the amounts, opens the order and raises the receipt.
    // Without one, the Paytm flow below runs as before.
    // Fails closed: if the lookup itself fails (network, session), stop here
    // rather than fall back to the older client-side Paytm flow.
    OnlineGateway? gateway;
    try {
      gateway = await OnlinePaymentService.gatewayFor();
    } catch (e) {
      _toast('Could not reach the payment server. Check your internet and try again.', AppColors.error);
      return;
    }
    if (gateway != null) {
      await _payViaGateway(student.stuId, student.stuname, cartState.items, fineMap);
      return;
    }
    // No gateway set up for the school: online payment is not offered. The
    // older client-side Paytm flow below is NOT used any more -- it recorded
    // receipts from the phone, through database functions that are being
    // closed to the app (only the server may record a payment).
    _toast('Online payment is not available for your school yet. Please pay at the school office.',
        AppColors.warning, seconds: 6);
    if (kLegacyClientPaytm == false) return;

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
        fineMap: _currentFineMap,
          partMap: ref.read(cartProvider).partMapByDemId,
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

      // Step 3: Create Paytm order via Edge Function (amount includes fines).
      // The Paytm merchant key is signed server-side in the shared
      // `create-paytm-order` edge function — the client never sees it.
      debugPrint('PAYMENT STEP 3: Creating Paytm order (amount=$grandTotal)...');

      if (!PaytmService.isConfigured) {
        await handlePaymentFailure(
          ref: ref,
          payId: payId,
          carId: carId,
          attemptedDemIds: _currentFineMap.keys.toList(),
        );
        if (mounted) setState(() => _isPaymentLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment gateway is not configured. Please contact support.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      // Paytm JS Checkout needs a WebView — mobile (Android/iOS) only.
      if (kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))) {
        await handlePaymentFailure(
          ref: ref,
          payId: payId,
          carId: carId,
          attemptedDemIds: _currentFineMap.keys.toList(),
        );
        if (mounted) setState(() => _isPaymentLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please use the mobile app to pay with Paytm.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      // Per-unit settlement (Paytm handoff §4): the order is created under this
      // institution's own Paytm merchant, from public.paytm_configuration, so
      // the funds settle to that unit's own bank account.
      //
      // An unresolved institution STOPS the payment. It used to fall through to
      // the default parent merchant, which took the money and issued a normal
      // receipt while settling it into the wrong account — invisible at both
      // ends. Same rule as the admin app.
      // ONE FEE GROUP PER PAYMENT.
      //
      // A Paytm order settles to exactly one merchant, and each fee group has
      // its own: college fees into the college account, hostel fees into the
      // hostel one. A cart holding both would put all of it in one account,
      // and nothing on the receipts would say so -- the server still raises a
      // receipt per group, so the two documents would disagree with the money.
      // THE DEMANDS BEING PAID -- from the cart, not from _currentFineMap.
      //
      // _currentFineMap holds only the demands that carry a FINE (it is built
      // as `if (fine > 0) fineMap[demId] = fine`). A fee that is not overdue
      // is not in it, so for an ordinary hostel fee this list was EMPTY: no
      // fee group was resolved, resolvePaytmRouting was handed a null group,
      // it skipped the merchant lookup altogether and fell back to the
      // institution default -- the college merchant. The hostel money went to
      // the college account with nothing anywhere reporting a problem.
      //
      // The payment ROW still showed ban_id = 2, because that is computed from
      // cartState.items; only the merchant came from the fines map. Two lists
      // for one decision is what hid this.
      final payingDemIds =
          cartState.items.map((f) => f.demId).toSet().toList();
      final fg = await SupabaseService.feeGroupsForDemands(payingDemIds);

      if (payingDemIds.isEmpty) {
        await handlePaymentFailure(
          ref: ref, payId: payId, carId: carId, attemptedDemIds: const []);
        if (mounted) {
          setState(() {
            _isPaymentLoading = false;
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nothing to pay — please add a fee and try again.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Resolved ONCE here, so the two refusals below and the routing further
      // down cannot disagree if the setting changes mid-payment.
      final splitByFeeGroup =
          await SupabaseService.feeGroupSettlementEnabled(student.insId);

      // A due whose fee group cannot be worked out STOPS the payment. Paying
      // it under the merchant of the dues that DID resolve would settle it
      // into an account it may not belong to, and the receipt would look
      // perfectly normal at both ends.
      if (splitByFeeGroup && fg.unresolved.isNotEmpty) {
        await handlePaymentFailure(
          ref: ref,
          payId: payId,
          carId: carId,
          attemptedDemIds: payingDemIds,
        );
        if (mounted) setState(() => _isPaymentLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'One of these fees is not linked to a fee group, so we '
                  'cannot tell which account it belongs to. Please pay at the '
                  'office, or contact support.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 7),
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      if (splitByFeeGroup && fg.names.length > 1) {
        await handlePaymentFailure(
          ref: ref,
          payId: payId,
          carId: carId,
          attemptedDemIds: payingDemIds,
        );
        if (mounted) setState(() => _isPaymentLoading = false);
        if (mounted) {
          final labels = fg.names.values
              .where((n) => n.isNotEmpty)
              .toList()
            ..sort();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'These fees belong to different accounts '
                  '(${labels.join(' and ')}). Please pay one at a time — '
                  'remove the others from the cart and pay again.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 7),
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      // Per-group settlement: the order is signed with the merchant of the
      // fee group being paid, falling back to the institution's own.
      // The fee group is what decides the merchant. ban_id is passed too so
      // the resolver can still answer if the group lookup comes back empty.
      final payingFgId = fg.names.length == 1 ? fg.names.keys.first : null;
      final payingBanId =
          fg.names.length == 1 ? fg.banks[fg.names.keys.first] : null;
      final routing = await SupabaseService.resolvePaytmRouting(
          insId: student.insId, fgId: payingFgId, banId: payingBanId);
      if (!routing.ok) {
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
              content: Text(routing.error!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      final routeMid = routing.mid;
      debugPrint('Paytm route MID (ins ${student.insId}): $routeMid');

      PaytmOrder order;
      try {
        order = await PaytmService.createOrder(
          payId: payId,
          amount: grandTotal,
          custId: 'STU-${student.stuId}',
          mid: routeMid,
          channelId: 'WAP', // mobile channel → enables UPI Intent (direct-to-app)
        );
      } catch (e) {
        debugPrint('PAYMENT STEP 3 FAILED: $e');
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
              content: Text('Failed to create payment order: $e. Please try again.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      debugPrint('PAYMENT STEP 3 OK: orderId=${order.orderId}');

      // Persist the Paytm order id on the payment row (admin bank-reconciliation
      // parity — the slot the gateway order id goes in).
      try {
        // Through the SECURITY DEFINER RPC, the app has
        // no UPDATE grant on payment, so a direct update was always refused.
        // create-paytm-order also saves the id server-side; this is the backup.
        await SupabaseService.client.rpc('set_payment_order', params: {
          'p_ins_id': ref.read(selectedStudentProvider)?.insId,
          'p_pay_id': payId,
          'p_order_id': order.orderId,
        });
      } catch (e) {
        // Swallowed ON PURPOSE, and only since 13-10-2026. create-paytm-order
        // now stamps the id server-side through stamp_payorderid before it
        // returns, so this call is the second of two and losing it costs
        // nothing. Until that was fixed it was the ONLY stamp a mobile
        // payment got, and a silent failure here is what let KANNAN D's
        // Rs 5,125 be deleted by his own retry on 11-10-2026.
        //
        // If the server-side stamp is ever removed, this catch has to go
        // with it.
        debugPrint('Failed to persist Paytm payorderid: $e');
      }

      // Store payment info for the success/failure handlers (captured before the
      // checkout opens so cleanup works even if the widget is disposed).
      _currentPayId = payId;
      _currentCarId = carId;
      _currentOrderId = order.orderId;
      _currentPaymentItems = List.from(cartState.items);
      _capturedClient = ref.read(supabaseClientProvider);

      // Hide loading overlay before opening the checkout.
      if (mounted) setState(() => _isPaymentLoading = false);

      if (!mounted) {
        // Widget gone before we could open the sheet — roll the 'I' row back.
        await _handlePaytmFailure(
          payId: payId, carId: carId, orderId: order.orderId, cancelled: true);
        return;
      }

      // Step 4: Open the native Paytm All-in-One SDK (WAP-channel test — the
      // order is now created with channel_id=WAP). Its result is advisory, so
      // the real outcome is confirmed server-side via get-paytm-payment.
      debugPrint('PAYMENT STEP 4: Launching Paytm All-in-One SDK...');
      try {
        await PaytmService.launchSdk(order);
      } catch (e) {
        debugPrint('Paytm SDK returned/threw (advisory): $e');
      }

      if (mounted) {
        setState(() {
          _isPaymentLoading = true;
          _loadingMessage = 'Verifying payment...';
        });
      }
      final result = await PaytmService.confirmOutcome(order);
      if (mounted) setState(() => _isPaymentLoading = false);
      debugPrint('PAYMENT STEP 4: Paytm outcome=$result');

      if (result == 'C') {
        // Best-effort fetch of the Paytm txn id to store as the reference.
        String payRef = '';
        try {
          payRef = (await PaytmService.verifyPayment(order.orderId, mid: order.mid))
                  .paymentId ??
              '';
        } catch (_) {}
        _handlePaymentSuccessCore(
            payRef.isNotEmpty ? payRef : 'Paytm: ${order.orderId}');
      } else if (result == 'F') {
        // Paytm SAID failed. That is a real decline, safe to record.
        await _handlePaytmFailure(
          payId: payId,
          carId: carId,
          orderId: order.orderId,
          cancelled: false,
        );
      } else {
        // PENDING -- confirmOutcome polled for 20s and Paytm still had no
        // answer. This used to be filed as "cancelled by user" and the row
        // written off as 'F'.
        //
        // That is exactly the payment that later succeeds: the bank has
        // already debited, Paytm confirms minutes later, and the money settles
        // to the college the next day -- against a row marked failed, with no
        // receipt, while the demand still shows as due. Nothing ever revisits
        // an 'F' row, so it stayed lost.
        //
        // Leave it 'I'. The stuck-payment sweep resolves it against Paytm and
        // raises the receipt if it captured. It cannot be cleaned up in the
        // meantime: delete_stale_initiated_payments only removes 'I' rows with
        // NO order id, and this one has one.
        //
        // The cart is deliberately left initiated so a second payment cannot
        // be started for the same dues while the first is undecided.
        final pendingInsId = student.insId;
        _currentPayId = null;
        _currentCarId = null;
        _currentOrderId = null;
        _currentPaymentItems = null;
        _capturedClient = null;

        // Keep chasing it in the background rather than making the parent wait.
        // resolveStuckPayment is a top-level function on the shared client, so
        // it is safe after this widget is gone. Paytm usually settles within a
        // few more seconds; by the time they reach History the receipt is
        // normally there. The home-screen sweep is the backstop if this misses.
        unawaited(
          Future.delayed(const Duration(seconds: 12), () async {
            try {
              await resolveStuckPayment(
                insId: pendingInsId,
                payId: payId,
                orderId: order.orderId,
              );
            } catch (e) {
              debugPrint('background resolve pay_id=$payId: $e');
            }
          }),
        );

        if (mounted) {
          setState(() => _isPaymentLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your bank has not confirmed this payment yet. Please do '
                  'NOT pay again — if it went through, the receipt appears in '
                  'History within a minute.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 10),
            ),
          );
        }
      }
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

  static const _gatewayNames = {
    'PAYTM': 'Paytm',
    'RAZORPAY': 'Razorpay',
    'PHONEPE': 'PhonePe',
    'CASHFREE': 'Cashfree',
    'EASEBUZZ': 'Easebuzz',
  };

  void _toast(String text, Color color, {int seconds = 5}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: seconds),
    ));
  }

  /// Pays through the school's own gateway. Nothing here writes a payment:
  /// pay-create opens the order, pay-status raises the receipt.
  Future<void> _payViaGateway(
      int stuId, String stuName, List<FeeModel> fees, Map<int, double> fineMap) async {
    final cart = ref.read(cartProvider);
    final lines = <Map<String, dynamic>>[
      for (final f in fees)
        {
          'dem_id': f.demId,
          'amount': cart.amountFor(f) + (fineMap[f.demId] ?? 0),
          'fine': fineMap[f.demId] ?? 0,
        }
    ];
    setState(() {
      _isProcessing = true;
      _isPaymentLoading = true;
      _loadingMessage = 'Opening payment...';
    });
    try {
      final order = await OnlinePaymentService.start(stuId: stuId, items: lines, channel: 'APP');
      if (!mounted) return;
      setState(() => _isPaymentLoading = false);
      final name = _gatewayNames[order.provider] ?? order.provider;
      final r = await openGatewayCheckout(context,
          order: order, gatewayName: name, payerName: stuName);
      if (!mounted) return;
      switch (r?.status) {
        case 'C':
          await afterGatewayPayment(ref, stuId);
          if (!mounted) return;
          final ids = [
            for (final x in r!.receipts)
              if (int.tryParse('${x['pay_id']}') != null) int.parse('${x['pay_id']}')
          ];
          _toast(ids.length > 1
              ? 'Payment successful — ${ids.length} receipts created.'
              : 'Payment successful!', AppColors.success, seconds: 4);
          if (ids.length == 1) {
            context.go('${Routes.transactionDetails}/${ids.first}');
          } else {
            context.go(Routes.paymentHistory);
          }
        case 'X':
          _toast('Your payment was received, but the receipt could not be raised '
              'automatically. Please do NOT pay again; the school office will '
              'issue it. Reference: ${order.orderId}', AppColors.warning, seconds: 10);
        case 'F' when r!.moneyMayBeMoving:
          _toast('Your bank is still processing this payment. Please do NOT pay again; if it goes '
              'through, the receipt appears in History within a few minutes.', AppColors.warning, seconds: 10);
        case 'F':
          _toast('The payment did not go through. Nothing was collected; you can try again.',
              AppColors.error);
        case 'T':
          _toast('Test payment completed (the school gateway is in test mode): no fee was paid.',
              AppColors.warning, seconds: 8);
        case 'H':
          _toast('This payment was closed by the school office. Please contact the office.', AppColors.warning);
        case null:
          _toast('Could not open the payment page. Please try again.', AppColors.error);
        default:
          _toast('Your bank has not confirmed this payment yet. Please do NOT pay '
              'again — if it went through, the receipt appears in History within '
              'a few minutes.', AppColors.warning, seconds: 10);
      }
    } on OnlinePaymentException catch (e) {
      _toast(e.message, AppColors.error, seconds: 7);
    } catch (e) {
      _toast('Could not start the payment: $e', AppColors.error, seconds: 7);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isPaymentLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }

  /// Core payment success logic shared by the Paytm checkout result handler.
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
          paymethod: 'Online Transfer',
          payreference: paymentId,
          items: items,
          fineMap: _currentFineMap,
          partMap: ref.read(cartProvider).partMapByDemId,
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

  /// Rolls back a Paytm payment that failed or was cancelled: marks the 'I'
  /// payment row 'F' and resets the cart. Mirrors the admin app's failure handling.
  Future<void> _handlePaytmFailure({
    required int payId,
    required int carId,
    required String orderId,
    required bool cancelled,
  }) async {
    final client = _capturedClient;
    final attemptedDemIds = _currentFineMap.keys.toList();
    _currentPayId = null;
    _currentCarId = null;
    _currentOrderId = null;
    _currentPaymentItems = null;
    _capturedClient = null;

    if (mounted) {
      try {
        await handlePaymentFailure(
          ref: ref,
          payId: payId,
          carId: carId,
          payReference: cancelled ? null : 'Paytm $orderId',
          errorReason: cancelled ? 'Cancelled by user' : 'Payment failed',
          attemptedDemIds: attemptedDemIds,
          // Ask Paytm before writing it off. A CANCELLED window especially is
          // not a declined payment -- the parent may have closed it while the
          // bank was still settling, and that money arrives anyway.
          orderId: orderId,
        );
      } catch (e) {
        debugPrint('Error in Paytm handlePaymentFailure: $e');
      }
    } else if (client != null) {
      // Widget disposed (user navigated away) — clean up via captured client.
      try {
        await Future.wait([
          SupabaseService.client.rpc('set_payment_status', params: {
            'p_ins_id': ref.read(selectedStudentProvider)?.insId,
            'p_pay_id': payId,
            'p_status': 'F',
            'p_method': 'online',
          }),
          SupabaseService.fromSchema('shoppingcart').update({
            'carinitiated': 'N',
          }).eq('car_id', carId),
        ]);
      } catch (e) {
        debugPrint('Error in direct Paytm cleanup: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cancelled ? 'Payment cancelled' : 'Payment failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          // Orders of the school's own gateways: the server guards those.
          .isFilter('pg_id', null)
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
            'or check now to see whether the bank has confirmed it.',
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

  /// "Check Status Now" for a pending payment. Goes through
  /// [resolveStuckPayment], so a payment is only finalised when the gateway
  /// gives a definite answer. It used to ask only the gateway and mark everything
  /// else failed -- a Paytm payment that had been charged included.
  Future<void> _resolvePendingPayment(int insId, int payId) async {
    if (mounted) {
      setState(() {
        _isPaymentLoading = true;
        _loadingMessage = 'Checking payment status...';
      });
    }

    void snack(String msg, Color color) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ));
    }

    try {
      final pay = await SupabaseService.fromSchema('payment')
          .select('payorderid')
          .eq('pay_id', payId)
          .maybeSingle();
      final result = await resolveStuckPayment(
        insId: insId,
        payId: payId,
        orderId: pay?['payorderid']?.toString(),
      );

      ref.invalidate(feesProvider);
      ref.invalidate(paymentsProvider);
      ref.invalidate(notificationsProvider);
      if (mounted) setState(() => _isPaymentLoading = false);
      if (!mounted) return;

      switch (result.outcome) {
        case StuckPaymentOutcome.recovered:
          snack('Payment recovered — receipt is ready.', AppColors.success);
          if (result.newPayIds.length > 1) {
            context.go(Routes.paymentHistory);
          } else {
            context.go('${Routes.transactionDetails}/${result.newPayIds.first}');
          }
        case StuckPaymentOutcome.failed:
          snack('Previous payment did not complete. You can try again now.',
              AppColors.warning);
        case StuckPaymentOutcome.leftAlone:
          // Not confirmed either way. Paying again now risks paying twice.
          snack('The bank has not confirmed the previous payment yet. Please '
              'wait a few minutes before paying again.', AppColors.warning);
      }
    } catch (e) {
      debugPrint('Pending-payment recovery error: $e');
      if (mounted) setState(() => _isPaymentLoading = false);
      if (!mounted) return;
      snack('Could not check payment status: $e', AppColors.error);
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


}
