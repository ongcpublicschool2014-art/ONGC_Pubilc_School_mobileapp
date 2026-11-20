import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_ui.dart';
import '../../../data/models/student_model.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/institution_provider.dart';
import '../../widgets/common/app_action_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/app_icon_circle_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Profile palette — uses app primary colors
  static const Color _cardBg = Color(0xFFFFFDF8);
  static const Color _cardBorder = Colors.transparent;
  static const Color _textDark = Color(0xFF17232B);
  static const Color _textMedium = Color(0xFF4A5A63);
  static const Color _textLight = Color(0xFF4A5A63);
  static const Color _divider = Color(0xFFE1F0EC);
  static const Color _iconBg = Color(0xFFF5F1E8);

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
              backgroundColor: _textDark,
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
            'batch': StudentModel.hasValue(selectedStudent.stubatch) ? selectedStudent.stubatch! : 'N/A',
            'gender': selectedStudent.gender,
            'dob': _formatDate(selectedStudent.dateOfBirth),
            'blood': StudentModel.hasValue(selectedStudent.stubloodgrp) ? selectedStudent.stubloodgrp! : 'N/A',
            'course': selectedStudent.courseName,
            'mobile': StudentModel.hasValue(currentParent?.payinchargemob) ? currentParent!.payinchargemob! : 'N/A',
            'email': StudentModel.hasValue(currentParent?.paremail) ? currentParent!.paremail! : 'N/A',
            'address': selectedStudent.fullAddress.isNotEmpty ? selectedStudent.fullAddress : 'N/A',
            'parentName': StudentModel.hasValue(currentParent?.payincharge) ? currentParent!.payincharge! : 'N/A',
          }
        : {
            'name': 'Student',
            'class': 'N/A',
            'adminNo': 'N/A',
            'batch': 'N/A',
            'gender': 'N/A',
            'dob': 'N/A',
            'blood': 'N/A',
            'course': 'N/A',
            'mobile': 'N/A',
            'email': 'N/A',
            'address': 'N/A',
            'parentName': 'N/A',
          };

    if (context.isDesktop) {
      return _buildDesktopProfile(context, studentData, hasMultipleStudents);
    }

    return Scaffold(
      backgroundColor: AppUi.pageBg,
      body: Column(
        children: [
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
                    _buildMobileTitleBar(context),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 22),
                    // Who this is: the page opens on the student, not on a
                    // greeting and a school logo.
                    _buildIdentityBlock(context, studentData),
                    const SizedBox(height: 20),
                    _buildSchoolInfoCard(context),
                    const SizedBox(height: 22),
                    _sectionLabel('Student details'),
                    const SizedBox(height: 10),
                    _buildStudentSummaryCard(studentData),
                    const SizedBox(height: 22),
                    _sectionLabel('Contact'),
                    const SizedBox(height: 10),
                    _buildContactCard(studentData),
                    const SizedBox(height: 22),
                    _buildQuickActionsCard(context, hasMultipleStudents),
                    const SizedBox(height: 6),
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

  Future<void> _launchPhone(String number) async {
    final digits = number.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppUi.inkMuted),
        ),
      );

  Widget _buildMobileTitleBar(BuildContext context) {
    final cartItemCount = ref.watch(cartItemCountProvider);
    final notificationCount = ref.watch(notificationCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Profile',
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

  /// Avatar, name, roll number and the chips that place the student.
  Widget _buildIdentityBlock(
      BuildContext context, Map<String, String> studentData) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final hasPhoto = selectedStudent != null &&
        selectedStudent.photoUrl != null &&
        selectedStudent.photoUrl!.isNotEmpty;
    final name = studentData['name']!;

    Widget chip(String text, {bool accent = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accent ? const Color(0xFFE1F0EC) : AppUi.fill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: accent ? AppUi.navy : AppUi.inkMuted,
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: GestureDetector(
            onTap: () => _showProfileImagePopup(
              context,
              name,
              hasPhoto ? selectedStudent.photoUrl! : null,
            ),
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppUi.navy,
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: selectedStudent.photoUrl!,
                      fit: BoxFit.cover,
                      width: 92,
                      height: 92,
                      errorWidget: (context, url, error) =>
                          _avatarInitials(name),
                    )
                  : _avatarInitials(name),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppUi.ink,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Admission No. ${studentData['adminNo']}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: AppUi.inkMuted),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (studentData['course'] != 'N/A')
              chip(studentData['course']!, accent: true),
            if (studentData['class'] != 'N/A')
              chip(studentData['class']!, accent: true),
            if (studentData['batch'] != 'N/A') chip('Batch ${studentData['batch']}'),
          ],
        ),
      ],
    );
  }

  Widget _avatarInitials(String name) => Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
              fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      );

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
              color: AppColors.avatarBg,
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

  /// Student details — one row per field.
  ///
  /// The 2x3 grid of tiles gave a roll number and a blood group the same
  /// visual weight as everything else and wrapped long course names; a label
  /// on the left and the value on the right reads the way a record should.
  Widget _buildStudentSummaryCard(Map<String, String> studentData) {
    final items = <_GridStat>[
      _GridStat(value: studentData['course']!, label: 'Standard'),
      _GridStat(value: studentData['class']!, label: 'Section'),
      _GridStat(value: studentData['dob']!, label: 'Date of birth'),
      _GridStat(value: studentData['gender']!, label: 'Gender'),
      if (studentData['blood'] != 'N/A')
        _GridStat(value: studentData['blood']!, label: 'Blood group'),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppUi.cardBox(),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: AppUi.lineSoft),
              ),
            _buildStatCell(items[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCell(_GridStat stat) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label,
            style: const TextStyle(fontSize: 14.5, color: AppUi.inkMuted),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              stat.value == 'N/A' ? '—' : stat.value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppUi.ink,
              ),
            ),
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
    final logoUrl = institution?.logoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppUi.fill,
        borderRadius: BorderRadius.circular(AppUi.radius),
      ),
      child: Row(
        children: [
          // School logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppUi.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppUi.line),
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
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppUi.ink,
                      height: 1.35),
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
      clipBehavior: Clip.antiAlias,
      decoration: AppUi.cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The card heading moved out to a section label above it, so the
          // card is nothing but the rows.
          ...contacts.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;
            final isLast = index == contacts.length - 1;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppUi.fill,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: contact.svgPath != null
                              ? SvgPicture.asset(contact.svgPath!,
                                  width: 17,
                                  height: 17,
                                  colorFilter: const ColorFilter.mode(
                                      AppUi.inkMuted, BlendMode.srcIn))
                              : Icon(contact.icon,
                                  size: 17, color: AppUi.inkMuted),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.label,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppUi.inkMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              contact.value == 'N/A'
                                  ? 'Not added yet'
                                  : contact.value,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: contact.value == 'N/A'
                                    ? AppUi.inkFaint
                                    : AppUi.ink,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // A phone number on a screen is only useful if it dials.
                      if (contact.label == 'Mobile' && contact.value != 'N/A')
                        GestureDetector(
                          onTap: () => _launchPhone(contact.value),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppUi.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppUi.line),
                            ),
                            child: const Center(
                              child:
                                  AppIcon('call', size: 17, color: AppUi.navy),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: AppUi.lineSoft),
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
    // No card around them: these are two buttons, and a bordered panel holding
    // two bordered buttons is a box inside a box.
    return Column(
      children: [
        if (hasMultipleStudents) ...[
          _buildMinimalButton(
            iconName: 'arrow-swap-horizontal',
            label: 'Switch student',
            filled: true,
            onTap: () => context.push(Routes.switchStudent),
          ),
          const SizedBox(height: 10),
        ],
        _buildMinimalButton(
          iconName: '24-support',
          label: 'Get support',
          filled: false,
          onTap: () => context.push(Routes.support),
        ),
      ],
    );
  }

  Widget _buildMinimalButton({
    required String iconName,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    // Spec: filled = amber bg + white icon/label
    //       outlined = white bg + amber 1.5px stroke + amber icon/label
    return AppActionButton(
      onPressed: onTap,
      label: label,
      variant: filled
          ? AppActionButtonVariant.filled
          : AppActionButtonVariant.outlined,
      borderRadius: 12,
      verticalPadding: 15,
      horizontalPadding: 12,
      leading: AppIcon(
        iconName,
        size: 18,
        color: filled ? Colors.white : AppUi.navy,
      ),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildSignOutButton() {
    // Plain text, not a bordered button: signing out is not something the
    // screen should be inviting anyone to do.
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showLogoutDialog(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Text(
            'Sign out',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppUi.failInk),
          ),
        ),
      ),
    );
  }

  // ─── Desktop layout ─────────────────────────────────────────

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
    return AppActionButton(
      onPressed: onTap,
      label: label,
      leading: AppIcon(iconName, size: 20, color: Colors.white),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
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
                color: photoUrl == null ? AppColors.avatarBg : null,
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
                        color: AppColors.avatarBg,
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
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
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
