import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../config/routes.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_ui.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/app_icon_circle_button.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const PaymentHistoryScreen({super.key, this.initialTab});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  // Mobile background — matches desktop scaffold
  static const Color _cardBg = Color(0xFFFFFDF8);
  static const Color _textDark = Color(0xFF17232B);
  static const Color _textMedium = Color(0xFF4A5A63);

  late String _activeFilter;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final tab = widget.initialTab?.toLowerCase();
    if (tab == 'paid') {
      _activeFilter = 'Paid';
    } else if (tab == 'failed') {
      _activeFilter = 'Failed';
    } else {
      _activeFilter = 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsProvider);

    return Scaffold(
      backgroundColor:
          context.isDesktop ? AppColors.scaffoldBg(context) : AppUi.pageBg,
      body: Column(
        children: [
          // Desktop: no header (MainScaffold top bar handles it).
          // Mobile: the page's own title bar. The filter chips moved down into
          // the scrolling list -- pinned here they pushed the first receipt
          // most of a screen down.
          if (!context.isDesktop)
            Container(
              color: _cardBg,
              child: SafeArea(
                bottom: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: _cardBg,
                    border: Border(bottom: BorderSide(color: AppUi.line)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      _buildHeader(context),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: paymentsAsync.when(
              data: (payments) => _buildTransactionList(payments),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading payments: $e')),
            ),
          ),
        ],
      ),
    );
  }

  List<PaymentModel> _filterPayments(List<PaymentModel> payments) {
    if (_activeFilter == 'All') return payments;
    if (_activeFilter == 'Paid') {
      return payments.where((p) => p.paystatus == 'C').toList();
    }
    if (_activeFilter == 'Failed') {
      return payments.where((p) => p.paystatus == 'F').toList();
    }
    return payments;
  }

  Widget _buildTransactionList(List<PaymentModel> payments) {
    final filtered = _filterPayments(payments);

    const int pageSize = 10;
    final totalPages = filtered.isEmpty ? 0 : (filtered.length / pageSize).ceil();
    final paged = filtered.isEmpty ? <PaymentModel>[] : filtered.skip(_currentPage * pageSize).take(pageSize).toList();

    if (context.isDesktop) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopGreetingBanner(context, payments),
            const SizedBox(height: 18),
            _buildDesktopTitle(context),
            const SizedBox(height: 20),
            _buildDesktopStatCards(context, payments),
            const SizedBox(height: 20),
            // Filter + table card (existing layout)
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.cardShadow(context),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Filter tab band — white background so it stands out from page bg
                  Container(
                    width: double.infinity,
                    color: AppColors.cardBg(context),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    child: _buildFilterTabs(['All', 'Paid', 'Failed']),
                  ),
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else ...[
                    _buildDesktopTable(paged),
                    _buildPaginationControls(totalPages),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile: a summary, the filters, then the receipts grouped by day.
    // Dates on every row made a week of attempts read as one undifferentiated
    // wall; the day headings are what turn it back into a history.
    final paid = payments.where((p) => p.paystatus == 'C').toList();
    final paidTotal = paid.fold<double>(0, (t, p) => t + p.transtotalamount);

    final groups = <String, List<PaymentModel>>{};
    for (final p in filtered) {
      groups.putIfAbsent(_dayLabel(p.paydate ?? p.createdat), () => []).add(p);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: AppUi.fill,
            borderRadius: BorderRadius.circular(AppUi.radius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total paid this year',
                      style: TextStyle(fontSize: 13, color: AppUi.inkMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${NumberFormat('#,##,###').format(paidTotal.toInt())}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                        color: AppUi.ink,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${paid.length} payment${paid.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 13, color: AppUi.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildFilterChips(payments),
        const SizedBox(height: 18),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildEmptyState(),
          )
        else
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 2),
              child: Text(
                entry.key,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppUi.inkMuted),
              ),
            ),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: AppUi.cardBox(),
              child: Column(
                children: [
                  for (int i = 0; i < entry.value.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Divider(height: 1, color: AppUi.lineSoft),
                      ),
                    _buildTransactionCard(entry.value[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],
      ],
    );
  }

  /// 'Today', 'Yesterday', or the date -- the heading a day's receipts sit under.
  String _dayLabel(DateTime when) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(when);
  }

  /// Filter pills carrying their counts, so the parent knows what is behind a
  /// tab before tapping it (and that an empty one is empty).
  Widget _buildFilterChips(List<PaymentModel> payments) {
    final counts = {
      'All': payments.length,
      'Paid': payments.where((p) => p.paystatus == 'C').length,
      'Failed': payments.where((p) => p.paystatus == 'F').length,
    };

    return Row(
      children: [
        for (final entry in counts.entries) ...[
          GestureDetector(
            onTap: () => setState(() {
              _activeFilter = entry.key;
              _currentPage = 0;
            }),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: _activeFilter == entry.key ? AppUi.navy : AppUi.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: _activeFilter == entry.key
                        ? AppUi.navy
                        : AppUi.line),
              ),
              child: Text(
                '${entry.key} ${entry.value}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _activeFilter == entry.key
                      ? Colors.white
                      : AppUi.inkMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildDesktopGreetingBanner(
      BuildContext context, List<PaymentModel> payments) {
    final successful = payments.where((p) => p.paystatus == 'C').length;
    final hasPayments = successful > 0;
    final message = hasPayments
        ? "Great! You've made $successful successful "
            "${successful == 1 ? 'payment' : 'payments'}."
        : "No successful payments yet. Start by clearing a fee.";
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

  Widget _buildDesktopTitle(BuildContext context) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final firstName =
        (selectedStudent?.name as String?)?.trim().split(' ').first ??
            'Student';
    final admissionNo =
        (selectedStudent?.admissionNumber as String?) ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$firstName's Payment History",
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

  Widget _buildDesktopStatCards(
      BuildContext context, List<PaymentModel> payments) {
    final successful = payments.where((p) => p.paystatus == 'C').toList();
    final failed = payments.where((p) => p.paystatus == 'F').toList();
    final totalPaid =
        successful.fold<double>(0, (sum, p) => sum + p.amount);
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Total Paid',
            value: '₹${NumberFormat('#,##,###').format(totalPaid.toInt())}',
            icon: 'wallet-3',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Successful',
            value: '${successful.length}',
            icon: 'tick-circle',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Failed',
            value: '${failed.length}',
            icon: 'close-circle',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Total Records',
            value: '${payments.length}',
            icon: 'receipt-text',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
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

  Widget _buildHeader(BuildContext context) {
    final cartItemCount = ref.watch(cartItemCountProvider);
    final notificationCount = ref.watch(notificationCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // The greeting belongs on Home. Here the parent already knows who
          // they are -- what they need is the name of the page they are on.
          const Expanded(
            child: Text(
              'History',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppUi.ink,
                letterSpacing: -0.4,
              ),
            ),
          ),
          _buildHeaderIcon(
            svgPath: 'assets/icons/Cart.svg',
            badgeCount: cartItemCount,
            onTap: () => context.push(Routes.cart),
          ),
          const SizedBox(width: 8),
          _buildHeaderIcon(
            svgPath: 'assets/main icons/line icons/notification.svg',
            badgeCount: notificationCount,
            onTap: () => context.go(Routes.notifications),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon({
    IconData? icon,
    String? svgPath,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return AppIconCircleButton(
      onPressed: onTap,
      badgeCount: badgeCount,
      icon: svgPath != null
          ? SvgPicture.asset(
              svgPath,
              width: 20,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            )
          : Icon(icon, size: 20, color: Colors.white),
    );
  }

  Widget _buildFilterTabs(List<String> filters) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE9DC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: filters.map((filter) {
          final isActive = _activeFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeFilter = filter;
                  _currentPage = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  // Active filter chip = amber filled + amber glow (matches the
                  // app's amber action affordances)
                  color: isActive ? AppColors.buttonPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.buttonPrimary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? Colors.white : _textMedium,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionCard(PaymentModel payment) {
    final isSuccess = payment.paystatus == 'C';
    final when = payment.paydate ?? payment.createdat;

    void open() {
      if (isSuccess && !payment.isReconciled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Receipt is pending approval. Please wait for admin to approve.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      context.push('/payment-history/${payment.payId}');
    }

    return InkWell(
      onTap: open,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSuccess ? AppUi.paidBg : AppUi.failBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppIcon(
                  isSuccess ? 'tick-circle' : 'close-circle',
                  size: 18,
                  color: isSuccess ? AppUi.paidInk : AppUi.failInk,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    payment.paynumber ?? 'PAY/${payment.payId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppUi.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      payment.statusText,
                      DateFormat('d MMM yyyy, h:mm a').format(when),
                      if (isSuccess && (payment.paymethod ?? '').trim().isNotEmpty)
                        payment.paymethod!.trim(),
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppUi.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Neutral, not red: a failed attempt printed in red reads as
                // money that left the account. The chip line says what happened.
                Text(
                  '₹${NumberFormat('#,##,###').format(payment.transtotalamount.toInt())}',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: isSuccess ? AppUi.ink : AppUi.inkMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // A failed attempt leaves its fees pending, so "Retry" means
                  // picking them again -- there is nothing to re-submit.
                  onTap: isSuccess
                      ? open
                      : () => context.push(Routes.allPendingFees),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSuccess) ...[
                        const AppIcon('receipt', size: 13, color: AppUi.link),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isSuccess ? 'Receipt' : 'Retry',
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppUi.link),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous
          _buildPageButton(
            icon: 'arrow-left-1',
            enabled: _currentPage > 0,
            onTap: () => setState(() => _currentPage--),
          ),
          const SizedBox(width: 8),
          // Page numbers
          for (int i = 0; i < totalPages; i++) ...[
            if (i == 0 || i == totalPages - 1 || (i >= _currentPage - 1 && i <= _currentPage + 1))
              GestureDetector(
                onTap: () => setState(() => _currentPage = i),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i == _currentPage ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: i != _currentPage
                        ? Border.all(color: AppColors.borderC(context))
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: i == _currentPage
                            ? Colors.white
                            : AppColors.textSecondaryC(context),
                      ),
                    ),
                  ),
                ),
              )
            else if ((i == 1 && _currentPage > 2) ||
                (i == totalPages - 2 && _currentPage < totalPages - 3))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('…', style: TextStyle(color: AppColors.textHintC(context))),
              ),
          ],
          const SizedBox(width: 8),
          // Next
          _buildPageButton(
            icon: 'arrow-right-1',
            enabled: _currentPage < totalPages - 1,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required String icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderC(context)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: AppIcon(
            icon,
            size: 20,
            color: enabled
                ? AppColors.textPrimaryC(context)
                : AppColors.textHintC(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<PaymentModel> payments) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header row
          Container(
            color: AppColors.filterBg(context),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('Date', style: _tableHeaderStyle(context)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Payment No', style: _tableHeaderStyle(context)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Method', style: _tableHeaderStyle(context)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Amount', style: _tableHeaderStyle(context), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Status', style: _tableHeaderStyle(context), textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text('Receipt', style: _tableHeaderStyle(context), textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
            // Data rows
            ...payments.asMap().entries.map((entry) {
              final index = entry.key;
              final payment = entry.value;
              final isSuccess = payment.paystatus == 'C';
              final isLast = index == payments.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      if (isSuccess && !payment.isReconciled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Receipt is pending approval. Please wait for admin to approve.'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      context.push('/payment-history/${payment.payId}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          // Date
                          Expanded(
                            flex: 2,
                            child: Text(
                              DateFormat('dd MMM yyyy').format(payment.paydate ?? payment.createdat),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryC(context),
                              ),
                            ),
                          ),
                          // Payment No
                          Expanded(
                            flex: 3,
                            child: Text(
                              payment.paynumber ?? 'PAY/${payment.payId}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryC(context),
                              ),
                            ),
                          ),
                          // Method
                          Expanded(
                            flex: 2,
                            child: Text(
                              isSuccess ? (payment.paymethod ?? '—') : '—',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryC(context),
                              ),
                            ),
                          ),
                          // Amount
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹${NumberFormat('#,##,###').format(payment.transtotalamount.toInt())}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSuccess ? AppColors.textPrimaryC(context) : AppColors.error,
                              ),
                            ),
                          ),
                          // Status badge
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSuccess ? AppColors.cardGreen : AppColors.cardRose,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  payment.statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSuccess ? AppColors.cardGreenDark : AppColors.cardRoseDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Receipt column
                          SizedBox(
                            width: 60,
                            child: isSuccess
                                ? payment.isReconciled
                                    ? IconButton(
                                        icon: AppIcon('document-download', size: 20, color: AppColors.primary),
                                        tooltip: 'Download Receipt',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => context.push('/payment-history/${payment.payId}'),
                                      )
                                    : Text(
                                        'Pending',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: AppColors.borderC(context).withValues(alpha: 0.5)),
                ],
              );
            }),
          ],
        ),
    );
  }

  TextStyle _tableHeaderStyle(BuildContext context) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryC(context),
        letterSpacing: 0.3,
      );

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    String icon;
    Color iconBgColor;
    Color iconColor;

    switch (_activeFilter) {
      case 'Paid':
        title = 'No Paid Payments';
        subtitle = 'Your successful payments will appear here.';
        icon = 'tick-circle';
        iconBgColor = AppColors.cardGreen;
        iconColor = AppColors.cardGreenDark;
        break;
      case 'Failed':
        title = 'No Failed Payments';
        subtitle = 'Failed payment attempts will appear here.';
        icon = 'close-circle';
        iconBgColor = AppColors.cardRose;
        iconColor = AppColors.cardRoseDark;
        break;
      default:
        title = 'No Payments Yet';
        subtitle = 'Your payment history will appear here once you make a payment.';
        icon = 'receipt-text';
        iconBgColor = AppColors.cardPurple;
        iconColor = AppColors.cardPurpleDark;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: AppIcon(icon, size: 48, color: iconColor)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.isDesktop ? AppColors.textPrimaryC(context) : _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.isDesktop ? AppColors.textSecondaryC(context) : _textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
