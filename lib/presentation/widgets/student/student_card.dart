import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/student_model.dart';
import '../common/app_card.dart';
import '../common/app_icon.dart';

class StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback? onTap;
  final bool isSelected;

  const StudentCard({
    super.key,
    required this.student,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      border: Border.all(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: isSelected ? 2 : 1,
      ),
      backgroundColor: isSelected ? AppColors.primary50 : AppColors.bgPrimary,
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: AppSizes.s4),
          Expanded(
            child: _buildStudentInfo(),
          ),
          if (onTap != null)
            AppIcon(
              'arrow-right-1',
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (student.photoUrl != null && student.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(student.photoUrl!),
        backgroundColor: AppColors.gray100,
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.avatarBg,
      child: Text(
        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: AppSizes.textXl,
          fontWeight: FontWeight.bold,
          color: AppColors.avatarText,
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          student.name,
          style: const TextStyle(
            fontSize: AppSizes.textBase,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.s1),
        Row(
          children: [
            if (student.className != null) ...[
              _buildInfoChip(
                'book',
                student.className!,
              ),
              const SizedBox(width: AppSizes.s3),
            ],
            _buildInfoChip(
              'card-tick',
              student.admissionNumber,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(String icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          icon,
          size: 14,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: AppSizes.s1),
        Text(
          text,
          style: const TextStyle(
            fontSize: AppSizes.textXs,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
