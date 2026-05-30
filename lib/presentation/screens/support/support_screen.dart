import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/cart_provider.dart';
import '../../providers/institution_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  static const Color _bg = Color(0xFFF1F5F9);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFE8E7E4);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMedium = Color(0xFF6B6B6B);
  static const Color _textLight = Color(0xFF6B6B6B);

  bool get _isMobile => !context.isDesktop;

  int _openFaqIndex = 0;

  final List<Map<String, String>> _faqs = [
    {
      'question': "How do I pay my child's fees online?",
      'answer':
          "Go to the \"Fee Details\" page, review the pending dues, and click on the 'Pay Now' button. Choose your preferred payment method and complete the transaction.",
    },
    {
      'question': 'What payment methods are accepted?',
      'answer':
          'We accept various payment methods including credit/debit cards, net banking, UPI, and digital wallets.',
    },
    {
      'question': 'Will I receive a receipt after payment?',
      'answer':
          'Yes, you can download and share the payment receipt from the payment history section after successful payment.',
    },
    {
      'question': 'What happens if I miss a payment due date?',
      'answer':
          'Late fees may apply if payment is not received by the due date. Please contact the school administration for assistance.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final institutionAsync = ref.watch(selectedStudentInstitutionProvider);
    return DesktopDetailScaffold(
      isNested: true,
      header: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeader(context),
          const SizedBox(height: 16),
        ],
      ),
      toolbar: const BreadcrumbBar(currentLabel: 'Help & Support'),
      body: Container(
        color: _isMobile ? _bg : null,
        child: SingleChildScrollView(
        child: Padding(
          padding: context.isDesktop ? const EdgeInsets.all(24) : const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard-style header (desktop only)
              if (context.isDesktop) ...[
                _buildDesktopGreetingBanner(context),
                const SizedBox(height: 18),
                _buildDesktopTitle(context),
                const SizedBox(height: 20),
              ] else
                const SizedBox(height: 24),
              // Contact School Card
              _buildContactCard(institutionAsync),
              const SizedBox(height: 24),
              // FAQ's Title
              Text(
                "FAQ's",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _isMobile ? _textDark : AppColors.textPrimaryC(context),
                ),
              ),
              const SizedBox(height: 12),
              // FAQ Items
              ..._faqs.asMap().entries.map((entry) {
                final index = entry.key;
                final faq = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildFaqItem(
                    question: faq['question']!,
                    answer: faq['answer']!,
                    isOpen: _openFaqIndex == index,
                    onToggle: () {
                      setState(() {
                        _openFaqIndex = _openFaqIndex == index ? -1 : index;
                      });
                    },
                  ),
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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
              'Need help? Reach out to your school or browse the FAQs below.',
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

  Widget _buildDesktopTitle(BuildContext context) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final firstName =
        selectedStudent?.name.trim().split(' ').first ?? 'Student';
    final admissionNo = selectedStudent?.admissionNumber ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$firstName's Help & Support",
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

  Widget _buildHeader(BuildContext context) {
    final cartItemCount = ref.watch(cartItemCountProvider);
    final notificationCount = ref.watch(notificationCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Back Button - Dark theme
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.iconButtonBorder(context)),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Center(
                child: SvgPicture.asset('assets/icons/arrow-left.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _isMobile ? _textDark : AppColors.textPrimaryC(context),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get assistance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isMobile ? _textMedium : AppColors.textSecondaryC(context),
                  ),
                ),
              ],
            ),
          ),
          // Student chip (desktop only)
          if (context.isDesktop) ...[
            _buildStudentChip(context),
            const SizedBox(width: 12),
          ],
          // Cart Icon - Dark theme
          GestureDetector(
            onTap: () => context.push(Routes.cart),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.iconButtonBorder(context)),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset('assets/icons/Cart.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                  if (cartItemCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.iconButtonBg(context), width: 2),
                        ),
                        child: Text(
                          cartItemCount > 9 ? '9+' : '$cartItemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Notification Icon - Dark theme with badge
          GestureDetector(
            onTap: () => context.go(Routes.notifications),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.iconButtonBorder(context)),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset('assets/main icons/line icons/notification.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                  if (notificationCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.iconButtonBg(context), width: 2),
                        ),
                        child: Text(
                          notificationCount > 9 ? '9+' : '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentChip(BuildContext context) {
    final student = ref.watch(selectedStudentProvider);
    if (student == null) return const SizedBox.shrink();
    final parts = student.name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.take(2).map((p) => p[0]).join().toUpperCase();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          backgroundImage: (student.photoUrl != null && student.photoUrl!.isNotEmpty)
              ? NetworkImage(student.photoUrl!) : null,
          child: (student.photoUrl == null || student.photoUrl!.isEmpty)
              ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))
              : null,
        ),
        const SizedBox(width: 8),
        Text(student.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryC(context))),
      ],
    );
  }

  Widget _buildContactCard(AsyncValue<dynamic> institutionAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isMobile ? _cardBg : AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isMobile
            ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 8))]
            : AppColors.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.cardBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppIcon(
                    '24-support',
                    size: 26,
                    color: AppColors.cardBlueDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Contact School',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _isMobile ? _textDark : AppColors.textPrimaryC(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Divider
          Container(
            height: 1,
            color: _isMobile ? const Color(0xFFF0F0F0) : AppColors.borderC(context),
          ),
          const SizedBox(height: 20),
          // Email Row
          _buildContactRow(
            icon: 'sms',
            iconBg: AppColors.cardPurple,
            iconColor: AppColors.cardPurpleDark,
            label: 'Email',
            value: institutionAsync.when(
              data: (inst) => inst?.email ?? 'N/A',
              loading: () => 'Loading...',
              error: (_, __) => 'N/A',
            ),
          ),
          const SizedBox(height: 16),
          // Phone Row
          _buildContactRow(
            icon: 'call',
            iconBg: AppColors.cardGreen,
            iconColor: AppColors.cardGreenDark,
            label: 'Phone',
            value: institutionAsync.when(
              data: (inst) => inst?.phone ?? 'N/A',
              loading: () => 'Loading...',
              error: (_, __) => 'N/A',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required String icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: AppIcon(icon, size: 20, color: iconColor)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHintC(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryC(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required bool isOpen,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _isMobile ? _cardBg : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: _isMobile
              ? (isOpen ? Border.all(color: AppColors.primary, width: 2) : null)
              : (isOpen ? Border.all(color: AppColors.primary, width: 2) : null),
          boxShadow: _isMobile
              ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 8))]
              : [
            BoxShadow(
              color: isOpen ? AppColors.shadowPurple : AppColors.shadowLight,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Question Row
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isOpen ? AppColors.cardPurple : AppColors.cardCyan,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: AppIcon(
                        'message-question',
                        size: 20,
                        color: isOpen
                            ? AppColors.cardPurpleDark
                            : AppColors.cardCyanDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isOpen ? FontWeight.w600 : FontWeight.w500,
                        color: _isMobile ? _textDark : AppColors.textPrimaryC(context),
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isOpen ? AppColors.primary : AppColors.filterBg(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: AppIcon(
                        isOpen ? 'arrow-up' : 'arrow-down',
                        size: 20,
                        color: isOpen ? Colors.white : AppColors.textHintC(context),
                      ),
                    ),
                  ),
                ],
              ),
              // Answer (shown when open)
              if (isOpen) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardPurple.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    answer,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryC(context),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
