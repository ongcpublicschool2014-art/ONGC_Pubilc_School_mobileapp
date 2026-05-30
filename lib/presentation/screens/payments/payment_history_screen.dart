import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../config/routes.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common/app_icon.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const PaymentHistoryScreen({super.key, this.initialTab});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  // Mobile background — matches desktop scaffold
  static const Color _bg = Color(0xFFF1F5F9);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFE8E7E4);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMedium = Color(0xFF6B6B6B);
  static const Color _textLight = Color(0xFF6B6B6B);

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
    final filters = ['All', 'Paid', 'Failed'];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Column(
        children: [
          // Desktop: no header (MainScaffold top bar handles it) | Mobile: shadow header
          if (!context.isDesktop)
            Container(
              color: _cardBg,
              child: SafeArea(
                bottom: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: _cardBg,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildHeader(context),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildFilterTabs(filters),
                      ),
                      const SizedBox(height: 16),
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

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    // Mobile: show all filtered items in a scrollable list (no pagination)
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildTransactionCard(filtered[index]),
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
    final selectedStudent = ref.watch(selectedStudentProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final notificationCount = ref.watch(notificationCountProvider);
    final studentName = selectedStudent?.name ?? 'Student';
    final className = selectedStudent?.className ?? 'N/A';
    final courseName = selectedStudent?.courseName ?? 'N/A';
    final hasPhoto = selectedStudent != null &&
        selectedStudent.photoUrl != null &&
        selectedStudent.photoUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => context.go(Routes.profile),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: selectedStudent.photoUrl!,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          _getInitials(studentName),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(studentName),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$courseName | $className',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textLight),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hey, ${studentName.split(' ').first}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark, letterSpacing: -0.3),
                ),
              ],
            ),
          ),
          // Cart icon
          _buildHeaderIcon(
            svgPath: 'assets/icons/Cart.svg',
            badgeCount: cartItemCount,
            onTap: () => context.push(Routes.cart),
          ),
          const SizedBox(width: 8),
          // Notification icon
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFD2913C),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            svgPath != null
                ? SvgPicture.asset(svgPath, width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))
                : Icon(icon, size: 20, color: Colors.white),
            if (badgeCount > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildFilterTabs(List<String> filters) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFEC),
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
                  color: isActive ? const Color(0xFFD2913C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? const [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
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

    return GestureDetector(
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
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main content area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? AppColors.cardGreen
                          : AppColors.cardRose,
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon(
                      isSuccess ? 'tick-circle' : 'close-circle',
                      size: 18,
                      color: isSuccess
                          ? AppColors.cardGreenDark
                          : AppColors.cardRoseDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Payment number + Year + Method
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.paynumber ?? 'PAY/${payment.payId}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          payment.yrlabel ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _textLight,
                          ),
                        ),
                        if (isSuccess && payment.paymethod != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            payment.paymethod!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: _textLight,
                          ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status badge + Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? AppColors.cardGreen
                              : AppColors.cardRose,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          payment.statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSuccess
                                ? AppColors.cardGreenDark
                                : AppColors.cardRoseDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹ ${NumberFormat('#,##,###').format(payment.transtotalamount.toInt())}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSuccess
                              ? _textDark
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Divider
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            // Date row with chevron
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  AppIcon(
                    'calendar',
                    size: 14,
                    color: _textLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(
                      payment.paydate ?? payment.createdat,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _textLight,
                    ),
                  ),
                  const Spacer(),
                  AppIcon(
                    'arrow-right-1',
                    size: 20,
                    color: _textLight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPaginationControls(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();
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
