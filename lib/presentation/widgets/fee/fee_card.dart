import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/fee_model.dart';
import '../common/app_card.dart';
import '../common/app_icon.dart';

class FeeCard extends StatelessWidget {
  final FeeModel fee;
  final VoidCallback? onTap;

  const FeeCard({
    super.key,
    required this.fee,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: AppSizes.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fee.feeTypeName,
                      style: const TextStyle(
                        fontSize: AppSizes.textBase,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s1),
                    Text(
                      fee.term,
                      style: const TextStyle(
                        fontSize: AppSizes.textXs,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(fee.balanceAmount),
                    style: TextStyle(
                      fontSize: AppSizes.textLg,
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
          if (fee.status != FeeStatus.paid) ...[
            const SizedBox(height: AppSizes.s3),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.s3),
            _buildDueDateInfo(),
          ],
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

  Widget _buildDueDateInfo() {
    return Row(
      children: [
        AppIcon(
          'calendar',
          size: 14,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: AppSizes.s2),
        Text(
          Formatters.dueDate(fee.dueDate),
          style: TextStyle(
            fontSize: AppSizes.textXs,
            color: fee.status == FeeStatus.overdue
                ? AppColors.error
                : AppColors.textSecondary,
            fontWeight: fee.status == FeeStatus.overdue
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
        const Spacer(),
        if (fee.paidAmount > 0) ...[
          Text(
            'Paid: ${Formatters.currency(fee.paidAmount)}',
            style: const TextStyle(
              fontSize: AppSizes.textXs,
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor() {
    switch (fee.status) {
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

  Color _getAmountColor() {
    if (fee.status == FeeStatus.paid) return AppColors.success;
    if (fee.status == FeeStatus.overdue) return AppColors.error;
    return AppColors.textPrimary;
  }

  String _getStatusIcon() {
    switch (fee.status) {
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

  String _getStatusText() {
    switch (fee.status) {
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
