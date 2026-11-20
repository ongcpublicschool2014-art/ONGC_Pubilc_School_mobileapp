import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/institution_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import 'app_icon.dart';

/// App Drawer widget that slides in from the left
/// Contains school info, user profile, menu items, and logout button
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final institutionAsync = ref.watch(selectedStudentWithInstitutionProvider);
    final institution = institutionAsync.valueOrNull;

    return Drawer(
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 52),
          child: Column(
            children: [
              // Top Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // School Header with Close Button
                    _buildSchoolHeader(context, institution),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    // User Profile
                    _buildUserProfile(selectedStudent),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    // Menu Items
                    _buildMenuItem(
                      context: context,
                      icon: 'lock',
                      label: 'Change Password',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(Routes.forgotPassword);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      context: context,
                      icon: '24-support',
                      label: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(Routes.support);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      context: context,
                      icon: 'setting-2',
                      label: 'Setting',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to settings screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings - Coming Soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Bottom Section
              Column(
                children: [
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildLogoutButton(context, ref),
                  const SizedBox(height: 24),
                  _buildSchoolFooter(institution),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolHeader(BuildContext context, InstitutionModel? institution) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // School Logo
              Container(
                padding: const EdgeInsets.all(5),
                child: CustomPaint(
                  size: const Size(30, 30),
                  painter: _SchoolLogoPainter(),
                ),
              ),
              const SizedBox(width: 4),
              // School Name and Address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      institution?.name ?? 'School Name',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        height: 1.47,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      institution?.shortAddress ?? 'Address not available',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Close Button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A979D).withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: const Color(0xFF0A4D47).withValues(alpha: 0.75),
                  blurRadius: 1,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: const Center(
              child: AppIcon(
                'close-circle',
                size: 24,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile(dynamic selectedStudent) {
    final String studentName = selectedStudent?.name ?? 'Robert';
    final String className = selectedStudent?.className ?? '10-B';
    final String initials = studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S';

    return Row(
      children: [
        // User Avatar
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary100,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // User Info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(
                studentName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Row(
              children: [
                const Text(
                  'Section: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                Text(
                  className,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            AppIcon(
              icon,
              size: 24,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                height: 1.47,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFE1F0EC),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE6E2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A979D).withValues(alpha: 0.1),
              blurRadius: 40,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: const Color(0xFF0A4D47).withValues(alpha: 0.75),
              blurRadius: 1,
              offset: Offset.zero,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFFC8453A),
                height: 1.47,
              ),
            ),
            SizedBox(width: 8),
            AppIcon(
              'logout',
              size: 24,
              color: Color(0xFFC8453A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolFooter(InstitutionModel? institution) {
    return Column(
      children: [
        // School Name
        Text(
          institution?.name ?? 'School Name',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // School Location
        Text(
          institution?.shortAddress ?? 'Location not available',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close drawer
              ref.read(authProvider.notifier).signOut();
              context.go(Routes.welcome);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for school logo (V shape)
class _SchoolLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F6B63)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Draw V shape
    path.moveTo(size.width * 0.5, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width * 0.25, 0);
    path.lineTo(size.width * 0.5, size.height * 0.6);
    path.lineTo(size.width * 0.75, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
