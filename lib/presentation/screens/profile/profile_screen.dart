import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/student_model.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/institution_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/header_icon_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Profile palette — uses app primary colors
  static const Color _bg = Color(0xFFF1F5F9);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Colors.transparent;
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMedium = Color(0xFF6B6B6B);
  static const Color _textLight = Color(0xFF6B6B6B);
  static const Color _divider = Color(0xFFD6F5E5);
  static const Color _iconBg = Color(0xFFF1F5F9);

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: _cardBg,
        title: const Text('Sign Out', style: TextStyle(color: _textDark)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: _textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: _textMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(authProvider.notifier).signOut();
              context.go(Routes.welcome);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final currentParent = ref.watch(currentParentProvider);
    final hasMultipleStudents = ref.watch(hasMultipleStudentsProvider);

    final Map<String, String> studentData = selectedStudent != null
        ? {
            'name': selectedStudent.name,
            'class': selectedStudent.className,
            'adminNo': selectedStudent.admissionNumber,
            'gender': selectedStudent.gender,
            'dob': _formatDate(selectedStudent.dateOfBirth),
            'blood': StudentModel.hasValue(selectedStudent.stubloodgrp) ? selectedStudent.stubloodgrp! : 'N/A',
            'mobile': StudentModel.hasValue(currentParent?.payinchargemob) ? currentParent!.payinchargemob! : 'N/A',
            'email': StudentModel.hasValue(currentParent?.paremail) ? currentParent!.paremail! : 'N/A',
            'address': selectedStudent.fullAddress.isNotEmpty ? selectedStudent.fullAddress : 'N/A',
            'parentName': StudentModel.hasValue(currentParent?.payincharge) ? currentParent!.payincharge! : 'N/A',
          }
        : {
            'name': 'Student',
            'class': 'N/A',
            'adminNo': 'N/A',
            'gender': 'N/A',
            'dob': 'N/A',
            'blood': 'N/A',
            'mobile': 'N/A',
            'email': 'N/A',
            'address': 'N/A',
            'parentName': 'N/A',
          };

    if (context.isDesktop) {
      return _buildDesktopProfile(context, studentData, hasMultipleStudents);
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Column(
        children: [
          // Header with white background
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildHeader(context, studentData),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // School info card
                    _buildSchoolInfoCard(context),
                    const SizedBox(height: 16),
                    // Student summary grid card
                    _buildStudentSummaryCard(studentData),
                    const SizedBox(height: 16),
                    // Quick actions
                    _buildQuickActionsCard(context, hasMultipleStudents),
                    const SizedBox(height: 16),
                    // Contact info card
                    _buildContactCard(studentData),
                    const SizedBox(height: 16),
                    // Sign out
                    _buildSignOutButton(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header — greeting + action icons (reference style)
  Widget _buildHeader(BuildContext context, Map<String, String> studentData) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final hasPhoto = selectedStudent != null && selectedStudent.photoUrl != null && selectedStudent.photoUrl!.isNotEmpty;
    final cartItemCount = ref.watch(cartItemCountProvider);
    final notificationCount = ref.watch(notificationCountProvider);
    final firstName = studentData['name']!.split(' ').first;
    final bool isDesktop = context.isDesktop;

    final headerRow = Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () => _showProfileImagePopup(
            context,
            studentData['name']!,
            hasPhoto ? selectedStudent.photoUrl! : null,
          ),
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
                    placeholder: (context, url) => Center(
                      child: Text(
                        _getInitials(studentData['name']!),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        _getInitials(studentData['name']!),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      _getInitials(studentData['name']!),
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
                studentData['class']!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textLight),
              ),
              const SizedBox(height: 2),
              Text(
                'Hey, $firstName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark, letterSpacing: -0.3),
              ),
            ],
          ),
        ),
        // Cart + notification icons — mobile only (global header handles them on desktop)
        if (!isDesktop) ...[
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
      ],
    );

    // On desktop, wrap the greeting row in a card; on mobile, keep it bare
    if (!isDesktop) return headerRow;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderC(context)),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: headerRow,
    );
  }

  Widget _buildHeaderIcon({
    IconData? icon,
    String? svgPath,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return HeaderIconButton(
      icon: icon,
      svgPath: svgPath,
      badgeCount: badgeCount,
      onTap: onTap,
    );
  }

  /// Student summary — 2x3 grid card like the "Content Generation Activity" in the reference
  Widget _buildStudentSummaryCard(Map<String, String> studentData) {
    final items = [
      _GridStat(value: studentData['adminNo']!, label: 'Admission No'),
      _GridStat(value: studentData['class']!, label: 'Class'),
      _GridStat(value: studentData['dob']!, label: 'Date of Birth'),
      _GridStat(value: studentData['gender']!, label: 'Gender'),
      _GridStat(value: studentData['blood']!, label: 'Blood Group'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: const Text(
              'Student Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark),
            ),
          ),
          const SizedBox(height: 16),
          // Two-column grid — built dynamically so it adapts to the
          // number of stats (odd counts leave the last slot empty).
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i += 2) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildStatCell(items[i])),
                      Expanded(
                        child: i + 1 < items.length
                            ? _buildStatCell(items[i + 1])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(_GridStat stat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _iconBg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            stat.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textLight),
          ),
        ],
      ),
    );
  }

  /// School info — compact card with logo, name, address
  Widget _buildSchoolInfoCard(BuildContext context) {
    final institutionAsync = ref.watch(selectedStudentInstitutionProvider);
    final institution = institutionAsync.valueOrNull;
    final schoolName = institution?.name ?? 'School';
    final schoolAddress = institution?.shortAddress ?? 'Address not available';
    final logoUrl = institution?.logoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // School logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: _cardBorder),
            ),
            child: ClipOval(
              child: hasLogo
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: AppIcon('book', size: 24, color: _textMedium),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: AppIcon('book', size: 24, color: _textMedium),
                      ),
                    )
                  : const Center(
                      child: AppIcon('book', size: 24, color: _textMedium),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schoolName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const AppIcon('location', size: 13, color: _textLight),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        schoolAddress,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contact info card — list style like "Top Creators" in reference
  Widget _buildContactCard(Map<String, String> studentData) {
    final contacts = [
      _ContactRow(svgPath: 'assets/icons/user.svg', label: 'Student In-Charge', value: studentData['parentName']!),
      _ContactRow(svgPath: 'assets/icons/mobile.svg', label: 'Mobile', value: studentData['mobile']!),
      _ContactRow(svgPath: 'assets/icons/envelope.svg', label: 'Email', value: studentData['email']!),
      _ContactRow(svgPath: 'assets/icons/Location.svg', label: 'Address', value: studentData['address']!),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: const Text(
              'Contact Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark),
            ),
          ),
          const SizedBox(height: 8),
          // List items
          ...contacts.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;
            final isLast = index == contacts.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _iconBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _cardBorder),
                        ),
                        child: Center(
                          child: contact.svgPath != null
                              ? SvgPicture.asset(contact.svgPath!, width: 18, height: 18, colorFilter: const ColorFilter.mode(_textMedium, BlendMode.srcIn))
                              : Icon(contact.icon, size: 18, color: _textMedium),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.label,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textLight),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              contact.value == 'N/A' ? 'Not provided' : contact.value,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: contact.value == 'N/A' ? _textLight : _textDark,
                                fontStyle: contact.value == 'N/A' ? FontStyle.italic : FontStyle.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: _divider),
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Quick actions — minimal buttons
  Widget _buildQuickActionsCard(BuildContext context, bool hasMultipleStudents) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (hasMultipleStudents) ...[
            Expanded(
              child: _buildMinimalButton(
                iconName: 'arrow-swap-horizontal',
                label: 'Switch Student',
                filled: true,
                onTap: () => context.push(Routes.switchStudent),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: _buildMinimalButton(
              iconName: '24-support',
              label: 'Get Support',
              filled: !hasMultipleStudents,
              onTap: () => context.push(Routes.support),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalButton({
    required String iconName,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final fg = filled ? Colors.white : const Color(0xFFD2913C);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: const Color(0xFFD2913C).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: filled ? const Color(0xFFD2913C) : _cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.black.withValues(alpha: filled ? 0.06 : 0.04),
          focusColor: Colors.black.withValues(alpha: filled ? 0.10 : 0.08),
          splashColor: Colors.black.withValues(alpha: filled ? 0.22 : 0.14),
          highlightColor: Colors.black.withValues(alpha: filled ? 0.12 : 0.06),
          mouseCursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: filled
                  ? null
                  : Border.all(color: const Color(0xFFD2913C), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(iconName, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(14),
        hoverColor: AppColors.error.withValues(alpha: 0.04),
        focusColor: AppColors.error.withValues(alpha: 0.08),
        splashColor: AppColors.error.withValues(alpha: 0.14),
        highlightColor: AppColors.error.withValues(alpha: 0.06),
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardBorder),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon('logout', size: 18, color: _textMedium),
              SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Desktop layout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildDesktopProfile(
      BuildContext context, Map<String, String> studentData, bool hasMultipleStudents) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column 1 — student profile card, student details, action buttons
            Expanded(
              child: Column(
                children: [
                  _buildHeader(context, studentData),
                  const SizedBox(height: 16),
                  _buildStudentSummaryCard(studentData),
                  const SizedBox(height: 16),
                  _buildDesktopActionButtons(context, hasMultipleStudents),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Column 2 — institution detail + contact information
            Expanded(
              child: Column(
                children: [
                  _buildDesktopSchoolCard(context),
                  const SizedBox(height: 16),
                  _buildContactCard(studentData),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Desktop action buttons — side-by-side in a single row
  Widget _buildDesktopActionButtons(BuildContext context, bool hasMultipleStudents) {
    return Row(
      children: [
        if (hasMultipleStudents) ...[
          Expanded(
            child: _buildDesktopActionButton(
              iconName: 'arrow-swap-horizontal',
              label: 'Switch Student',
              onTap: () => context.push(Routes.switchStudent),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: _buildDesktopActionButton(
            iconName: '24-support',
            label: 'Get Support',
            onTap: () => context.push(Routes.support),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopActionButton({
    required String iconName,
    required String label,
    required VoidCallback onTap,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD2913C).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFFD2913C),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.black.withValues(alpha: 0.06),
          focusColor: Colors.black.withValues(alpha: 0.10),
          splashColor: Colors.black.withValues(alpha: 0.22),
          highlightColor: Colors.black.withValues(alpha: 0.12),
          mouseCursor: SystemMouseCursors.click,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(iconName, size: 20, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSchoolCard(BuildContext context) {
    final institutionAsync = ref.watch(selectedStudentInstitutionProvider);
    final institution = institutionAsync.valueOrNull;
    final schoolName = institution?.name ?? 'School';
    final schoolAddress = institution?.shortAddress ?? 'Address not available';
    final schoolEmail = institution?.email;
    final schoolPhone = institution?.phone;
    final schoolMotto = institution?.motto;
    final logoUrl = institution?.logoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasLogo
                        ? CachedNetworkImage(
                            imageUrl: logoUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: AppIcon('book', size: 24, color: _textMedium),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: AppIcon('book', size: 24, color: _textMedium),
                            ),
                          )
                        : const Center(
                            child: AppIcon('book', size: 24, color: _textMedium),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const AppIcon('location', size: 14, color: _textLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              schoolAddress,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textLight),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (schoolMotto != null && schoolMotto.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _cardBorder),
                ),
                child: Row(
                  children: [
                    const AppIcon('quote-up', size: 18, color: _textLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        schoolMotto,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: _textMedium),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (schoolEmail != null || schoolPhone != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: _divider),
              const SizedBox(height: 16),
              if (schoolEmail != null && schoolEmail.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: schoolPhone != null && schoolPhone.isNotEmpty ? 12 : 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(8)),
                        child: const Center(child: AppIcon('sms', size: 18, color: _textMedium)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Email', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: _textLight)),
                            const SizedBox(height: 2),
                            Text(schoolEmail, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (schoolPhone != null && schoolPhone.isNotEmpty)
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: AppIcon('call', size: 18, color: _textMedium)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: _textLight)),
                          const SizedBox(height: 2),
                          Text(schoolPhone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textDark)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showProfileImagePopup(BuildContext context, String name, String? photoUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const AppIcon('close-circle', color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: photoUrl == null ? AppColors.secondary : null,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      width: 200,
                      height: 200,
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.secondary,
                        child: Center(
                          child: Text(
                            _getInitials(name),
                            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(name),
                        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
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
}

class _GridStat {
  final String value;
  final String label;
  const _GridStat({required this.value, required this.label});
}

class _ContactRow {
  final IconData? icon;
  final String? svgPath;
  final String label;
  final String value;
  const _ContactRow({this.icon, this.svgPath, required this.label, required this.value});
}
