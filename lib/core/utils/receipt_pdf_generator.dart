import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../data/models/payment_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/institution_model.dart';
import '../../data/models/fee_model.dart';
import '../../../receipt_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants per design spec
// ─────────────────────────────────────────────────────────────────────────────
const _kBlack = PdfColor.fromInt(0xFF000000);
const _kRealizationOrange = PdfColor.fromInt(0xFFB85C00);

/// ISO B5 — 176 × 250 mm (~499 × 709 pt). Matches the on-screen ReceiptWidget.
/// Pass this to `Printing.layoutPdf(format: ...)` so the print dialog targets
/// B5 paper instead of falling back to the printer's loaded paper (often A4).
const kReceiptPageFormat = PdfPageFormat(176 * PdfPageFormat.mm, 250 * PdfPageFormat.mm);

const double _kFontSize = 9;
const double _kAmountCol = 120;
// Match widget: 48pt page margin, 120pt header, particulars fills remaining space.
const double _kPageMargin = 48;
const double _kHeaderHeight = 120;
const double _kInfoHeight = 90;
const double _kSectionHeaderHeight = 30;
// B5 (709pt) - 2*48 margin - 120 header - 10 - 12 RECEIPT - 8 spacing
//   - 90 info - 30 section header - 32 total - 78 footer - ~4 borders ≈ 230pt
const double _kParticularsHeight = 230;
const double _kTotalRowHeight = 32;
const double _kFooterHeight = 78;

/// Builds the printable A5 fee receipt. Layout mirrors the on-screen
/// `ReceiptWidget` 1:1 — any layout change must update both.
Future<pw.Document> generateReceiptPdf({
  required PaymentModel payment,
  required StudentModel student,
  InstitutionModel? institution,
  List<FeeModel>? feeDetails,
}) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
  final medium = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Medium.ttf'));
  final semibold = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Bold.ttf'));

  final data = _buildReceiptData(
    payment: payment,
    student: student,
    institution: institution,
    feeDetails: feeDetails,
  );

  // Logo: download once and reuse, since pw.Image needs ImageProvider, not a URL.
  pw.MemoryImage? logo;
  if ((data.schoolLogoUrl ?? '').isNotEmpty) {
    try {
      final res = await http.get(Uri.parse(data.schoolLogoUrl!));
      if (res.statusCode == 200) logo = pw.MemoryImage(res.bodyBytes);
    } catch (_) {/* fall back to text-only header */}
  }

  // Optional banner asset by school name (engineering/polytechnic/etc.).
  pw.MemoryImage? banner;
  pw.MemoryImage? crest;
  final bannerPath = receiptHeaderImage(data.schoolName);
  if (bannerPath != null) {
    try {
      final b = await rootBundle.load(bannerPath);
      banner = pw.MemoryImage(b.buffer.asUint8List());
      final c = await rootBundle.load('assets/images/KMPTC Logo.jpg');
      crest = pw.MemoryImage(c.buffer.asUint8List());
    } catch (_) {/* asset missing — fall through to fallback header */}
  }

  final theme = pw.ThemeData.withFont(
    base: regular,
    bold: bold,
    italic: regular,
    boldItalic: bold,
  );

  final pdf = pw.Document(theme: theme);
  pdf.addPage(
    pw.Page(
      pageFormat: kReceiptPageFormat,
      margin: const pw.EdgeInsets.all(_kPageMargin),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _pdfHeader(data, logo: logo, banner: banner, crest: crest, semibold: semibold, medium: medium, bold: bold),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text('RECEIPT', style: pw.TextStyle(font: bold, fontSize: _kFontSize, color: _kBlack)),
            ),
            pw.SizedBox(height: 8),
            // Table fills the full content width (mirrors widget's stretch).
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _kBlack, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _pdfInfoRow(data, semibold: semibold, regular: regular),
                  _pdfTopBorder(_pdfSectionHeader(bold: bold)),
                  _pdfTopBorder(_pdfParticulars(data, regular: regular)),
                  _pdfTopBorder(_pdfTotalRow(data, bold: bold)),
                  _pdfTopBorder(_pdfFooter(data, semibold: semibold, bold: bold)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Data build (mirrors transaction_details_screen.dart::_buildReceiptData)
// ─────────────────────────────────────────────────────────────────────────────

ReceiptData _buildReceiptData({
  required PaymentModel payment,
  required StudentModel student,
  InstitutionModel? institution,
  List<FeeModel>? feeDetails,
}) {
  final dateFormat = DateFormat('dd MMM yyyy');
  final payDate = payment.paydate ?? payment.createdat;

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

  final addressParts = <String>[
    if ((institution?.insaddress1 ?? '').isNotEmpty) institution!.insaddress1!,
    if ((institution?.insaddress2 ?? '').isNotEmpty) institution!.insaddress2!,
    if ((institution?.inspincode ?? '').isNotEmpty) institution!.inspincode!,
  ];

  return ReceiptData(
    receiptNo: payment.paymentNumber,
    date: dateFormat.format(payDate),
    studentName: student.name,
    mobileNo: student.stumobile,
    address: student.fullAddress,
    admissionNo: student.admissionNumber,
    className: student.className,
    schoolName: institution?.insname ?? '',
    schoolAddress: addressParts.join(', '),
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

// ─────────────────────────────────────────────────────────────────────────────
// PDF render — header
// ─────────────────────────────────────────────────────────────────────────────

pw.Widget _pdfHeader(
  ReceiptData data, {
  pw.MemoryImage? logo,
  pw.MemoryImage? banner,
  pw.MemoryImage? crest,
  required pw.Font semibold,
  required pw.Font medium,
  required pw.Font bold,
}) {
  if (banner != null) {
    return pw.SizedBox(
      height: _kHeaderHeight,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            flex: 30,
            child: crest != null
                ? pw.Image(crest, height: 72, fit: pw.BoxFit.contain)
                : pw.SizedBox.shrink(),
          ),
          pw.Expanded(flex: 70, child: pw.Image(banner, fit: pw.BoxFit.contain)),
        ],
      ),
    );
  }
  // Fallback header: logo on left, school name + address rendered banner-style —
  // large centered title and centered address filling the rest of the width.
  return pw.SizedBox(
    height: _kHeaderHeight,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null) ...[
          pw.SizedBox(width: 90, height: 90, child: pw.Image(logo, fit: pw.BoxFit.contain)),
          pw.SizedBox(width: 12),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                data.schoolName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: bold, fontSize: 18, color: _kBlack, letterSpacing: 0.5),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                data.schoolAddress,
                textAlign: pw.TextAlign.center,
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(font: medium, fontSize: 10, color: _kBlack),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF render — table sections
// ─────────────────────────────────────────────────────────────────────────────

pw.Widget _pdfTopBorder(pw.Widget child) {
  return pw.Container(
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _kBlack, width: 1)),
    ),
    child: child,
  );
}

pw.Widget _pdfInfoRow(
  ReceiptData data, {
  required pw.Font semibold,
  required pw.Font regular,
}) {
  return pw.SizedBox(
    height: _kInfoHeight,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(
          child: _pdfInfoCell(
            [
              ['Name', data.studentName],
              ['Reg. No', data.admissionNo],
              ['Branch', data.className],
              ['Mode', data.paymentMethod],
            ],
            semibold: semibold,
            regular: regular,
          ),
        ),
        pw.Container(width: 1, color: _kBlack),
        pw.Expanded(
          child: _pdfInfoCell(
            [
              ['Receipt No', data.receiptNo],
              ['Date', data.date],
              ['Sem', receiptSemesterLabel(data)],
              ['Txn ID', ReceiptWidget.formatReference(data.paymentReference)],
            ],
            semibold: semibold,
            regular: regular,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _pdfInfoCell(
  List<List<String>> rows, {
  required pw.Font semibold,
  required pw.Font regular,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) pw.SizedBox(height: 8),
          _pdfKv(rows[i][0], rows[i][1], semibold: semibold, regular: regular),
        ],
      ],
    ),
  );
}

pw.Widget _pdfKv(
  String label,
  String value, {
  required pw.Font semibold,
  required pw.Font regular,
}) {
  final v = value.trim().isEmpty ? '-' : value;
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('$label : ',
          style: pw.TextStyle(font: semibold, fontSize: _kFontSize, color: _kBlack)),
      pw.Expanded(
        child: pw.Text(
          v,
          maxLines: 2,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(font: regular, fontSize: _kFontSize, color: _kBlack),
        ),
      ),
    ],
  );
}

/// Two-cell row with a 1pt vertical divider between PARTICULARS and AMOUNTS.
pw.Widget _pdfTwoCellRow({
  required pw.Widget left,
  required pw.Widget right,
  required double height,
  required pw.EdgeInsets leftPadding,
  required pw.EdgeInsets rightPadding,
}) {
  return pw.SizedBox(
    height: height,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(child: pw.Padding(padding: leftPadding, child: left)),
        pw.Container(width: 1, color: _kBlack),
        pw.SizedBox(
          width: _kAmountCol,
          child: pw.Padding(padding: rightPadding, child: right),
        ),
      ],
    ),
  );
}

pw.Widget _pdfSectionHeader({required pw.Font bold}) {
  return _pdfTwoCellRow(
    height: _kSectionHeaderHeight,
    leftPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    rightPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    left: pw.Center(
      child: pw.Text('PARTICULARS',
          style: pw.TextStyle(font: bold, fontSize: _kFontSize, color: _kBlack)),
    ),
    right: pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('AMOUNTS (Rs)',
          style: pw.TextStyle(font: bold, fontSize: _kFontSize, color: _kBlack)),
    ),
  );
}

pw.Widget _pdfParticulars(ReceiptData data, {required pw.Font regular}) {
  final items = flattenParticulars(data);
  return _pdfTwoCellRow(
    height: _kParticularsHeight,
    leftPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    rightPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    left: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) pw.SizedBox(height: 6),
          pw.Text('${i + 1}. ${items[i].type}',
              style: pw.TextStyle(font: regular, fontSize: _kFontSize, color: _kBlack)),
        ],
      ],
    ),
    right: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) pw.SizedBox(height: 6),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(formatReceiptAmount(items[i].amount),
                style: pw.TextStyle(font: regular, fontSize: _kFontSize, color: _kBlack)),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _pdfTotalRow(ReceiptData data, {required pw.Font bold}) {
  return _pdfTwoCellRow(
    height: _kTotalRowHeight,
    leftPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    rightPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    left: pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('TOTAL',
          style: pw.TextStyle(font: bold, fontSize: _kFontSize, color: _kBlack)),
    ),
    right: pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(formatReceiptAmount(data.total),
          style: pw.TextStyle(font: bold, fontSize: _kFontSize, color: _kBlack)),
    ),
  );
}

pw.Widget _pdfFooter(
  ReceiptData data, {
  required pw.Font semibold,
  required pw.Font bold,
}) {
  final showRealization = data.reconStatus != 'R';
  return pw.SizedBox(
    height: _kFooterHeight,
    child: pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 34, 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            amountInWords(data.total),
            style: pw.TextStyle(font: semibold, fontSize: _kFontSize, color: _kBlack),
          ),
          if (showRealization) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              '* Subject to Realization',
              style: pw.TextStyle(font: semibold, fontSize: _kFontSize, color: _kRealizationOrange),
            ),
          ],
          pw.Spacer(),
          pw.Align(
            alignment: pw.Alignment.bottomRight,
            child: pw.Text('Cashier',
                style: pw.TextStyle(font: bold, fontSize: _kFontSize, color: _kBlack)),
          ),
        ],
      ),
    ),
  );
}
