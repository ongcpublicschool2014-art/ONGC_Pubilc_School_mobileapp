import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../config/routes.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../core/utils/extensions.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';

class FeeDetailsScreen extends ConsumerWidget {
  final String feeId;

  const FeeDetailsScreen({super.key, required this.feeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(feesProvider);

    return DesktopDetailScaffold(
      isNested: true,
      mobileAppBar: AppBar(
        title: const Text('Fee Details'),
      ),
      header: _buildDesktopHeader(context),
      toolbar: const BreadcrumbBar(currentLabel: 'Fee Details'),
      body: feesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (fees) {
          final fee = fees.firstWhere(
            (f) => f.id == feeId,
            orElse: () => throw Exception('Fee not found'),
          );

          return SingleChildScrollView(
            padding: context.isDesktop ? const EdgeInsets.all(24) : const EdgeInsets.symmetric(horizontal: 16, vertical: AppSizes.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (context.isDesktop) ...[
                  _buildDesktopGreetingBanner(context, fee),
                  const SizedBox(height: 18),
                  _buildDesktopTitle(context, ref, fee),
                  const SizedBox(height: 20),
                ],
                _buildFeeHeader(context, fee),
                const SizedBox(height: AppSizes.s4),
                _buildFeeDetails(context, fee),
                const SizedBox(height: AppSizes.s4),
                _buildPaymentBreakdown(context, fee),
                if (fee.status != FeeStatus.paid) ...[
                  const SizedBox(height: AppSizes.s6),
                  AppButton(
                    text: 'Pay Now - ${Formatters.currency(fee.balanceAmount)}',
                    onPressed: () {
                      final cart = ref.read(cartProvider.notifier);
                      if (!ref.read(cartProvider).containsFee(fee.id)) {
                        cart.addFee(fee);
                      }
                      context.go(Routes.cart);
                    },
                    isFullWidth: true,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopGreetingBanner(BuildContext context, FeeModel fee) {
    final isPaid = fee.status == FeeStatus.paid;
    final message = isPaid
        ? 'This fee is fully paid. View the breakdown below.'
        : 'Outstanding ${Formatters.currency(fee.balanceAmount)} on this fee.';
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

  Widget _buildDesktopTitle(
      BuildContext context, WidgetRef ref, FeeModel fee) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final firstName =
        selectedStudent?.name.trim().split(' ').first ?? 'Student';
    final admissionNo = selectedStudent?.admissionNumber ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$firstName's Fee Details",
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

  Widget _buildDesktopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const AppIcon('arrow-left-1', size: 16, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Fee Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryC(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeHeader(BuildContext context, FeeModel fee) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppSizes.roundedXl),
        border: Border.all(color: AppColors.borderC(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getStatusColor(fee.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.roundedLg),
            ),
            child: AppIcon(
              _getStatusIcon(fee.status),
              color: _getStatusColor(fee.status),
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.feeTypeName,
                  style: TextStyle(
                    fontSize: AppSizes.textLg,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(height: AppSizes.s1),
                Text(
                  fee.term,
                  style: TextStyle(
                    fontSize: AppSizes.textSm,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(fee.status),
        ],
      ),
    );
  }

  Widget _buildFeeDetails(BuildContext context, FeeModel fee) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppSizes.roundedXl),
        border: Border.all(color: AppColors.borderC(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Details',
            style: TextStyle(
              fontSize: AppSizes.textBase,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryC(context),
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          _buildDetailRow(context, 'Due Date', Formatters.date(fee.dueDate)),
          _buildDetailRow(context, 'Base Amount', Formatters.currency(fee.amount)),
          if (fee.discountAmount > 0)
            _buildDetailRow(context, 'Discount', '- ${Formatters.currency(fee.discountAmount)}', valueColor: AppColors.success),
          if (fee.lateFee > 0)
            _buildDetailRow(context, 'Late Fee', '+ ${Formatters.currency(fee.lateFee)}', valueColor: AppColors.error),
          const Divider(height: AppSizes.s6),
          _buildDetailRow(context, 'Total Amount', Formatters.currency(fee.totalAmount), isBold: true),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(BuildContext context, FeeModel fee) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppSizes.roundedXl),
        border: Border.all(color: AppColors.borderC(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: AppSizes.textBase,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryC(context),
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          _buildDetailRow(context, 'Amount Paid', Formatters.currency(fee.paidAmount), valueColor: AppColors.success),
          _buildDetailRow(context, 'Balance Due', Formatters.currency(fee.balanceAmount), valueColor: fee.balanceAmount > 0 ? AppColors.error : AppColors.success),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.textSm,
              color: AppColors.textSecondaryC(context),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.textSm,
              color: valueColor ?? AppColors.textPrimaryC(context),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(FeeStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s3,
        vertical: AppSizes.s1,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.roundedFull),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Color _getStatusColor(FeeStatus status) {
    switch (status) {
      case FeeStatus.paid:
        return AppColors.success;
      case FeeStatus.pending:
        return AppColors.warning;
      case FeeStatus.overdue:
        return AppColors.error;
      case FeeStatus.partial:
        return AppColors.info;
    }
  }

  String _getStatusIcon(FeeStatus status) {
    switch (status) {
      case FeeStatus.paid:
        return 'tick-circle';
      case FeeStatus.pending:
        return 'clock';
      case FeeStatus.overdue:
        return 'warning-2';
      case FeeStatus.partial:
        return 'timer';
    }
  }

  String _getStatusText(FeeStatus status) {
    switch (status) {
      case FeeStatus.paid:
        return 'Paid';
      case FeeStatus.pending:
        return 'Pending';
      case FeeStatus.overdue:
        return 'Overdue';
      case FeeStatus.partial:
        return 'Partial';
    }
  }
}
