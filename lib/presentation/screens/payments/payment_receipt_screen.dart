import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../core/utils/extensions.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';

class PaymentReceiptScreen extends ConsumerWidget {
  final String paymentId;

  const PaymentReceiptScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(paymentByIdProvider(int.tryParse(paymentId) ?? 0));
    final selectedStudent = ref.watch(selectedStudentProvider);

    return DesktopDetailScaffold(
      isNested: false,
      mobileAppBar: AppBar(
        title: const Text('Payment Receipt'),
        actions: [
          IconButton(
            icon: const AppIcon('share'),
            onPressed: () {
              // TODO: Implement share
            },
          ),
        ],
      ),
      header: _buildDesktopHeader(context, ref),
      toolbar: BreadcrumbBar(
        parentLabel: 'Payment History',
        parentRoute: Routes.paymentHistory,
        currentLabel: 'Payment Receipt',
      ),
      body: paymentAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (payment) {
          if (payment == null) {
            return const Center(child: Text('Payment not found'));
          }

          return SingleChildScrollView(
            padding: context.isDesktop ? const EdgeInsets.all(24) : const EdgeInsets.symmetric(horizontal: 16, vertical: AppSizes.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (context.isDesktop) ...[
                  _buildDesktopGreetingBanner(context),
                  const SizedBox(height: 18),
                  _buildDesktopTitle(context, selectedStudent),
                  const SizedBox(height: 20),
                ],
                _buildReceiptCard(context, payment, selectedStudent?.name ?? ''),
                const SizedBox(height: AppSizes.s4),
                _buildPaymentDetails(context, payment),
                const SizedBox(height: AppSizes.s6),
                AppButton(
                  text: 'Download Receipt',
                  onPressed: () {
                    // TODO: Implement download
                  },
                  icon: Icons.download_rounded,
                  isFullWidth: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopGreetingBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD2913C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Payment receipt — download or share a copy below.',
              style: TextStyle(
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

  Widget _buildDesktopTitle(BuildContext context, dynamic selectedStudent) {
    final firstName =
        (selectedStudent?.name as String?)?.trim().split(' ').first ??
            'Student';
    final admissionNo =
        (selectedStudent?.admissionNumber as String?) ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$firstName's Payment Receipt",
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

  Widget _buildDesktopHeader(BuildContext context, WidgetRef ref) {
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
          Expanded(
            child: Text(
              'Payment Receipt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryC(context),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: Implement share
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const AppIcon('share', size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, PaymentModel payment, String studentName) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s6),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppSizes.roundedXl),
        border: Border.all(color: AppColors.borderC(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _getStatusColor(payment.status).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(
                _getStatusIcon(payment.status),
                size: 32,
                color: _getStatusColor(payment.status),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            payment.status == PaymentStatus.success ? 'Payment Successful' : 'Payment ${payment.status.name}',
            style: TextStyle(
              fontSize: AppSizes.textLg,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(payment.status),
            ),
          ),
          const SizedBox(height: AppSizes.s2),
          Text(
            Formatters.currency(payment.amount),
            style: TextStyle(
              fontSize: AppSizes.text3xl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryC(context),
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s4,
              vertical: AppSizes.s2,
            ),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(AppSizes.roundedFull),
            ),
            child: Text(
              payment.paymentNumber,
              style: TextStyle(
                fontSize: AppSizes.textSm,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryC(context),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          const Divider(),
          const SizedBox(height: AppSizes.s4),
          _buildInfoRow(context, 'Student', studentName),
          _buildInfoRow(context, 'Date', payment.paidAt != null ? Formatters.dateTime(payment.paidAt!) : '-'),
          _buildInfoRow(context, 'Method', payment.paymentMethod ?? '-'),
          if (payment.transactionId != null)
            _buildInfoRow(context, 'Transaction ID', payment.transactionId!),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext context, PaymentModel payment) {
    if (payment.details.isEmpty) return const SizedBox.shrink();

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
            'Fee Breakdown',
            style: TextStyle(
              fontSize: AppSizes.textBase,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryC(context),
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          ...payment.details.map((detail) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  detail.feeName ?? 'Fee',
                  style: TextStyle(
                    fontSize: AppSizes.textSm,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
                Text(
                  Formatters.currency(detail.amount),
                  style: TextStyle(
                    fontSize: AppSizes.textSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: AppSizes.s6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryC(context),
                ),
              ),
              Text(
                Formatters.currency(payment.amount),
                style: const TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
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
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.textSm,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimaryC(context),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
        return AppColors.success;
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.failed:
        return AppColors.error;
      case PaymentStatus.refunded:
        return AppColors.info;
    }
  }

  String _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
        return 'tick-circle';
      case PaymentStatus.pending:
        return 'clock';
      case PaymentStatus.failed:
        return 'close-circle';
      case PaymentStatus.refunded:
        return 'refresh';
    }
  }
}
