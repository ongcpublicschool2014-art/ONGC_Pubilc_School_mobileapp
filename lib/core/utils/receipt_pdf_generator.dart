import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/institution_model.dart';
import '../../data/models/fee_model.dart';
import '../../receipt_widget.dart';
import '../services/supabase_service.dart';

/// Builds a ReceiptData from the mobile-app's payment/student/institution/fees
/// models. Mirrors `_buildReceiptData` in transaction_details_screen.dart so
/// the PDF and the on-screen preview always show the same numbers.
ReceiptData _buildReceiptData({
  required PaymentModel payment,
  required StudentModel student,
  InstitutionModel? institution,
  List<FeeModel>? feeDetails,
  ({String name, String address, String banner})? letterhead,
}) {
  final dateFormat = DateFormat('dd MMM yyyy');
  final payDate = payment.paydate ?? payment.createdat;

  // Group fees by term. Mirrors the admin app: split fine into its own
  // ReceiptFeeItem so the receipt shows e.g. "TUITION FEES 1,400" + "Fine 100"
  // instead of a single bundled "TUITION FEES 1,500".
  final feesByTerm = <String, List<ReceiptFeeItem>>{};
  if (feeDetails != null) {
    for (final fee in feeDetails) {
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
  }

  final termDetails = feesByTerm.entries
      .map((e) => ReceiptTermDetail(term: e.key, fees: e.value))
      .toList();

  // For an ARREAR receipt the Branch is the arrear's ORIGINAL class
  // (fee.arrearclass), matching the admin app — not the student's current course.
  String? arrearBranch;
  if (feeDetails != null) {
    for (final fee in feeDetails) {
      if (fee.isArrear) {
        final ac = fee.arrearClassLabel;
        if (ac.isNotEmpty) {
          arrearBranch = ac;
          break;
        }
      }
    }
  }

  return ReceiptData(
    receiptNo: payment.paymentNumber,
    date: dateFormat.format(payDate),
    studentName: student.name,
    mobileNo: student.stumobile,
    address: student.fullAddress,
    admissionNo: student.admissionNumber,
    className: student.className,
    courseName: (arrearBranch != null && arrearBranch.isNotEmpty)
        ? arrearBranch
        : student.courseName,
    schoolName: letterhead?.name ?? institution?.insname ?? '',
    schoolAddress: letterhead?.address ?? institution?.fullAddress ?? '',
    headerBanner: letterhead?.banner ?? '',
    schoolLogoUrl: institution?.inslogo,
    schoolMobile: institution?.insmobno,
    schoolEmail: institution?.insmail,
    feeDetails: termDetails,
    paymentMethod: payment.paymentMethod,
    paymentDate: dateFormat.format(payDate),
    status: payment.paystatus == 'C'
        ? 'paid'
        : payment.paystatus == 'F'
            ? 'failed'
            : 'pending',
    total: payment.transtotalamount,
  );
}

/// Wrapper kept for the existing call site in transaction_details_screen.dart.
/// Builds a [ReceiptData] from the supplied models and renders via
/// [buildReceiptPdf], which is a 1:1 port of the admin app's receipt PDF.
Future<pw.Document> generateReceiptPdf({
  required PaymentModel payment,
  required StudentModel student,
  InstitutionModel? institution,
  List<FeeModel>? feeDetails,
}) async {
  // Resolved from THIS receipt's fee types, so a hostel receipt prints the
  // hostel letterhead and a college one the college's -- the admin app's rule.
  final letterhead = await SupabaseService.receiptLetterhead(
    insId: student.insId,
    feeTypes: [for (final f in (feeDetails ?? const <FeeModel>[])) f.feeTypeName],
    fallbackName: institution?.insname ?? '',
    fallbackAddress: institution?.fullAddress ?? '',
  );
  final data = _buildReceiptData(
    payment: payment,
    student: student,
    institution: institution,
    feeDetails: feeDetails,
    letterhead: letterhead,
  );
  return buildReceiptPdf(data);
}

/// Builds the B5 fee-receipt PDF — a 1:1 match of [ReceiptWidget] and the
/// admin app's Figma "Receipt" design.
Future<pw.Document> buildReceiptPdf(ReceiptData data) async {
  // Prefer bundled Inter fonts (already shipped in assets/fonts) — falls back
  // to PdfGoogleFonts CDN if the bundled assets can't be loaded.
  pw.Font reg, med, semi, bold;
  try {
    reg = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
    med = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Medium.ttf'));
    semi = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
    bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  } catch (_) {
    reg = await PdfGoogleFonts.interRegular();
    med = await PdfGoogleFonts.interMedium();
    semi = await PdfGoogleFonts.interSemiBold();
    bold = await PdfGoogleFonts.interBold();
  }

  pw.ImageProvider? logo;
  if ((data.schoolLogoUrl ?? '').isNotEmpty) {
    try {
      logo = await networkImage(data.schoolLogoUrl!);
    } catch (_) {/* fall back to a logo-less header */}
  }

  // The fee group's OWN banner (letterhead_banner_<fg_id>) when one is
  // mapped; only otherwise the name-matched college artwork. Matching on the
  // institution name alone printed the college header on hostel receipts --
  // the institution is a college either way, so the name cannot tell them
  // apart. A mapped banner may be a bundled asset or an https URL.
  pw.ImageProvider? banner;
  pw.ImageProvider? crest;
  final mapped = data.headerBanner.trim();
  final bannerAsset =
      mapped.isNotEmpty ? mapped : receiptHeaderImage(data.schoolName);
  if (bannerAsset != null && bannerAsset.isNotEmpty) {
    try {
      banner = bannerAsset.startsWith('http')
          ? await networkImage(bannerAsset)
          : await imageFromAssetBundle(bannerAsset);
      crest = await imageFromAssetBundle('assets/images/KMPTC Logo.jpg');
    } catch (_) {/* fall back to logo + text */}
  }

  const black = PdfColors.black;
  // ISO B5 — 176 × 250 mm.
  final b5 = PdfPageFormat(176 * PdfPageFormat.mm, 250 * PdfPageFormat.mm);
  const divider = pw.BorderSide(color: black, width: 1);
  const amountColWidth = 120.0;

  pw.TextStyle st(double size, pw.Font f) =>
      pw.TextStyle(font: f, fontSize: size, color: black);

  pw.Widget kv(String label, String value) => pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(text: '$label : ', style: st(10, semi)),
          pw.TextSpan(
              text: value.trim().isEmpty ? '-' : value, style: st(10, reg)),
        ]),
      );

  pw.Widget infoCell(List<pw.Widget> lines) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            for (var i = 0; i < lines.length; i++) ...[
              if (i > 0) pw.SizedBox(height: 8),
              lines[i],
            ],
          ],
        ),
      );

  final particulars = flattenParticulars(data);

  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: b5,
      margin: const pw.EdgeInsets.all(40),
      theme: pw.ThemeData.withFont(base: reg, bold: bold),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header — centered college banner, or logo + text fallback.
            if (banner != null)
              // Three-grid header: 25% logo | 50% banner | 25% empty.
              pw.SizedBox(
                height: 100,
                child: pw.Row(
                  children: [
                    // 16% logo | 4% gap | 60% banner | 4% gap | 16% empty.
                    pw.Expanded(
                      flex: 4,
                      child: pw.Center(
                        child: crest != null
                            ? pw.Image(crest, height: 88)
                            : pw.SizedBox(),
                      ),
                    ),
                    pw.Expanded(flex: 1, child: pw.SizedBox()),
                    pw.Expanded(
                      flex: 15,
                      child: pw.Center(
                        child: pw.Image(banner, fit: pw.BoxFit.contain),
                      ),
                    ),
                    pw.Expanded(flex: 1, child: pw.SizedBox()),
                    pw.Expanded(flex: 4, child: pw.SizedBox()),
                  ],
                ),
              )
            else
              pw.SizedBox(
                height: 82,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logo != null) ...[
                      pw.SizedBox(
                          width: 70,
                          height: 70,
                          child: pw.Image(logo, fit: pw.BoxFit.contain)),
                      pw.SizedBox(width: 14),
                    ],
                    pw.Flexible(
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(data.schoolName, style: st(15, bold)),
                          pw.SizedBox(height: 3),
                          pw.Text(data.schoolAddress,
                              maxLines: 2, style: st(9, med)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Text('RECEIPT', style: st(13, bold))),
            pw.SizedBox(height: 8),
            // Bordered receipt table — content-sized (no Expanded), so the
            // PDF layout engine renders every row reliably.
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: black, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Info row — student details | receipt details.
                  pw.Container(
                    height: 74,
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: infoCell([
                            kv('Name', data.studentName),
                            kv('Admission No.', data.admissionNo),
                            kv('Branch', data.courseName),
                            // Payment mode, matching the admin app's receipt.
                            kv('Mode', data.paymentMethod.isEmpty ? '-' : data.paymentMethod),
                          ]),
                        ),
                        pw.Container(width: 1, height: 74, color: black),
                        pw.Expanded(
                          child: infoCell([
                            kv('Receipt No', data.receiptNo),
                            kv('Date', data.date),
                            kv('Term', receiptSemesterLabel(data)),
                            // Gateway transaction reference — the student's
                            // proof of an online payment, and what support
                            // needs when tracing one.
                            kv('Txn ID', (data.paymentReference ?? '').trim().isEmpty
                                ? '-'
                                : data.paymentReference!.trim()),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  // Column headings.
                  pw.Container(
                    height: 30,
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(top: divider)),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            height: 30,
                            alignment: pw.Alignment.center,
                            child: pw.Text('PARTICULARS',
                                style: st(11, bold)),
                          ),
                        ),
                        pw.Container(width: 1, height: 30, color: black),
                        pw.Container(
                          width: amountColWidth,
                          height: 30,
                          alignment: pw.Alignment.centerRight,
                          padding:
                              const pw.EdgeInsets.symmetric(horizontal: 12),
                          child: pw.Text('AMOUNTS (Rs)',
                              style: st(11, bold)),
                        ),
                      ],
                    ),
                  ),
                  // Particulars.
                  pw.Container(
                    height: 240,
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(top: divider)),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            height: 240,
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: pw.Column(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                              children: [
                                for (var i = 0;
                                    i < particulars.length;
                                    i++) ...[
                                  if (i > 0) pw.SizedBox(height: 6),
                                  pw.Text(
                                      '${i + 1}. ${particulars[i].type}',
                                      style: st(10.5, reg)),
                                ],
                              ],
                            ),
                          ),
                        ),
                        pw.Container(width: 1, height: 240, color: black),
                        pw.Container(
                          width: amountColWidth,
                          height: 240,
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              for (var i = 0;
                                  i < particulars.length;
                                  i++) ...[
                                if (i > 0) pw.SizedBox(height: 6),
                                pw.Text(
                                    formatReceiptAmount(
                                        particulars[i].amount),
                                    style: st(10.5, reg)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Total row.
                  pw.Container(
                    height: 32,
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(top: divider)),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            height: 32,
                            alignment: pw.Alignment.centerRight,
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12),
                            child: pw.Text('TOTAL', style: st(12, bold)),
                          ),
                        ),
                        pw.Container(width: 1, height: 32, color: black),
                        pw.Container(
                          width: amountColWidth,
                          height: 32,
                          alignment: pw.Alignment.centerRight,
                          padding:
                              const pw.EdgeInsets.symmetric(horizontal: 12),
                          child: pw.Text(formatReceiptAmount(data.total),
                              style: st(12, bold)),
                        ),
                      ],
                    ),
                  ),
                  // Footer — amount in words + cashier signature line.
                  pw.Container(
                    height: 110,
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(top: divider)),
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(amountInWords(data.total),
                            style: st(11, med)),
                        pw.Spacer(),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.only(right: 34),
                          child: pw.Text('Cashier',
                              textAlign: pw.TextAlign.right,
                              style: st(12, bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
  return pdf;
}
