import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/payment_model.dart';
import '../common/app_card.dart';
import '../common/app_icon.dart';

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback? onTap;

  const PaymentCard({
    super.key,
    required this.payment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          _buildStatusIcon(),
          const SizedBox(width: AppSizes.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.paymentNumber,
                  style: const TextStyle(
                    fontSize: AppSizes.textSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.s1),
                Text(
                  _getPaymentDescription(),
                  style: const TextStyle(
                    fontSize: AppSizes.textXs,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.s1),
                Text(
                  payment.paidAt != null
                      ? Formatters.dateTime(payment.paidAt!)
                      : Formatters.dateTime(payment.createdAt),
                  style: const TextStyle(
                    fontSize: AppSizes.textXs,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.s3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(payment.amount),
                style: TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: FontWeight.bold,
                  color: _getAmountColor(),
                ),
              ),
              const SizedBox(height: AppSizes.s1),
              _buildStatusBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.roundedLg),
      ),
      child: Center(
        child: AppIcon(
          _getStatusIcon(),
          color: _getStatusColor(),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.roundedFull),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(),
        ),
      ),
    );
  }

  String _getPaymentDescription() {
    if (payment.details.isEmpty) {
      return payment.paymentMethod ?? 'Payment';
    }
    if (payment.details.length == 1) {
      return payment.details.first.feeName ?? 'Fee Payment';
    }
    return '${payment.details.length} fees paid';
  }

  Color _getStatusColor() {
    switch (payment.status) {
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

  Color _getAmountColor() {
    switch (payment.status) {
      case PaymentStatus.success:
        return AppColors.success;
      case PaymentStatus.failed:
        return AppColors.error;
      default:
        return AppColors.textPrimary;
    }
  }

  String _getStatusIcon() {
    switch (payment.status) {
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

  String _getStatusText() {
    switch (payment.status) {
      case PaymentStatus.success:
        return 'Success';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}
