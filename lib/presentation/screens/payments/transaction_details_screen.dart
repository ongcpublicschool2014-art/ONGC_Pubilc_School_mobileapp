import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/receipt_pdf_generator.dart';
import '../../../data/models/fee_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../receipt_widget.dart';
import '../../../core/services/supabase_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../widgets/common/amber_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';
import '../../widgets/common/drill_down_icon_button.dart';

enum _ExportMode { download, print, share }

class TransactionDetailsScreen extends ConsumerWidget {
  final String paymentId;
  final bool isNested;

  const TransactionDetailsScreen({super.key, required this.paymentId, this.isNested = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(paymentByIdProvider(int.tryParse(paymentId) ?? 0));
    final selectedStudent = ref.watch(selectedStudentProvider);

    return DesktopDetailScaffold(
      isNested: isNested,
      header: Column(
        children: [
          const SizedBox(height: 8),
          _buildHeader(context, ref),
          const SizedBox(height: 12),
        ],
      ),
      toolbar: const BreadcrumbBar(
        parentLabel: 'Payment History',
        parentRoute: Routes.paymentHistory,
        currentLabel: 'Transaction Details',
      ),
      body: paymentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (payment) {
          if (payment == null) {
            return const Center(child: Text('Payment not found'));
          }

          final isPaid = payment.status == PaymentStatus.success;

          return SingleChildScrollView(
            padding: context.isDesktop ? const EdgeInsets.all(24) : const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard-style header (desktop only)
                if (context.isDesktop) ...[
                  _buildDesktopGreetingBanner(context, isPaid),
                  const SizedBox(height: 18),
                  _buildDesktopTitle(context, selectedStudent),
                  const SizedBox(height: 20),
                ],

                // Transaction Card
                _buildTransactionCard(
                  context,
                  payment,
                  selectedStudent?.name ?? '',
                  selectedStudent?.className ?? '',
                  selectedStudent?.admissionNumber ?? '',
                  payment.transtotalamount,
                  payment.yrlabel ?? 'Fee Payment',
                  isPaid,
                ),
                const SizedBox(height: 24),
                // Action Buttons
                _buildActionButtons(context, ref, payment, isPaid),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopGreetingBanner(BuildContext context, bool isPaid) {
    final message = isPaid
        ? 'Payment successful — your receipt is ready below.'
        : 'This payment did not go through. Tap retry to try again.';
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
              message,
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

  Widget _buildDesktopTitle(BuildContext context, dynamic selectedStudent) {
    final firstName =
        (selectedStudent?.name as String?)?.trim().split(' ').first ??
            'Student';
    final admissionNo =
        (selectedStudent?.admissionNumber as String?) ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$firstName's Transaction",
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

  ReceiptData? _buildReceiptData({
    required PaymentModel payment,
    required dynamic selectedStudent,
    required dynamic institution,
    required List<FeeModel> fees,
  }) {
    if (selectedStudent == null) return null;

    final dateFormat = DateFormat('dd MMM yyyy');
    final payDate = payment.paydate ?? payment.createdat;

    // Group fees by term. Mirrors the admin app: split fine into its own
    // ReceiptFeeItem so the receipt shows e.g. "TUITION FEES 1,400" + "Fine 100"
    // instead of a single bundled "TUITION FEES 1,500".
    final feesByTerm = <String, List<ReceiptFeeItem>>{};
    for (final fee in fees) {
      final termKey = fee.demfeeterm;
      final collected = fee.paidamount > 0 ? fee.paidamount : fee.feeamount;
      final fine = fee.fineamount;
      final feeOnly = (collected - fine).clamp(0, double.infinity).toDouble();
      feesByTerm.putIfAbsent(termKey, () => []).add(
        ReceiptFeeItem(type: fee.feeTypeName, amount: feeOnly),
      );
      if (fine > 0) {
        feesByTerm[termKey]!.add(ReceiptFeeItem(type: '  Fine', amount: fine));
      }
    }

    final termDetails = feesByTerm.entries
        .map((e) => ReceiptTermDetail(term: e.key, fees: e.value))
        .toList();

    return ReceiptData(
      receiptNo: payment.paymentNumber,
      date: dateFormat.format(payDate),
      studentName: selectedStudent.name ?? '',
      mobileNo: selectedStudent.stumobile ?? '',
      address: selectedStudent.fullAddress ?? '',
      admissionNo: selectedStudent.admissionNumber ?? '',
      className: selectedStudent.className ?? '',
      courseName: (selectedStudent.courseName as String?) ?? '-',
      schoolName: institution?.insname ?? '',
      schoolAddress: institution?.fullAddress ?? '',
      schoolLogoUrl: institution?.inslogo,
      schoolMobile: institution?.insmobno,
      schoolEmail: institution?.insmail,
      feeDetails: termDetails,
      paymentMethod: payment.paymentMethod,
      paymentDate: dateFormat.format(payDate),
      status: payment.paystatus == 'C' ? 'paid' : payment.paystatus == 'F' ? 'failed' : 'pending',
      reconStatus: payment.reconStatus,
      paymentReference: payment.payreference,
      total: payment.transtotalamount,
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final notificationCount = ref.watch(notificationCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          DrillDownIconButton(
            svgPath: 'assets/icons/arrow-left.svg',
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.paymentHistory);
              }
            },
          ),

          // Title
          Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryC(context),
            ),
          ),

          // Notification Icon - Dark theme with badge
          DrillDownIconButton(
            svgPath: 'assets/main icons/line icons/notification.svg',
            badgeCount: notificationCount,
            onTap: () => context.go(Routes.notifications),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    PaymentModel payment,
    String studentName,
    String className,
    String admissionNumber,
    double amount,
    String feeName,
    bool isPaid,
  ) {
    final headerColor = isPaid ? AppColors.primary : const Color(0xFFDC2626);
    final amountColor = isPaid ? AppColors.primary : const Color(0xFFDC2626);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header (Green for success, Red for failed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: headerColor,
              child: Column(
                children: [
                  // Icon (Checkmark for success, X for failed)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF1F6FD), width: 1),
                    ),
                    child: Center(
                      child: isPaid
                          ? CustomPaint(
                              size: const Size(36, 36),
                              painter: _CheckmarkPainter(),
                            )
                          : CustomPaint(
                              size: const Size(36, 36),
                              painter: _CrossPainter(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Payment Status Text
                  Text(
                    isPaid ? 'Payment  Successful' : 'Payment  Failed',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.27,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Transaction Status Text
                  Text(
                    isPaid ? 'Transaction Completed' : 'Transaction In-completed',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Details Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.cardBg(context),
              child: Column(
                children: [
                  // Amount Section
                  Text(
                    isPaid ? 'Amount Paid' : 'Amount',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryC(context),
                      height: 1.47,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₹ ${_formatAmount(amount)}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                      height: 1.38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Container(
                    height: 1,
                    color: AppColors.borderC(context),
                  ),
                  const SizedBox(height: 16),
                  // Transaction Details
                  _buildDetailRow(context, 'Receipt No', payment.paymentNumber),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Student', studentName),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Class', className),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Admission No', admissionNumber),
                  if (payment.payreference != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(context, 'Transaction ID', payment.payreference!),
                  ],
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Payment Method', payment.paymentMethod),
                  const SizedBox(height: 16),
                  _buildDetailRowWithDot(
                    context,
                    'Date & Time',
                    _formatDate(payment.paidAt ?? payment.createdAt),
                    _formatTime(payment.paidAt ?? payment.createdAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryC(context),
            height: 1.43,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimaryC(context),
            height: 1.47,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowWithDot(BuildContext context, String label, String date, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryC(context),
            height: 1.43,
          ),
        ),
        Row(
          children: [
            Text(
              '$date ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimaryC(context),
                height: 1.47,
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textPrimaryC(context),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              ' $time',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimaryC(context),
                height: 1.47,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, PaymentModel payment, bool isPaid) {
    // If paid but pending approval, show pending message instead of download
    if (isPaid && payment.isPendingApproval) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange, width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon('timer', size: 22, color: Colors.orange),
            SizedBox(width: 10),
            Text(
              'Pending Approval',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Primary Button (Download for success, Retry for failed)
        Expanded(
          child: AmberButton(
            label: isPaid ? 'Download' : 'Retry',
            icon: isPaid ? 'document-download' : 'refresh',
            iconSize: 24,
            height: 48,
            radius: 12,
            onPressed: () async {
              if (isPaid) {
                await _handleDownloadOrShare(context, ref, payment, isShare: false);
              } else {
                await _handleRetryPayment(context, ref, payment);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        // Share Button — outlined with state feedback
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () async {
                await _handleDownloadOrShare(context, ref, payment, isShare: true);
              },
              borderRadius: BorderRadius.circular(12),
              hoverColor: const Color(0xFFD2913C).withValues(alpha: 0.06),
              focusColor: const Color(0xFFD2913C).withValues(alpha: 0.10),
              splashColor: const Color(0xFFD2913C).withValues(alpha: 0.14),
              highlightColor: const Color(0xFFD2913C).withValues(alpha: 0.06),
              mouseCursor: SystemMouseCursors.click,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E7E4), width: 1.5),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(
                        'share',
                        size: 24,
                        color: AppColors.textSecondaryC(context),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryC(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDownloadOrShare(BuildContext context, WidgetRef ref, PaymentModel payment, {required bool isShare}) async {
    if (isShare) {
      // Direct share — generate PDF and share
      await _generateAndExport(context, ref, payment, mode: _ExportMode.share);
      return;
    }

    // Show receipt preview dialog with Download/Print options
    // First show loading while fetching fee details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading receipt...'),
            ],
          ),
        ),
      ),
    );

    try {
      final student = ref.read(selectedStudentProvider);
      // .future awaits the FutureProvider so the receipt always has the
      // school header even on first open before the cache warms.
      final institution = await ref.read(selectedStudentWithInstitutionProvider.future);

      if (student == null) {
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
        return;
      }

      // Fetch fee details
      final details = await SupabaseService.fromSchema('paymentdetails')
          .select('*')
          .eq('pay_id', payment.payId)
          .eq('activestatus', 1);

      final detailModels = (details as List)
          .map((d) => PaymentDetailModel.fromJson(d))
          .toList();

      List<FeeModel> feeModels = [];
      if (detailModels.isNotEmpty) {
        final demIds = detailModels.map((d) => d.demId).toList();
        try {
          final fees = await SupabaseService.fromSchema('feedemand')
              .select('*, feetype(*, feegroup(*))')
              .inFilter('dem_id', demIds);
          feeModels = (fees as List).map((f) => FeeModel.fromJson(f)).toList();
        } catch (e) {
          final fees = await SupabaseService.fromSchema('feedemand')
              .select('*')
              .inFilter('dem_id', demIds);
          feeModels = (fees as List).map((f) => FeeModel.fromJson(f)).toList();
        }

        // Map paid amounts
        final detailMap = <int, PaymentDetailModel>{};
        for (final d in detailModels) {
          detailMap[d.demId] = d;
        }
        feeModels = feeModels.map((fee) {
          final detail = detailMap[fee.demId];
          return detail != null ? fee.copyWith(paidamount: detail.transtotalamount) : fee;
        }).toList();
      }

      final receiptData = _buildReceiptData(
        payment: payment,
        selectedStudent: student,
        institution: institution,
        fees: feeModels,
      );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      if (receiptData == null) return;

      // Show receipt preview dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => _ReceiptPreviewDialog(
          receiptData: receiptData,
          payment: payment,
          onDownload: () async {
            Navigator.of(dialogContext).pop();
            await _generateAndExport(context, ref, payment, mode: _ExportMode.download);
          },
          onPrint: () async {
            Navigator.of(dialogContext).pop();
            await _generateAndExport(context, ref, payment, mode: _ExportMode.print);
          },
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _generateAndExport(BuildContext context, WidgetRef ref, PaymentModel payment, {required _ExportMode mode}) async {
    bool loadingDialogOpen = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating receipt...'),
            ],
          ),
        ),
      ),
    );
    loadingDialogOpen = true;

    void dismissLoading() {
      if (loadingDialogOpen && context.mounted) {
        loadingDialogOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    try {
      final student = ref.read(selectedStudentProvider);
      // .future awaits the FutureProvider so the receipt always has the
      // school header even on first open before the cache warms.
      final institution = await ref.read(selectedStudentWithInstitutionProvider.future);

      if (student == null) {
        dismissLoading();
        return;
      }

      // Fetch fee details for the receipt table
      final details = await SupabaseService.fromSchema('paymentdetails')
          .select('*')
          .eq('pay_id', payment.payId)
          .eq('activestatus', 1);

      final detailModels = (details as List)
          .map((d) => PaymentDetailModel.fromJson(d))
          .toList();

      List<FeeModel> feeModels = [];
      if (detailModels.isNotEmpty) {
        final demIds = detailModels.map((d) => d.demId).toList();
        try {
          final fees = await SupabaseService.fromSchema('feedemand')
              .select('*, feetype(*, feegroup(*))')
              .inFilter('dem_id', demIds);
          feeModels = (fees as List).map((f) => FeeModel.fromJson(f)).toList();
        } catch (e) {
          final fees = await SupabaseService.fromSchema('feedemand')
              .select('*')
              .inFilter('dem_id', demIds);
          feeModels = (fees as List).map((f) => FeeModel.fromJson(f)).toList();
        }

        final detailMap = <int, PaymentDetailModel>{};
        for (final d in detailModels) {
          detailMap[d.demId] = d;
        }
        feeModels = feeModels.map((fee) {
          final detail = detailMap[fee.demId];
          return detail != null ? fee.copyWith(paidamount: detail.transtotalamount) : fee;
        }).toList();
      }

      final pdf = await generateReceiptPdf(
        payment: payment,
        student: student,
        institution: institution,
        feeDetails: feeModels,
      );

      final bytes = await pdf.save();

      dismissLoading();
      if (!context.mounted) return;

      final safeFilename = payment.paymentNumber.replaceAll('/', '_');

      if (mode == _ExportMode.share) {
        if (kIsWeb) {
          // Web: use print dialog as fallback since file sharing isn't supported
          await Printing.layoutPdf(
            onLayout: (_) async => bytes,
            name: '$safeFilename.pdf',
            format: kReceiptPageFormat,
          );
        } else {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$safeFilename.pdf');
          await file.writeAsBytes(bytes);
          await Share.shareXFiles(
            [XFile(file.path)],
            text: 'Payment Receipt - ${payment.paymentNumber}',
          );
        }
      } else if (mode == _ExportMode.download) {
        // Use system print/save dialog — works on web, desktop, and mobile
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: '$safeFilename.pdf',
          format: kReceiptPageFormat,
        );
      } else {
        // Print mode
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: '$safeFilename.pdf',
          format: kReceiptPageFormat,
        );
      }
    } catch (e) {
      dismissLoading();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleRetryPayment(BuildContext context, WidgetRef ref, PaymentModel payment) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Get dem_ids from paymentdetails for this payment
      final payDetails = await SupabaseService.fromSchema('paymentdetails')
          .select('dem_id')
          .eq('pay_id', payment.payId);

      final demIds = (payDetails as List)
          .map((d) => d['dem_id'] is int ? d['dem_id'] as int : int.parse(d['dem_id'].toString()))
          .toList();

      if (demIds.isEmpty) {
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fee details found for this payment'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 2. Fetch fresh feedemand records to check current status
      final fees = await SupabaseService.fromSchema('feedemand')
          .select('*')
          .inFilter('dem_id', demIds)
          .eq('activestatus', 1);

      final feeModels = (fees as List)
          .map((f) => FeeModel.fromJson(f))
          .toList();

      // 3. Filter to only unpaid fees (balancedue > 0 and paidstatus != 'P')
      final unpaidFees = feeModels
          .where((f) => f.balancedue > 0 && f.paidstatus != 'P')
          .toList();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      if (unpaidFees.isEmpty) {
        // All fees already paid
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: const AppIcon('tick-circle', color: Color(0xFF2DBE60), size: 48),
            title: const Text('Already Paid'),
            content: const Text('All fees from this payment have already been paid.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Add unpaid fees to cart and navigate
        final cartNotifier = ref.read(cartProvider.notifier);
        cartNotifier.clearCart();
        cartNotifier.addFees(unpaidFees);

        if (context.mounted) {
          context.go(Routes.cart);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0';
    final parts = amount.toStringAsFixed(0).split('');
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        final posFromEnd = parts.length - i;
        if (posFromEnd == 3 || (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0)) {
          result.add(',');
        }
      }
      result.add(parts[i]);
    }
    return result.join('');
  }

  String _formatDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'pm' : 'am';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

/// Custom painter for checkmark icon (success)
class _CheckmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    // Draw checkmark shape
    path.moveTo(size.width * 0.15, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.75);
    path.lineTo(size.width * 0.85, size.height * 0.25);
    path.lineTo(size.width * 0.75, size.height * 0.15);
    path.lineTo(size.width * 0.4, size.height * 0.55);
    path.lineTo(size.width * 0.25, size.height * 0.4);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for X icon (failed)
class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw X shape
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.75),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.25),
      Offset(size.width * 0.25, size.height * 0.75),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Receipt preview dialog with Download/Print/Close actions
class _ReceiptPreviewDialog extends StatelessWidget {
  final ReceiptData receiptData;
  final PaymentModel payment;
  final VoidCallback onDownload;
  final VoidCallback onPrint;

  const _ReceiptPreviewDialog({
    required this.receiptData,
    required this.payment,
    required this.onDownload,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 650 ? 620.0 : screenSize.width * 0.92;
    final receiptScale = (dialogWidth - 32) / 499; // 499 is ISO B5 width, 32 for padding

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.9),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top action bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  // Download button
                  _ActionButton(
                    icon: 'document-download',
                    label: 'Download',
                    onTap: onDownload,
                    filled: false,
                  ),
                  const SizedBox(width: 12),
                  // Print button
                  _ActionButton(
                    icon: 'printer',
                    label: 'Print',
                    onTap: onPrint,
                    filled: true,
                  ),
                  const Spacer(),
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const AppIcon('close-circle', size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            // Receipt preview (scrollable). Receipt is fixed ISO B5 = 499 x 709 pt.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: dialogWidth - 32,
                  height: 709 * receiptScale,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 499,
                      height: 709,
                      child: ReceiptWidget(data: receiptData),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF6C8EEF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: filled ? null : Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 18, color: filled ? Colors.white : AppColors.textSecondaryC(context)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: filled ? Colors.white : AppColors.textSecondaryC(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
