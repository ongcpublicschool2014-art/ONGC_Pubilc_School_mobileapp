import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../config/routes.dart';
import '../../../data/models/student_model.dart';
import '../../providers/student_provider.dart';
import '../../providers/institution_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/auth_desktop_wrapper.dart';
import '../../widgets/common/screen_illustrations.dart';

class StudentSelectionScreen extends ConsumerStatefulWidget {
  const StudentSelectionScreen({super.key});

  @override
  ConsumerState<StudentSelectionScreen> createState() => _StudentSelectionScreenState();
}

class _StudentSelectionScreenState extends ConsumerState<StudentSelectionScreen> {
  int? _selectedStudentIndex;
  bool _hasAutoSelected = false;
  bool _isCheckingStudents = true; // Show loading while checking

  @override
  void initState() {
    super.initState();
    // Check for single student after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSingleStudent();
    });
  }

  Future<void> _checkForSingleStudent() async {
    if (_hasAutoSelected) return;

    final studentsAsync = ref.read(studentsByParentProvider);
    studentsAsync.when(
      loading: () {
        // Still loading, keep showing loader
      },
      error: (_, __) {
        // Error occurred, show the screen
        if (mounted) {
          setState(() => _isCheckingStudents = false);
        }
      },
      data: (students) async {
        if (students.length == 1 && mounted) {
          _hasAutoSelected = true;
          // Auto-select the only student and navigate to home
          final student = students.first;
          await ref.read(selectedStudentProvider.notifier).selectStudent(student);
          if (mounted) {
            context.go(Routes.home);
          }
        } else if (mounted) {
          // Multiple students or no students - show selection screen
          setState(() => _isCheckingStudents = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for students loading and auto-select if single student
    ref.listen<AsyncValue<List<StudentModel>>>(studentsByParentProvider, (previous, next) {
      next.when(
        loading: () {},
        error: (_, __) {
          if (mounted && _isCheckingStudents) {
            setState(() => _isCheckingStudents = false);
          }
        },
        data: (students) async {
          if (students.length == 1 && !_hasAutoSelected && mounted) {
            _hasAutoSelected = true;
            final student = students.first;
            await ref.read(selectedStudentProvider.notifier).selectStudent(student);
            if (mounted) {
              context.go(Routes.home);
            }
          } else if (mounted && _isCheckingStudents) {
            // Multiple students - show selection screen
            setState(() => _isCheckingStudents = false);
          }
        },
      );
    });

    // Show loading screen while checking for single student
    if (_isCheckingStudents) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textHintC(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: AuthDesktopWrapper(
        headline: 'Select Student',
        subtitle: 'Choose a student to continue',
        centerContent: ScreenIllustrations.studentSelection(size: 360, isDark: true),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildStudentList(),
                  const SizedBox(height: 32),
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Select Student',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryC(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a student to continue',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryC(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList() {
    final studentsAsync = ref.watch(studentsByParentProvider);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading students: $error'),
      ),
      data: (students) {
        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.cardPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppIcon(
                      'profile-delete',
                      size: 40,
                      color: AppColors.cardPurpleDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No students found',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            for (int index = 0; index < students.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              _buildStudentCard(students[index], _selectedStudentIndex == index, index),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStudentCard(StudentModel student, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStudentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? []
              : [
                  BoxShadow(
                    color: isSelected ? AppColors.shadowPurple : AppColors.shadowLight,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Avatar - Circular like profile page
            Container(
              width: 48,
              height: 48,
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
                      width: 48,
                      height: 48,
                      placeholder: (context, url) => Center(
                        child: Text(
                          _getInitials(student.stuname),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          _getInitials(student.stuname),
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
                        _getInitials(student.stuname),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            // Student Info - Home page style
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.stuname,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Adm No: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondaryC(context),
                          ),
                        ),
                        TextSpan(
                          text: student.stuadmno,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryC(context),
                          ),
                        ),
                        TextSpan(
                          text: ' | Class: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondaryC(context),
                          ),
                        ),
                        TextSpan(
                          text: student.stuclass,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryC(context),
                          ),
                        ),
                      ],
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
            // Selection indicator
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderC(context),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const AppIcon('tick-circle', size: 18, color: Colors.white)
                  : null,
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

  Widget _buildContinueButton() {
    final isEnabled = _selectedStudentIndex != null;

    return GestureDetector(
        onTap: isEnabled
            ? () async {
                final studentsAsync = ref.read(studentsByParentProvider);
                final students = studentsAsync.valueOrNull;
                if (students != null && _selectedStudentIndex != null) {
                  final selectedStudent = students[_selectedStudentIndex!];
                  await ref.read(selectedStudentProvider.notifier).selectStudent(selectedStudent);
                }
                if (mounted) context.go(Routes.home);
              }
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isEnabled ? const Color(0xFFD2913C) : AppColors.borderC(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isEnabled
                ? const [
                    BoxShadow(
                      color: Color(0x30000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? Colors.white : AppColors.textHintC(context),
                ),
              ),
              const SizedBox(width: 8),
              AppIcon(
                'arrow-right-1',
                size: 20,
                color: isEnabled ? Colors.white : AppColors.textHintC(context),
              ),
            ],
          ),
        ),
    );
  }
}
