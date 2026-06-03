import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/fee_model.dart';
import '../common/app_card.dart';
import '../common/app_icon.dart';

class FeeSummaryCard extends StatelessWidget {
  final FeeSummary summary;
  final VoidCallback? onPayNowTap;

  const FeeSummaryCard({
    super.key,
    required this.summary,
    this.onPayNowTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s5),
      backgroundColor: AppColors.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Summary',
            style: TextStyle(
              fontSize: AppSizes.textBase,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: 'Total Due',
                  amount: summary.totalDue,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border,
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Paid',
                  amount: summary.totalPaid,
                  color: AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border,
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Pending',
                  amount: summary.totalPending,
                  color: summary.overdueCount > 0
                      ? AppColors.error
                      : AppColors.warning,
                ),
              ),
            ],
          ),
          if (summary.pendingCount > 0 || summary.overdueCount > 0) ...[
            const SizedBox(height: AppSizes.s4),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.s4),
            Row(
              children: [
                if (summary.overdueCount > 0) ...[
                  _buildCountBadge(
                    count: summary.overdueCount,
                    label: 'Overdue',
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSizes.s3),
                ],
                if (summary.pendingCount > 0)
                  _buildCountBadge(
                    count: summary.pendingCount,
                    label: 'Pending',
                    color: AppColors.warning,
                  ),
                const Spacer(),
                if (summary.nextDueDate != null)
                  _buildNextDueDate(),
              ],
            ),
          ],
          if (summary.totalPending > 0 && onPayNowTap != null) ...[
            const SizedBox(height: AppSizes.s4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPayNowTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.s3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.roundedLg),
                  ),
                ),
                child: Text(
                  'Pay Now - ${Formatters.currency(summary.totalPending)}',
                  style: const TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          Formatters.currencyCompact(amount),
          style: TextStyle(
            fontSize: AppSizes.textLg,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: AppSizes.s1),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.textXs,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCountBadge({
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s3,
        vertical: AppSizes.s1,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.roundedFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.s2),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: AppSizes.textXs,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextDueDate() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          'clock',
          size: 14,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: AppSizes.s1),
        Text(
          'Next: ${Formatters.dateShort(summary.nextDueDate!)}',
          style: const TextStyle(
            fontSize: AppSizes.textXs,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
