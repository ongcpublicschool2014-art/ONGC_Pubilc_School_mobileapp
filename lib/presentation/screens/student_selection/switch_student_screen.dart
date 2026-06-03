import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../config/routes.dart';
import '../../../data/models/student_model.dart';
import '../../providers/student_provider.dart';
import '../../providers/institution_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';

class SwitchStudentScreen extends ConsumerStatefulWidget {
  const SwitchStudentScreen({super.key});

  @override
  ConsumerState<SwitchStudentScreen> createState() => _SwitchStudentScreenState();
}

class _SwitchStudentScreenState extends ConsumerState<SwitchStudentScreen> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Pre-select current student by matching stuId + insId
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentStudent = ref.read(selectedStudentProvider);
      final students = ref.read(studentsByParentProvider).valueOrNull;
      if (currentStudent != null && students != null) {
        for (int i = 0; i < students.length; i++) {
          if (students[i].stuId == currentStudent.stuId &&
              students[i].insId == currentStudent.insId) {
            setState(() => _selectedIndex = i);
            break;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsByParentProvider);
    final currentStudent = ref.watch(selectedStudentProvider);

    return DesktopDetailScaffold(
      isNested: true,
      header: _buildHeader(context),
      toolbar: const BreadcrumbBar(
        parentLabel: 'Profile',
        parentRoute: Routes.profile,
        currentLabel: 'Switch Student',
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (students) => _buildStudentList(students, currentStudent),
      ),
      bottomBar: _buildSwitchButton(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          if (!context.isDesktop)
            GestureDetector(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(Routes.profile);
                }
              },
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 14),
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
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/arrow-left.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch Student',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a different student profile',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<StudentModel> students, StudentModel? currentStudent) {
    final padding = context.isDesktop
        ? const EdgeInsets.all(24)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    return ListView.separated(
      padding: padding,
      // +3 leading slots on desktop: banner + title + spacer
      itemCount: students.length + (context.isDesktop ? 3 : 0),
      separatorBuilder: (_, idx) {
        if (context.isDesktop && idx < 2) return const SizedBox(height: 18);
        if (context.isDesktop && idx == 2) return const SizedBox(height: 4);
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        if (context.isDesktop && index == 0) {
          return _buildDesktopGreetingBanner(context, students.length);
        }
        if (context.isDesktop && index == 1) {
          return _buildDesktopTitle(context, currentStudent);
        }
        if (context.isDesktop && index == 2) {
          return const SizedBox.shrink();
        }
        final realIndex = index - (context.isDesktop ? 3 : 0);
        final student = students[realIndex];
        final isSelected = _selectedIndex == realIndex;
        final isCurrent = currentStudent != null &&
            currentStudent.stuId == student.stuId &&
            currentStudent.insId == student.insId;

        return _buildStudentCard(student, isSelected, isCurrent, realIndex);
      },
    );
  }

  Widget _buildDesktopGreetingBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD2913C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Pick a student to switch — $count linked to this account.',
              style: const TextStyle(
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

  Widget _buildDesktopTitle(
      BuildContext context, StudentModel? currentStudent) {
    final firstName =
        currentStudent?.name.trim().split(' ').first ?? 'Student';
    final admissionNo = currentStudent?.admissionNumber ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Switch Student",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryC(context),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Currently $firstName · ID $admissionNo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textHintC(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(StudentModel student, bool isSelected, bool isCurrent, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderC(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppColors.cardShadow(context),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE5A85C), Color(0xFFD2913C)],
                ),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: (student.photoUrl != null && student.photoUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: student.photoUrl!,
                      fit: BoxFit.cover,
                      width: 52,
                      height: 52,
                      placeholder: (context, url) => Center(
                        child: Text(
                          _getInitials(student.name),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          _getInitials(student.name),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(student.name),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryC(context),
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cardGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cardGreenDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Admission No: ${student.admissionNumber} | Class: ${student.className}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondaryC(context),
                    ),
                  ),
                  Consumer(builder: (context, ref, _) {
                    final instAsync = ref.watch(institutionByIdProvider(student.insId));
                    final instName = instAsync.valueOrNull?.insname ?? student.inscode;
                    if (instName.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        instName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderC(context),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const AppIcon(
                      'tick-circle',
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchButton() {
    final currentStudent = ref.watch(selectedStudentProvider);
    final students = ref.watch(studentsByParentProvider).valueOrNull;
    final currentIndex = (students != null && currentStudent != null)
        ? students.indexWhere((s) => s.stuId == currentStudent.stuId && s.insId == currentStudent.insId)
        : -1;
    final isNewSelection = _selectedIndex != null && _selectedIndex != currentIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GestureDetector(
        onTap: isNewSelection ? _handleSwitch : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isNewSelection ? const Color(0xFFD2913C) : AppColors.borderC(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isNewSelection
                ? [
                    BoxShadow(
                      color: const Color(0x30000000),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isNewSelection ? 'Switch Student' : 'Select a Different Student',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isNewSelection ? Colors.white : AppColors.textHintC(context),
                ),
              ),
              if (isNewSelection) ...[
                const SizedBox(width: 10),
                const AppIcon(
                  'arrow-swap-horizontal',
                  size: 22,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSwitch() async {
    if (_selectedIndex == null) return;

    final studentsAsync = ref.read(studentsByParentProvider);
    final students = studentsAsync.valueOrNull;
    if (students == null || _selectedIndex! >= students.length) return;

    final selectedStudent = students[_selectedIndex!];

    await ref.read(selectedStudentProvider.notifier).selectStudent(selectedStudent);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${selectedStudent.name}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      context.go(Routes.home);
    }
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
