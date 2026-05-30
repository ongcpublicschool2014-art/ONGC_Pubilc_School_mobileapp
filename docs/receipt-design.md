# Fee Receipt — Design Specification

The fee receipt has **two implementations that must stay 1:1 identical**:

| | File | Purpose | Page size |
|---|---|---|---|
| On-screen preview | [`lib/widgets/receipt_widget.dart`](../lib/widgets/receipt_widget.dart) | Flutter `ReceiptWidget` shown in-app | **ISO B5** — 176 × 250 mm (499 × 709 pt) |
| Print / download | [`lib/utils/receipt_pdf.dart`](../lib/utils/receipt_pdf.dart) | `buildReceiptPdf` produces the PDF | **ISO A5** — 148 × 210 mm |

Both render the same Figma "Receipt" design. Shared call sites: **Daily Collection**, **Student Fee Collection**, and **Failed Transactions** — any layout change must be mirrored in both files so the preview and the print match.

---

## Page & framing

- **Widget (B5):** `499 × 709` pt, white background, `EdgeInsets.all(48)` outer padding.
- **PDF (A5):** `a5PageFormat` (148×210 mm), `EdgeInsets.all(24)` margin. A5 is passed explicitly to every `Printing.layoutPdf` call — otherwise the dialog defaults to the printer's loaded paper (usually A4) and the right-edge unprintable margin clips the amount column.
- The bordered table in the PDF is centered at a **fixed 350 pt width** so it sits inside the ~371 pt content area with a small inset each side. (The widget version lets the table fill width via `Expanded`.)

## Vertical structure (top → bottom)

1. **Header** (height 100 / 82 pt)
2. `SizedBox(height: 10)`
3. **"RECEIPT"** — centered, bold, 9 pt
4. `SizedBox(height: 8)`
5. **Bordered receipt table** (1 pt black border, 4 pt corner radius):
   1. Info row — student details ⏐ receipt details
   2. Section header — `PARTICULARS` ⏐ `AMOUNTS (Rs)`
   3. Particulars (fee lines) — fills remaining height
   4. Total row
   5. Footer — amount in words + cashier signature

---

## Header

Chosen by institution name via `receiptHeaderImage(schoolName)`:

| Name contains | Banner asset |
|---|---|
| `engineering` | `assets/images/kcet.png` |
| `polytechnic` | `assets/images/kmptc.jpg` |
| `science` / `arts` / `management` / `women` | `assets/images/kcsam.jpg` |
| (none) | **fallback:** institution logo + name/address text |

- **Banner header** — two-grid row: `flex 4` crest (`KMPTC Logo.jpg`, 88 pt tall) ⏐ `flex 1` gap ⏐ `flex 15` banner (contain-fit).
- **Fallback header** — optional 70×70 network logo + column of `schoolName` (800 weight) and `schoolAddress` (500 weight, max 2 lines).

---

## Receipt table

### Info row (two equal cells, divided by a 1 pt vertical rule)

| Left cell | Right cell |
|---|---|
| `Name : <studentName>` | `Receipt No : <receiptNo>` |
| `Reg. No : <admissionNo>` | `Date : <date>` |
| `Branch : <className>` | `Sem : FEE (UP TO DATE)` |
| `Mode : <paymentMethod>` | `Txn ID : <paymentReference>` |

- Each line is a `key : value` pair (`_kv`) — label at weight 600, value at 400. Empty values render as `-`.
- Cell padding: `horizontal 12, vertical 10`; 8 pt gap between lines.

### Section header
`PARTICULARS` (centered, bold) ⏐ `AMOUNTS (Rs)` (right-aligned, bold). Amount column fixed at **120 pt**.

### Particulars
Flattened fee lines from `flattenParticulars(data)` — each term's fees become numbered rows: `1. <feeType>` … with the matching amount right-aligned in the 120 pt column. 6 pt gap between rows. Amounts via `formatReceiptAmount` (two decimals + thousands separators, e.g. `5,000.00`).

### Total row
`TOTAL` (right-aligned, bold) ⏐ grand total `formatReceiptAmount(data.total)` (bold).

### Footer (height ~110 / 78 pt)
- **Amount in words** — `amountInWords(total)` → e.g. `Rupees Five Thousand Only` (Indian crore/lakh/thousand system, rounded to whole rupees).
- **`* Subject to Realization`** — printed in orange `#B85C00`, weight 600, **only when `reconStatus != 'R'`** (cheque/UPI/bank entry not yet reconciled). Signals the receipt isn't a settled-cash equivalent.
- **`Cashier`** — bold, right-aligned signature line (34 pt right inset).

---

## Typography & color

- **Font:** Inter (`GoogleFonts.inter` / `PdfGoogleFonts.inter*`).
- **Base size:** **9 pt** throughout.
- **Weights:** body 400, key labels / address-detail 500–600, headings & totals 700, fallback school name 800.
- **Color:** pure black `#000000` on white; the only accent is the orange realization note `#B85C00`.
- **Rules/borders:** 1 pt solid black — outer table border (4 pt radius), the vertical cell divider, and a top border separating each table section.

---

## Data model — `ReceiptData`

```
ReceiptData
 ├─ receiptNo, date
 ├─ studentName, mobileNo, address, admissionNo, className, courseName
 ├─ schoolName, schoolAddress, schoolLogoUrl?, schoolMobile?, schoolEmail?
 ├─ feeDetails : List<ReceiptTermDetail>      // term → List<ReceiptFeeItem>(type, amount)
 ├─ paymentMethod, paymentDate
 ├─ status        : 'paid' | 'pending'
 ├─ reconStatus   : 'P' (pending recon) | 'R' (reconciled)   // drives "Subject to Realization"
 ├─ paymentReference?                          // gateway txn id / UTR (Txn ID field)
 └─ total : double
```

### Helper functions (in `receipt_widget.dart`)
- `flattenParticulars(data)` — term-grouped fees → flat numbered list.
- `receiptHeaderImage(schoolName)` — picks the banner asset (see table above).
- `receiptSemesterLabel(data)` — distinct non-empty terms joined with `, `.
- `formatReceiptAmount(amount)` — `5000 → "5,000.00"`.
- `amountInWords(amount)` — Indian-system rupees-in-words.
- `ReceiptWidget.isOnlineMethod(method)` / `formatReference(raw)` — kept for backward compatibility with existing call sites.

---

## Editing notes

- **Change the widget and the PDF together.** They are deliberate duplicates; a test (`receipt widget multi-term`) guards the multi-term header.
- The PDF uses **fixed section heights** (info 90, header 30, particulars 150, total 32, footer 78) instead of `Expanded`, because the PDF layout engine renders fixed-height rows reliably; the widget uses `Expanded` for the particulars area.
- Keep all text at 9 pt — the layout (especially the 120 pt amount column and 350 pt table width) is tuned around that size.
