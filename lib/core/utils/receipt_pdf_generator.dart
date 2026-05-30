import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../data/models/payment_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/institution_model.dart';
import '../../data/models/fee_model.dart';

// Figma color palette (matching receipt_widget.dart)
const _kPrimaryBlue = PdfColor.fromInt(0xFF6C8EEF);
const _kDarkBlue = PdfColor.fromInt(0xFF4A6CD4);
const _kTextDark = PdfColor.fromInt(0xFF2a2a2a);
const _kTextMedium = PdfColor.fromInt(0xFF4c4c4c);
const _kHeaderBg = PdfColor.fromInt(0xFFE9EEFF);
const _kBorderColor = PdfColor.fromInt(0xFFd9d9d9);
const _kDividerColor = PdfColor.fromInt(0xFFACBEDD);

/// Term + fee items for receipt table
class _ReceiptTerm {
  final String term;
  final List<(String type, double amount)> fees;
  _ReceiptTerm({required this.term, required this.fees});
}

Future<pw.Document> generateReceiptPdf({
  required PaymentModel payment,
  required StudentModel student,
  InstitutionModel? institution,
  List<FeeModel>? feeDetails,
}) async {
  // Load fonts that support Rupee symbol (₹)
  final fontRegular = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();
  final fontItalic = await PdfGoogleFonts.notoSansItalic();

  final pdf = pw.Document();
  final isPaid = payment.paystatus == 'C';
  final isFailed = payment.paystatus == 'F';

  // Theme with Unicode-supporting font
  final theme = pw.ThemeData.withFont(
    base: fontRegular,
    bold: fontBold,
    italic: fontItalic,
    boldItalic: fontBold,
  );

  final dateFormat = DateFormat('dd MMM yyyy');
  final payDate = payment.paydate ?? payment.createdat;
  final dateStr = dateFormat.format(payDate);

  final addressParts = <String>[
    if (institution?.insaddress1 != null) institution!.insaddress1!,
    if (institution?.insaddress2 != null) institution!.insaddress2!,
    if (institution?.inspincode != null) institution!.inspincode!,
  ];

  // Try to load school logo
  pw.MemoryImage? logoImage;
  if (institution?.inslogo != null) {
    try {
      final response = await http.get(Uri.parse(institution!.inslogo!));
      if (response.statusCode == 200) {
        logoImage = pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {}
  }

  // Group fees by term. Mirrors the admin app: any fine is listed as a
  // separate "Fine" line item beneath the fee row, not bundled into the total.
  final terms = <_ReceiptTerm>[];
  if (feeDetails != null && feeDetails.isNotEmpty) {
    final feesByTerm = <String, List<(String, double)>>{};
    for (final fee in feeDetails) {
      final termKey = fee.demfeeterm;
      final collected = fee.paidamount > 0 ? fee.paidamount : fee.feeamount;
      final fine = fee.fineamount;
      final feeOnly = (collected - fine).clamp(0, double.infinity).toDouble();
      feesByTerm.putIfAbsent(termKey, () => []).add(
        (fee.feeTypeName, feeOnly),
      );
      if (fine > 0) {
        feesByTerm[termKey]!.add(('  Fine', fine));
      }
    }
    for (final entry in feesByTerm.entries) {
      terms.add(_ReceiptTerm(term: entry.key, fees: entry.value));
    }
  }

  // Pagination: max items per page
  const maxItemsFirstPage = 8;
  const maxItemsContinuation = 12;

  final List<(int startIdx, List<_ReceiptTerm> items, bool isFirst, bool isLast)> pages = [];
  if (terms.isEmpty) {
    pages.add((0, <_ReceiptTerm>[], true, true));
  } else if (terms.length <= maxItemsFirstPage) {
    pages.add((0, terms, true, true));
  } else {
    pages.add((0, terms.sublist(0, maxItemsFirstPage), true, false));
    int offset = maxItemsFirstPage;
    int remaining = terms.length - maxItemsFirstPage;
    while (remaining > 0) {
      final count = remaining <= maxItemsContinuation ? remaining : maxItemsContinuation;
      final isLast = count >= remaining;
      pages.add((offset, terms.sublist(offset, offset + count), false, isLast));
      offset += count;
      remaining -= count;
    }
  }

  for (int pageIdx = 0; pageIdx < pages.length; pageIdx++) {
    final (startIdx, items, isFirst, isLast) = pages[pageIdx];
    final pageNum = pageIdx + 1;
    final totalPages = pages.length;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        build: (context) {
          final content = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildPdfHeader(institution, logoImage, addressParts, dateStr, payment.paymentNumber, pageNum, totalPages, payment.paymethod, isPaid, isFailed, payment.statusText),
              pw.SizedBox(height: 12),
              pw.Container(height: 1, color: _kDividerColor),
              pw.SizedBox(height: 12),

              // Student info (first page only)
              if (isFirst) ...[
                _buildPdfStudentInfo(student),
                pw.SizedBox(height: 20),
              ],

              // Fee table
              if (items.isNotEmpty)
                _buildPdfFeeTable(items, startIdx, isLast, payment.transtotalamount),

              if (isLast) ...[
                pw.Spacer(),
                // Footer
                pw.Center(
                  child: pw.Text(
                    'Thank you for your payment.',
                    style: pw.TextStyle(fontSize: 14, color: _kTextDark, fontStyle: pw.FontStyle.italic),
                  ),
                ),
                pw.SizedBox(height: 8),
                if (institution?.insmail != null || institution?.insmobno != null)
                  pw.Center(
                    child: pw.Text(
                      'For any further inquiries, please contact us at ${institution?.insmail ?? ''}'
                      '${institution?.insmail != null && institution?.insmobno != null ? ' or call ' : ''}'
                      '${institution?.insmobno ?? ''}',
                      style: const pw.TextStyle(fontSize: 10, color: _kTextMedium),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
              ] else ...[
                pw.Spacer(),
                pw.Center(
                  child: pw.Text(
                    'Continued on next page...',
                    style: pw.TextStyle(fontSize: 10, color: _kTextMedium, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ],
          );

          return pw.Stack(
            children: [
              // Background logo watermark (center of page)
              if (logoImage != null)
                pw.Positioned.fill(
                  child: pw.Center(
                    child: pw.Opacity(
                      opacity: 0.05,
                      child: pw.Image(logoImage, width: 200, height: 200, fit: pw.BoxFit.contain),
                    ),
                  ),
                ),
              // Main content
              content,
              // PAID/FAILED stamp overlay — over Term & Fee Type columns
              if (isPaid || isFailed)
                pw.Positioned(
                  left: 130,
                  top: isFirst ? 310 : 80,
                  child: pw.Transform.rotateBox(
                    angle: -0.35,
                    child: pw.Opacity(
                      opacity: 0.55,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: isPaid
                              ? const PdfColor.fromInt(0x66c2eecd)
                              : const PdfColor.fromInt(0x66FFD6D6),
                          border: pw.Border.all(
                            color: isPaid ? const PdfColor.fromInt(0xFF34c759) : const PdfColor.fromInt(0xFFFF3B30),
                            width: 2,
                          ),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          isPaid ? 'PAID' : 'FAILED',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: isPaid ? const PdfColor.fromInt(0xFF34c759) : const PdfColor.fromInt(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  return pdf;
}

// ── PDF Helpers ──────────────────────────────────────────────────────────

pw.Widget _buildPdfHeader(
  InstitutionModel? institution,
  pw.MemoryImage? logoImage,
  List<String> addressParts,
  String dateStr,
  String receiptNo,
  int pageNum,
  int totalPages,
  String? payMethod,
  bool isPaid,
  bool isFailed,
  String statusText,
) {
  final methodLabel = payMethod?.toLowerCase() == 'razorpay' ? 'Online' : (payMethod ?? '-');
  final statusLabel = isPaid ? 'Paid' : isFailed ? 'Failed' : statusText;
  return pw.Column(
    children: [
      // Logo + school name
      pw.Center(
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoImage != null) ...[
              pw.Image(logoImage, width: 48, height: 48, fit: pw.BoxFit.cover),
              pw.SizedBox(width: 12),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  institution?.insname ?? '',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _kDarkBlue),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  addressParts.join(', '),
                  style: const pw.TextStyle(fontSize: 9, color: _kTextMedium),
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 14),
      // Fee Receipt + receipt no + date  ||  Receipt Method + Status
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Fee Receipt', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _kPrimaryBlue)),
              pw.SizedBox(height: 6),
              _pdfLabelValue('Receipt No:', receiptNo),
              pw.SizedBox(height: 3),
              _pdfLabelValue('Date:', dateStr),
            ],
          ),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (totalPages > 1) ...[
                pw.Text('Page $pageNum of $totalPages', style: const pw.TextStyle(fontSize: 9, color: _kTextMedium)),
                pw.SizedBox(height: 6),
              ] else
                pw.SizedBox(height: 22),
              _pdfLabelValue('Receipt Method:', methodLabel),
              pw.SizedBox(height: 3),
              _pdfLabelValue('Status:', statusLabel),
            ],
          ),
        ],
      ),
    ],
  );
}

pw.Widget _buildPdfStudentInfo(StudentModel student) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('To:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _kTextDark)),
      pw.SizedBox(height: 8),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfLabelValue('Name:', student.stuname),
                pw.SizedBox(height: 6),
                _pdfLabelValue('Mobile No:', student.stumobile),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Address:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _kTextDark)),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Text(student.fullAddress, style: const pw.TextStyle(fontSize: 10, color: _kTextMedium)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _pdfLabelValue('Admission No:', student.stuadmno),
              pw.SizedBox(height: 6),
              _pdfLabelValue('Standard:', student.courseName),
              pw.SizedBox(height: 6),
              _pdfLabelValue('Class:', student.stuclass),
            ],
          ),
        ],
      ),
    ],
  );
}

pw.Widget _buildPdfFeeTable(List<_ReceiptTerm> items, int startIdx, bool isLast, double total) {
  return pw.Column(
    children: [
      // Table header
      pw.Container(
        decoration: pw.BoxDecoration(
          color: _kHeaderBg,
          border: pw.Border.all(color: _kBorderColor, width: 1),
        ),
        child: pw.Row(
          children: [
            _pdfHeaderCell('S.No', 46),
            pw.Container(width: 1, color: _kBorderColor),
            _pdfHeaderCell('Semester', 124),
            pw.Container(width: 1, color: _kBorderColor),
            pw.Expanded(child: _pdfHeaderCell('Fee Type', null)),
            pw.Container(width: 1, color: _kBorderColor),
            _pdfHeaderCell('Amount', 119),
          ],
        ),
      ),
      // Data rows
      for (int i = 0; i < items.length; i++)
        _buildPdfDataRow(startIdx + i, items[i]),
      // Sub total (last page only)
      if (isLast)
        pw.Row(
          children: [
            pw.SizedBox(width: 172),
            pw.Expanded(
              child: pw.Container(
                decoration: const pw.BoxDecoration(
                  color: _kPrimaryBlue,
                  borderRadius: pw.BorderRadius.only(
                    bottomLeft: pw.Radius.circular(4),
                    bottomRight: pw.Radius.circular(4),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('Sub Total', textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    ),
                    pw.SizedBox(
                      width: 119,
                      child: pw.Text('\u20B9${_formatAmount(total)}', textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    ],
  );
}

pw.Widget _pdfHeaderCell(String text, double? width) {
  final child = pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    alignment: pw.Alignment.center,
    child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _kPrimaryBlue)),
  );
  return width != null ? pw.SizedBox(width: width, child: child) : child;
}

pw.Widget _buildPdfDataRow(int index, _ReceiptTerm term) {
  return pw.Container(
    constraints: const pw.BoxConstraints(minHeight: 36),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        left: pw.BorderSide(color: _kBorderColor, width: 1),
        right: pw.BorderSide(color: _kBorderColor, width: 1),
        bottom: pw.BorderSide(color: _kBorderColor, width: 1),
      ),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 46,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            alignment: pw.Alignment.topCenter,
            child: pw.Text('${index + 1}.', style: const pw.TextStyle(fontSize: 10, color: _kTextDark)),
          ),
        ),
        pw.Container(width: 1, color: _kBorderColor),
        pw.SizedBox(
          width: 124,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            alignment: pw.Alignment.topCenter,
            child: pw.Text(term.term, style: const pw.TextStyle(fontSize: 10, color: _kTextDark)),
          ),
        ),
        pw.Container(width: 1, color: _kBorderColor),
        pw.Expanded(
          child: pw.Column(
            children: [
              for (final fee in term.fees)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: pw.Text(fee.$1, textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 10, color: _kTextDark)),
                ),
            ],
          ),
        ),
        pw.Container(width: 1, color: _kBorderColor),
        pw.SizedBox(
          width: 119,
          child: pw.Column(
            children: [
              for (final fee in term.fees)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: pw.Text('\u20B9${_formatAmount(fee.$2)}', textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 10, color: _kTextDark)),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _pdfLabelValue(String label, String value) {
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _kTextDark)),
      pw.SizedBox(width: 6),
      pw.Text(value, style: const pw.TextStyle(fontSize: 10, color: _kTextMedium)),
    ],
  );
}

String _formatAmount(double amount) {
  if (amount == amount.truncateToDouble()) {
    return amount.toInt().toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
  return amount.toStringAsFixed(2).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
}
