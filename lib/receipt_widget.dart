import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class ReceiptData {
  final String receiptNo;
  final String date;
  final String studentName;
  final String mobileNo;
  final String address;
  final String admissionNo;
  final String className;
  final String courseName;
  final String schoolName;
  final String schoolAddress;
  final String? schoolLogoUrl;
  final String? schoolMobile;
  final String? schoolEmail;
  final List<ReceiptTermDetail> feeDetails;
  final String paymentMethod;
  final String paymentDate;
  final String status; // 'paid' | 'pending' | 'failed'
  final String reconStatus; // 'P' = pending recon, 'R' = reconciled
  final String? paymentReference; // gateway txn id / UTR
  final double total;

  const ReceiptData({
    required this.receiptNo,
    required this.date,
    required this.studentName,
    required this.mobileNo,
    required this.address,
    required this.admissionNo,
    required this.className,
    this.courseName = '-',
    required this.schoolName,
    required this.schoolAddress,
    this.schoolLogoUrl,
    this.schoolMobile,
    this.schoolEmail,
    required this.feeDetails,
    required this.paymentMethod,
    required this.paymentDate,
    required this.status,
    this.reconStatus = 'P',
    this.paymentReference,
    required this.total,
  });
}

class ReceiptTermDetail {
  final String term;
  final List<ReceiptFeeItem> fees;
  const ReceiptTermDetail({required this.term, required this.fees});
}

class ReceiptFeeItem {
  final String type;
  final double amount;
  const ReceiptFeeItem({required this.type, required this.amount});
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers (shared with PDF generator)
// ─────────────────────────────────────────────────────────────────────────────

class ReceiptParticular {
  final String type;
  final double amount;
  const ReceiptParticular(this.type, this.amount);
}

/// Flatten term-grouped fees into a single numbered list for the receipt body.
List<ReceiptParticular> flattenParticulars(ReceiptData data) {
  final out = <ReceiptParticular>[];
  for (final term in data.feeDetails) {
    for (final f in term.fees) {
      out.add(ReceiptParticular(f.type, f.amount));
    }
  }
  return out;
}

/// Pick a banner asset based on the school name. Returns null when no
/// keyword matches and the fallback (logo + text) should be used.
String? receiptHeaderImage(String schoolName) {
  final n = schoolName.toLowerCase();
  if (n.contains('engineering')) return 'assets/images/kcet.png';
  if (n.contains('polytechnic')) return 'assets/images/kmptc.jpg';
  if (n.contains('science') ||
      n.contains('arts') ||
      n.contains('management') ||
      n.contains('women')) {
    return 'assets/images/kcsam.jpg';
  }
  return null;
}

/// Distinct non-empty term labels joined with ", ". Falls back to
/// "FEE (UP TO DATE)" if no real term info is present.
String receiptSemesterLabel(ReceiptData data) {
  final seen = <String>{};
  final terms = <String>[];
  for (final t in data.feeDetails) {
    final v = t.term.trim();
    if (v.isEmpty) continue;
    if (seen.add(v)) terms.add(v);
  }
  if (terms.isEmpty) return 'FEE (UP TO DATE)';
  return terms.join(', ');
}

/// Indian-style amount: 5000 → "5,000.00".
String formatReceiptAmount(double amount) {
  final whole = amount.truncate();
  final frac = ((amount - whole) * 100).round().abs();
  final wholeStr = _indianGroup(whole.abs());
  final sign = amount < 0 ? '-' : '';
  return '$sign$wholeStr.${frac.toString().padLeft(2, '0')}';
}

String _indianGroup(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  while (rest.length > 2) {
    buf.write(',');
    buf.write(rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  final pieces = [rest, buf.toString().split(',').where((e) => e.isNotEmpty).toList().reversed.join(','), last3]
      .where((e) => e.isNotEmpty)
      .toList();
  return pieces.join(',');
}

/// Indian-system rupees-in-words. Rounded to whole rupees.
/// e.g. 5000 → "Rupees Five Thousand Only"
String amountInWords(double amount) {
  final rupees = amount.round();
  if (rupees == 0) return 'Rupees Zero Only';
  final words = _numberToIndianWords(rupees);
  return 'Rupees $words Only';
}

const _ones = [
  '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
  'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
  'Seventeen', 'Eighteen', 'Nineteen'
];
const _tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

String _twoDigits(int n) {
  if (n < 20) return _ones[n];
  final t = n ~/ 10;
  final r = n % 10;
  return r == 0 ? _tens[t] : '${_tens[t]} ${_ones[r]}';
}

String _threeDigits(int n) {
  final h = n ~/ 100;
  final r = n % 100;
  if (h == 0) return _twoDigits(r);
  if (r == 0) return '${_ones[h]} Hundred';
  return '${_ones[h]} Hundred ${_twoDigits(r)}';
}

String _numberToIndianWords(int n) {
  if (n < 0) return '-${_numberToIndianWords(-n)}';
  if (n == 0) return 'Zero';
  final parts = <String>[];
  final crore = n ~/ 10000000;
  n %= 10000000;
  final lakh = n ~/ 100000;
  n %= 100000;
  final thousand = n ~/ 1000;
  n %= 1000;
  if (crore > 0) parts.add('${_twoDigits(crore)} Crore');
  if (lakh > 0) parts.add('${_twoDigits(lakh)} Lakh');
  if (thousand > 0) parts.add('${_twoDigits(thousand)} Thousand');
  if (n > 0) parts.add(_threeDigits(n));
  return parts.join(' ');
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

/// On-screen fee receipt — ISO B5 (176 × 250 mm = 499 × 709 pt).
/// Must stay 1:1 identical with the PDF in lib/core/utils/receipt_pdf_generator.dart.
class ReceiptWidget extends StatelessWidget {
  final ReceiptData data;
  const ReceiptWidget({super.key, required this.data});

  // Backward-compatible helpers kept for existing call sites.
  static bool isOnlineMethod(String method) {
    final m = method.toLowerCase();
    return m.contains('razorpay') ||
        m.contains('online') ||
        m.contains('upi') ||
        m.contains('netbank') ||
        m.contains('card');
  }

  static String formatReference(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    return raw.trim();
  }

  static const _font = 'Inter';
  static const _black = Color(0xFF000000);
  static const _realizationOrange = Color(0xFFB85C00);
  static const _border = BorderSide(color: _black, width: 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 499,
      height: 709,
      color: Colors.white,
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'RECEIPT',
              style: TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w700, color: _black),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final banner = receiptHeaderImage(data.schoolName);
    if (banner != null) {
      return SizedBox(height: 100, child: _bannerHeader(banner));
    }
    return SizedBox(height: 120, child: _fallbackHeader());
  }

  Widget _bannerHeader(String bannerAsset) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Image.asset(
            'assets/images/KMPTC Logo.jpg',
            height: 88,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        const Expanded(flex: 1, child: SizedBox.shrink()),
        Expanded(
          flex: 15,
          child: Image.asset(
            bannerAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _fallbackHeader() {
    final hasLogo = (data.schoolLogoUrl ?? '').trim().isNotEmpty;
    // Logo on the left, school name + address rendered banner-style — large
    // centered title and centered address filling the rest of the header width.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasLogo) ...[
          SizedBox(
            width: 110,
            height: 110,
            child: Image.network(
              data.schoolLogoUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.schoolName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _black,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.schoolAddress,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w500, color: _black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Table ───────────────────────────────────────────────────────────────
  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoRow(),
          _topBorder(child: _buildSectionHeader()),
          Expanded(child: _topBorder(child: _buildParticulars())),
          _topBorder(child: _buildTotalRow()),
          _topBorder(child: _buildFooter()),
        ],
      ),
    );
  }

  Widget _topBorder({required Widget child}) {
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(top: _border)),
      child: child,
    );
  }

  Widget _buildInfoRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _infoCell(left: true)),
          const DecoratedBox(
            decoration: BoxDecoration(border: Border(left: _border)),
            child: SizedBox(width: 0),
          ),
          Expanded(child: _infoCell(left: false)),
        ],
      ),
    );
  }

  Widget _infoCell({required bool left}) {
    final lines = left
        ? [
            _kv('Name', data.studentName),
            _kv('Reg. No', data.admissionNo),
            _kv('Branch', data.className),
            _kv('Mode', data.paymentMethod),
          ]
        : [
            _kv('Receipt No', data.receiptNo),
            _kv('Date', data.date),
            _kv('Sem', receiptSemesterLabel(data)),
            _kv('Txn ID', formatReference(data.paymentReference)),
          ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            lines[i],
          ],
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    final v = (value.trim().isEmpty) ? '-' : value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label : ',
          style: const TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w600, color: _black),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w400, color: _black),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Two-cell row layout shared by section header, particulars, and total —
  /// gives a continuous vertical 1pt divider between PARTICULARS and AMOUNTS.
  Widget _twoCellRow({
    required Widget left,
    required Widget right,
    required EdgeInsetsGeometry leftPadding,
    required EdgeInsetsGeometry rightPadding,
    bool intrinsicHeight = true,
  }) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: Padding(padding: leftPadding, child: left)),
        const DecoratedBox(
          decoration: BoxDecoration(border: Border(left: _border)),
          child: SizedBox(width: 0),
        ),
        SizedBox(width: 120, child: Padding(padding: rightPadding, child: right)),
      ],
    );
    return intrinsicHeight ? IntrinsicHeight(child: row) : row;
  }

  Widget _buildSectionHeader() {
    return _twoCellRow(
      leftPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      rightPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      left: const Center(
        child: Text(
          'PARTICULARS',
          style: TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w700, color: _black),
        ),
      ),
      right: const Align(
        alignment: Alignment.centerRight,
        child: Text(
          'AMOUNTS (Rs)',
          style: TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w700, color: _black),
        ),
      ),
    );
  }

  Widget _buildParticulars() {
    final items = flattenParticulars(data);
    return _twoCellRow(
      intrinsicHeight: false, // particulars area fills the Expanded vertical space
      leftPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      rightPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      left: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Text(
              '${i + 1}. ${items[i].type}',
              style: const TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w400, color: _black),
            ),
          ],
        ],
      ),
      right: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatReceiptAmount(items[i].amount),
                style: const TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w400, color: _black),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    return _twoCellRow(
      leftPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      rightPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      left: const Align(
        alignment: Alignment.centerRight,
        child: Text(
          'TOTAL',
          style: TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w700, color: _black),
        ),
      ),
      right: Align(
        alignment: Alignment.centerRight,
        child: Text(
          formatReceiptAmount(data.total),
          style: const TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w700, color: _black),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final showRealization = data.reconStatus != 'R';
    return SizedBox(
      height: 110,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 34, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              amountInWords(data.total),
              style: const TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w600, color: _black),
            ),
            if (showRealization) ...[
              const SizedBox(height: 6),
              const Text(
                '* Subject to Realization',
                style: TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w600, color: _realizationOrange),
              ),
            ],
            const Spacer(),
            const Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Cashier',
                style: TextStyle(fontFamily: _font, fontSize: 9, fontWeight: FontWeight.w700, color: _black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
