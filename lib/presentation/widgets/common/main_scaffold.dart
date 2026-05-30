import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/student_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import 'app_icon.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(Routes.home)) return 0;
    if (location.startsWith(Routes.paymentHistory)) return 1;
    if (location.startsWith(Routes.notifications)) return 2;
    if (location.startsWith(Routes.profile)) return 3;
    // Drill-down routes map to their parent tab
    if (location.startsWith('/transaction')) return 1;
    return 0;
  }

  bool _isDrillDownRoute(String location) {
    return location.startsWith('/support') ||
        location.startsWith('/cart') ||
        location.startsWith('/all-pending-fees') ||
        location.startsWith('/pay-all-fees') ||
        location.startsWith('/paid-fees') ||
        location.startsWith('/switch-student') ||
        location.startsWith('/transaction/') ||
        (location.startsWith('/fees/') && location != '/fees') ||
        (location.startsWith('/payment-history/') &&
            location != '/payment-history') ||
        (location.startsWith('/notifications/') &&
            location != '/notifications');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    // Activate Supabase Realtime listener for push notifications
    ref.watch(notificationRealtimeProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (context.isDesktop) {
      return _buildDesktopLayout(context, ref, selectedIndex, isDark);
    }
    return _buildMobileLayout(context, selectedIndex, isDark);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Desktop: ONE unified rounded container wrapping sidebar | header+content
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDesktopLayout(
      BuildContext context, WidgetRef ref, int selectedIndex, bool isDark) {
    const double sidebarWidth = 260;
    return Scaffold(
      backgroundColor: AppColors.cardBg(context),
      body: Column(
        children: [
          // Full-width header spanning the entire top
          _buildDesktopTopBar(context, ref, isDark, selectedIndex),
          Divider(
              height: 1, thickness: 1, color: AppColors.borderC(context)),
          // Below header: sidebar on the left, content on the right
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: sidebarWidth,
                  child: _buildDesktopSidebar(
                      context, ref, selectedIndex, isDark),
                ),
                VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.borderC(context)),
                Expanded(
                  child: Container(
                    color: AppColors.scaffoldBg(context),
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Desktop top header bar (page title + search + actions)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDesktopTopBar(
      BuildContext context, WidgetRef ref, bool isDark, int selectedIndex) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final unreadCount = ref.watch(notificationCountProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final institutionAsync = ref.watch(selectedStudentInstitutionProvider);
    final institution = institutionAsync.valueOrNull;
    final schoolName = institution?.name ?? 'School Fees';
    final logoUrl = institution?.logoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Brand: school logo + institution name (moved to the left)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.borderC(context).withValues(alpha: 0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasLogo
                ? CachedNetworkImage(
                    imageUrl: logoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorWidget: (context, url, error) => Container(
                        color: AppColors.primary,
                        child: const Center(child: AppIcon('book',
                            color: Colors.white, size: 26))),
                  )
                : Container(
                    color: AppColors.primary,
                    child: const Center(child: AppIcon('book',
                        color: Colors.white, size: 26))),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              schoolName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryC(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          // Compact search bar positioned next to the cart icon
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: _TopBarSearchField(),
          ),
          const SizedBox(width: 12),
          // Cart icon with badge — outlined circle per reference
          _buildTopBarIconButton(
            context: context,
            svgPath: 'assets/icons/Cart.svg',
            badge: cartCount,
            onTap: () => context.push(Routes.cart),
          ),
          const SizedBox(width: 10),
          // Notification bell with unread badge — outlined circle per reference
          _buildTopBarIconButton(
            context: context,
            svgPath: 'assets/main icons/line icons/notification.svg',
            badge: unreadCount,
            onTap: () => context.go(Routes.notifications),
          ),
          const SizedBox(width: 14),
          // User avatar + student name + dropdown menu
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: AppColors.cardBg(context),
            onSelected: (value) {
              if (value == 'switch') {
                context.go(Routes.switchStudent);
              } else if (value == 'logout') {
                _showLogoutDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'switch',
                child: Row(
                  children: [
                    AppIcon('arrow-swap-horizontal', size: 20, color: AppColors.textSecondaryC(context)),
                    const SizedBox(width: 10),
                    Text(
                      'Switch Account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryC(context),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const AppIcon('logout', size: 20, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (selectedStudent?.photoUrl != null && selectedStudent!.photoUrl!.trim().isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: selectedStudent.photoUrl!,
                          fit: BoxFit.cover,
                          width: 36,
                          height: 36,
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              _getInitials(selectedStudent.name),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _getInitials(selectedStudent?.name ?? 'U'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedStudent?.name ?? '—',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryC(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Student',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHintC(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                AppIcon(
                  'arrow-down',
                  size: 20,
                  color: AppColors.textHintC(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarIconButton({
    required BuildContext context,
    required String svgPath,
    required int badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFD2913C),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              svgPath,
              width: 20,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            if (badge > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Desktop sidebar — brand + search + grouped nav + logout
  // Rendered inside the unified outer container, so it has no own card styling.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDesktopSidebar(
      BuildContext context, WidgetRef ref, int selectedIndex, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // MAIN MENU group
          _buildSidebarSectionLabel(context, 'MAIN MENU'),
          const SizedBox(height: 8),
          _buildSidebarItem(
            context: context,
            index: 0,
            selectedIndex: selectedIndex,
            label: 'Dashboard',
            lineSvg: 'assets/main icons/line icons/home.svg',
            fillSvg: 'assets/main icons/fill icons/home.svg',
            onTap: () => context.go(Routes.home),
          ),
          _buildSidebarItem(
            context: context,
            index: 1,
            selectedIndex: selectedIndex,
            label: 'History',
            lineSvg: 'assets/main icons/line icons/receipt-item.svg',
            fillSvg: 'assets/main icons/fill icons/receipt-item.svg',
            onTap: () => context.go(Routes.paymentHistory),
          ),
          _buildSidebarItem(
            context: context,
            index: 2,
            selectedIndex: selectedIndex,
            label: 'Alerts',
            lineSvg: 'assets/main icons/line icons/notification.svg',
            fillSvg: 'assets/main icons/fill icons/notification.svg',
            onTap: () => context.go(Routes.notifications),
            badge: ref.watch(notificationCountProvider),
          ),
          const SizedBox(height: 20),
          // GENERAL group
          _buildSidebarSectionLabel(context, 'GENERAL'),
          const SizedBox(height: 8),
          _buildSidebarItem(
            context: context,
            index: 3,
            selectedIndex: selectedIndex,
            label: 'Profile',
            lineSvg: 'assets/main icons/line icons/profile-circle.svg',
            fillSvg: 'assets/main icons/fill icons/profile-circle.svg',
            onTap: () => context.go(Routes.profile),
          ),
          _buildSidebarItem(
            context: context,
            index: -1,
            selectedIndex: selectedIndex,
            label: 'Logout',
            fallbackIcon: 'logout',
            onTap: () => _showLogoutDialog(context, ref),
          ),
          // Fill remaining space — no watermark, cleaner per reference
          const Expanded(child: SizedBox.shrink()),
        ],
      );
  }

  Widget _buildSidebarSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 20, 0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFFD2913C),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required int index,
    required int selectedIndex,
    required String label,
    required VoidCallback onTap,
    String? lineSvg,
    String? fillSvg,
    String? fallbackIcon,
    int badge = 0,
  }) {
    assert(
      (lineSvg != null && fillSvg != null) || fallbackIcon != null,
      'Provide either lineSvg + fillSvg or a fallbackIcon (AppIcon name).',
    );
    final isSelected = index == selectedIndex;
    final Color fg =
        isSelected ? Colors.white : AppColors.textSecondaryC(context);
    final Widget iconWidget = (lineSvg != null && fillSvg != null)
        ? SvgPicture.asset(
            isSelected ? fillSvg : lineSvg,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
          )
        : AppIcon(fallbackIcon!, size: 20, color: fg);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
            if (badge > 0) ...[
              const Spacer(),
              Container(
                constraints: const BoxConstraints(minWidth: 22, maxWidth: 32),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.error,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondaryC(context))),
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Mobile: existing bottom nav bar layout
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMobileLayout(
      BuildContext context, int selectedIndex, bool isDark) {
    final location = GoRouterState.of(context).matchedLocation;
    if (_isDrillDownRoute(location)) {
      return child; // Drill-down screen handles its own Scaffold
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: AppColors.cardBg(context),
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        body: child,
        extendBody: false,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    selectedIndex: selectedIndex,
                    label: 'Home',
                    lineSvg: 'assets/main icons/line icons/home.svg',
                    fillSvg: 'assets/main icons/fill icons/home.svg',
                    onTap: () => context.go(Routes.home),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    selectedIndex: selectedIndex,
                    label: 'History',
                    lineSvg: 'assets/main icons/line icons/receipt-item.svg',
                    fillSvg: 'assets/main icons/fill icons/receipt-item.svg',
                    onTap: () => context.go(Routes.paymentHistory),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    selectedIndex: selectedIndex,
                    label: 'Alerts',
                    lineSvg: 'assets/main icons/line icons/notification.svg',
                    fillSvg: 'assets/main icons/fill icons/notification.svg',
                    onTap: () => context.go(Routes.notifications),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    selectedIndex: selectedIndex,
                    label: 'Profile',
                    lineSvg: 'assets/main icons/line icons/profile-circle.svg',
                    fillSvg: 'assets/main icons/fill icons/profile-circle.svg',
                    onTap: () => context.go(Routes.profile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required int selectedIndex,
    required String label,
    required String lineSvg,
    required String fillSvg,
    required VoidCallback onTap,
  }) {
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              isSelected ? fillSvg : lineSvg,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? AppColors.primary : AppColors.textHintC(context),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected ? AppColors.primary : AppColors.textHintC(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful search field for the desktop top bar.
class _TopBarSearchField extends StatefulWidget {
  @override
  State<_TopBarSearchField> createState() => _TopBarSearchFieldState();
}

class _TopBarSearchFieldState extends State<_TopBarSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFilterSelected(String value) {
    final String? query = _controller.text.trim().isEmpty
        ? null
        : Uri.encodeComponent(_controller.text.trim());
    switch (value) {
      case 'all':
        context.go(Routes.fees);
        break;
      case 'pending':
        context.go(query != null
            ? '${Routes.allPendingFees}?group=$query'
            : Routes.allPendingFees);
        break;
      case 'paid':
        context.go(Routes.paidFees);
        break;
      case 'pay_all':
        context.go(Routes.payAllFees);
        break;
    }
    _controller.clear();
    _focusNode.unfocus();
  }

  PopupMenuItem<String> _filterMenuItem(
      BuildContext context, String value, String label, String icon) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          AppIcon(icon, size: 18, color: AppColors.textSecondaryC(context)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimaryC(context),
            ),
          ),
        ],
      ),
    );
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;
    if (q.contains('pay') ||
        q.contains('history') ||
        q.contains('receipt') ||
        q.contains('transaction')) {
      context.go(Routes.paymentHistory);
    } else if (q.contains('notif') || q.contains('alert')) {
      context.go(Routes.notifications);
    } else if (q.contains('profile') ||
        q.contains('account') ||
        q.contains('student')) {
      context.go(Routes.profile);
    } else if (q.contains('support') ||
        q.contains('help') ||
        q.contains('contact')) {
      context.go(Routes.support);
    } else if (q.contains('cart') || q.contains('queue')) {
      context.go(Routes.cart);
    } else if (q.contains('paid')) {
      context.go(Routes.paidFees);
    } else {
      context.go(
          '${Routes.allPendingFees}?group=${Uri.encodeComponent(query.trim())}');
    }
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _hasFocus
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.borderC(context).withValues(alpha: 0.5),
          width: _hasFocus ? 1.4 : 1,
        ),
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          AppIcon(
            'search-normal-1',
            size: 20,
            color: _hasFocus
                ? AppColors.primary
                : AppColors.textHintC(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: AppColors.primary,
              cursorHeight: 16,
              decoration: InputDecoration(
                hintText: 'Search anything...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textHintC(context),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryC(context),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: _onSearch,
            ),
          ),
          // Trailing: clear button when typing
          if (hasText) ...[
            _ClearButton(
              onTap: () {
                _controller.clear();
                setState(() {});
              },
            ),
            const SizedBox(width: 6),
          ],
          // Solid primary action button — opens quick-filter menu
          Padding(
            padding: const EdgeInsets.all(4),
            child: PopupMenuButton<String>(
              tooltip: 'Filter',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              color: AppColors.cardBg(context),
              elevation: 8,
              onSelected: _onFilterSelected,
              itemBuilder: (context) => [
                _filterMenuItem(context, 'all', 'All Fees', 'receipt-text'),
                _filterMenuItem(context, 'pending', 'Pending Fees', 'clock'),
                _filterMenuItem(context, 'paid', 'Paid Fees', 'tick-circle'),
                _filterMenuItem(context, 'pay_all', 'Pay All Fees', 'wallet-3'),
              ],
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  'setting-4',
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.borderC(context).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: AppIcon(
            'close-circle',
            size: 14,
            color: AppColors.textSecondaryC(context),
          ),
        ),
      ),
    );
  }
}

