import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/fee_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/student_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';

class PaidFeesScreen extends ConsumerWidget {
  const PaidFeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paidPaymentsAsync = ref.watch(paidFeesByPaymentProvider);
    final notificationCount = ref.watch(notificationCountProvider);
    final student = context.isDesktop ? ref.watch(selectedStudentProvider) : null;

    return DesktopDetailScaffold(
      isNested: true,
      header: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeader(context, notificationCount, student),
          const SizedBox(height: 16),
        ],
      ),
      toolbar: const BreadcrumbBar(currentLabel: 'Paid Fees'),
      body: paidPaymentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, s) => Center(
          child: Text(
            'Error loading paid fees',
            style: TextStyle(color: AppColors.textSecondaryC(context)),
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) return _buildEmptyState(context);

          // Sort payment groups: newest first (higher pay_id = newer)
          final sortedPayIds = groups.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          // Calculate total paid from payment records
          final totalPaid = groups.values
              .fold(0.0, (sum, g) => sum + g.payment.transtotalamount);

          return ListView(
            padding: context.isDesktop ? const EdgeInsets.all(24) : const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              // Dashboard-style header (desktop only)
              if (context.isDesktop) ...[
                _buildDesktopGreetingBanner(
                    context, sortedPayIds.length, totalPaid),
                const SizedBox(height: 18),
                _buildDesktopTitle(context, ref),
                const SizedBox(height: 20),
                _buildDesktopStatCards(
                    context, groups, sortedPayIds.length, totalPaid),
                const SizedBox(height: 20),
              ] else ...[
                // Total paid summary (mobile keeps the existing card)
                _buildTotalSummary(context, totalPaid, sortedPayIds.length),
                const SizedBox(height: 20),
              ],

              // Payment accordion items
              ...sortedPayIds.map((payId) => _PaymentAccordion(
                payment: groups[payId]!.payment,
                fees: groups[payId]!.fees,
              )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopGreetingBanner(
      BuildContext context, int paymentCount, double totalPaid) {
    final hasPayments = paymentCount > 0;
    final message = hasPayments
        ? "Awesome! You've paid ₹${NumberFormat('#,##,###').format(totalPaid.toInt())} across $paymentCount ${paymentCount == 1 ? 'payment' : 'payments'}."
        : 'No paid fees yet.';
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
          "$firstName's Paid Fees",
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

  Widget _buildDesktopStatCards(
    BuildContext context,
    Map<dynamic, dynamic> groups,
    int paymentCount,
    double totalPaid,
  ) {
    final allFees = groups.values
        .expand<dynamic>((g) => g.fees as List<dynamic>)
        .toList();
    final feeCount = allFees.length;
    final lastPayment = groups.values
        .map<DateTime?>((g) => g.payment.createdat as DateTime?)
        .whereType<DateTime>()
        .fold<DateTime?>(null,
            (acc, d) => (acc == null || d.isAfter(acc)) ? d : acc);
    final lastPaymentLabel =
        lastPayment != null ? DateFormat('dd MMM yyyy').format(lastPayment) : '—';
    return Row(
      children: [
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Total Paid',
            value: '₹${NumberFormat('#,##,###').format(totalPaid.toInt())}',
            icon: 'tick-circle',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Payments',
            value: '$paymentCount',
            icon: 'wallet-3',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Fees Cleared',
            value: '$feeCount',
            icon: 'receipt-text',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardTile(
            context: context,
            label: 'Last Payment',
            value: lastPaymentLabel,
            icon: 'calendar',
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
                  color: AppColors.primary,
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

  Widget _buildHeader(BuildContext context, int notificationCount, StudentModel? student) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.home);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.iconButtonBorder(context)),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Center(
                child: SvgPicture.asset('assets/icons/arrow-left.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
              ),
            ),
          ),
          // Title - centered
          Expanded(
            child: Text(
              'Paid Fees',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryC(context),
              ),
            ),
          ),
          // Student chip (desktop only)
          if (student != null) ...[
            _buildStudentChip(context, student),
            const SizedBox(width: 12),
          ],
          // Notification Icon
          GestureDetector(
            onTap: () => context.go(Routes.notifications),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.iconButtonBorder(context)),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset('assets/main icons/line icons/notification.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                  if (notificationCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.iconButtonBg(context), width: 2),
                        ),
                        child: Text(
                          notificationCount > 9 ? '9+' : '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
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

  Widget _buildStudentChip(BuildContext context, StudentModel student) {
    final parts = student.name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.take(2).map((p) => p[0]).join().toUpperCase();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          backgroundImage: (student.photoUrl != null && student.photoUrl!.isNotEmpty)
              ? NetworkImage(student.photoUrl!) : null,
          child: (student.photoUrl == null || student.photoUrl!.isEmpty)
              ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))
              : null,
        ),
        const SizedBox(width: 8),
        Text(student.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryC(context))),
      ],
    );
  }

  Widget _buildTotalSummary(BuildContext context, double totalPaid, int receiptCount) {
    return Column(
      children: [
        Text(
          'Total Paid',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryC(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '\u{20B9} ${NumberFormat('#,##,###').format(totalPaid.toInt())}',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.cardGreenDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$receiptCount ${receiptCount == 1 ? 'receipt' : 'receipts'}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textHintC(context),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.cardGreen,
                shape: BoxShape.circle,
              ),
              child: const AppIcon(
                'tick-circle',
                size: 48,
                color: AppColors.cardGreenDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Paid Fees Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryC(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed fee payments will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryC(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Accordion widget for a single payment transaction group
class _PaymentAccordion extends StatefulWidget {
  final PaymentModel payment;
  final List<FeeModel> fees;

  const _PaymentAccordion({
    required this.payment,
    required this.fees,
  });

  @override
  State<_PaymentAccordion> createState() => _PaymentAccordionState();
}

class _PaymentAccordionState extends State<_PaymentAccordion>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final paymentNumber = payment.paymentNumber;
    final paymentDate = payment.paidAt ?? payment.createdAt;
    final paymentMethod = payment.paymethod ?? '';
    final totalPaid = payment.transtotalamount;
    final isGroupPayment = widget.fees.length > 1;

    // Determine fee group names
    final feeGroups = <String>{};
    for (final fee in widget.fees) {
      final groupName = fee.feeGroupName.isNotEmpty ? fee.feeGroupName : fee.demfeetype;
      feeGroups.add(groupName);
    }
    final isMixedGroups = feeGroups.length > 1;

    // Payment title — use receipt number when available
    final title = paymentNumber.isNotEmpty
        ? paymentNumber
        : isGroupPayment
            ? (isMixedGroups ? 'Payment' : PaidFeesScreen.toTitleCase(feeGroups.first))
            : widget.fees.isNotEmpty
                ? PaidFeesScreen.toTitleCase(widget.fees.first.feeTypeName)
                : 'Payment';

    final subtitle = isGroupPayment
        ? '${widget.fees.length} fees paid together'
        : widget.fees.isNotEmpty && widget.fees.first.demfeeterm.isNotEmpty
            ? '${widget.fees.first.demfeeterm} \u{2022} ${widget.fees.first.demfeeyear}'
            : 'Individual payment';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Collapsed header - always visible
            GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Green check icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cardGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: AppIcon(
                          'tick-circle',
                          size: 20,
                          color: AppColors.cardGreenDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title & subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryC(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondaryC(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amount & chevron
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\u{20B9} ${NumberFormat('#,##,###').format(totalPaid.toInt())}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cardGreenDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMM yyyy').format(paymentDate),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textHintC(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    RotationTransition(
                      turns: _rotateAnimation,
                      child: AppIcon(
                        'arrow-down',
                        size: 22,
                        color: AppColors.textSecondaryC(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded content
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.borderC(context).withValues(alpha: 0.3),
                  ),

                  // Receipt info bar
                  if (paymentNumber.isNotEmpty || paymentMethod.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBg(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            if (paymentNumber.isNotEmpty) ...[
                              AppIcon(
                                'receipt',
                                size: 14,
                                color: AppColors.textSecondaryC(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                paymentNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryC(context),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (paymentMethod.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg(context),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.borderC(context).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  paymentMethod,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondaryC(context),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Fee items
                  if (widget.fees.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Column(
                        children: widget.fees.map((fee) => _buildFeeItem(context, fee)).toList(),
                      ),
                    ),

                  // View Receipt button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: GestureDetector(
                      onTap: () => context.push('${Routes.transactionDetails}/${payment.payId}'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(
                              'receipt-text',
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'View Receipt',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeItem(BuildContext context, FeeModel fee) {
    final groupName = fee.feeGroupName.isNotEmpty ? fee.feeGroupName : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const AppIcon(
            'tick-circle',
            size: 16,
            color: AppColors.cardGreenDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.feeTypeName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                if (fee.demfeeterm.isNotEmpty || groupName.isNotEmpty)
                  Text(
                    [
                      if (fee.demfeeterm.isNotEmpty) '${fee.demfeeterm} \u{2022} ${fee.demfeeyear}',
                      if (groupName.isNotEmpty) PaidFeesScreen.toTitleCase(groupName),
                    ].join(' \u{2022} '),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textHintC(context),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '\u{20B9} ${NumberFormat('#,##,###').format(fee.paidamount.toInt())}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.cardGreenDark,
            ),
          ),
        ],
      ),
    );
  }
}
