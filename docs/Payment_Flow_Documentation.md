# Krishnasamy Institution Fees App - Payment Gateway Flow Documentation

## Overview

This document describes the complete payment flow from fee selection to receipt generation. The app supports selecting **multiple fee groups** (School Fees, Van Fees, Tuition Fees, etc.) and consolidating them into a **single payment transaction** with **one receipt**.

---

## Payment Flow Summary

```
HOME SCREEN
    |
    |-- "Pay All Fees" --> PAY ALL FEES SCREEN (auto-selects all pending fees)
    |-- Fee Category Card --> ALL PENDING FEES SCREEN (filtered by group)
    |
    v
CART SCREEN (all selected fees combined)
    |
    v
PAYMENT PROCESSING (4-step process)
    |
    |-- Step 1: Save cart to database
    |-- Step 2: Create payment record (status: Initiated)
    |-- Step 3: Create Razorpay order via Edge Function
    |-- Step 4: Open Razorpay checkout
    |
    +-------+-------+
    |               |
 SUCCESS          FAILURE
    |               |
    v               v
Update fees &    Keep cart for
payment record   retry attempt
    |
    v
PAYMENT HISTORY SCREEN
    |
    v
TRANSACTION DETAILS SCREEN (Receipt View)
    |
    +-------+-------+
    |               |
 DOWNLOAD         SHARE
 (PDF)            (PDF via share_plus)
```

---

## Screen-by-Screen Flow

### Screen 1: Home Screen

**File:** `lib/presentation/screens/home/home_screen.dart`

The home screen is the starting point. Parents see:
- **Total pending fees** summary with academic year label
- **"Pay All Fees" button** - navigates to Pay All Fees screen
- **Fee category cards** (School Fees, Van Fees, Exam Fees, Other) - each navigates to All Pending Fees screen filtered by that group
- **Overdue/Due Soon cards** - navigate with status filters

**User Actions:**
| Action | Navigation |
|--------|-----------|
| Tap "Pay All Fees" | `/pay-all-fees` |
| Tap fee category card | `/all-pending-fees?group={groupName}` |
| Tap overdue card | `/all-pending-fees?group={name}&status=overdue` |

---

### Screen 2: Pay All Fees Screen

**File:** `lib/presentation/screens/fees/pay_all_fees_screen.dart`

Displays all pending fees with **auto-selection** - every pending fee is pre-selected into the cart on load.

**Features:**
- Fee group dropdown filter (All Fees, Term Fees, Tuition, Hostel, Bus, Extra)
- Individual fee toggle (select/deselect)
- Group-level select all
- Running total of selected fees
- "View Cart" button at bottom

**Fee Categorization Logic:**
```
Bus/Van Fees    --> fee name contains 'bus', 'transport', 'van'
Tuition Fees    --> fee name contains 'tuition'
Hostel Fees     --> fee name contains 'hostel'
Extra Fees      --> fee name contains 'extra', 'misc', 'other', 'activity', 'event'
Term Fees       --> everything else (grouped by term: I TERM, II TERM, etc.)
```

---

### Screen 3: All Pending Fees Screen

**File:** `lib/presentation/screens/fees/all_pending_fees_screen.dart`

Detailed fee listing with multi-select capability. Can be filtered by group or status.

**Display Structure:**
- Fees organized by category (Term-wise, Month-wise)
- Sub-filter tabs (terms for school fees, months for van/tuition)
- Each fee shows: name, due date, balance amount, overdue badge
- Select all per group or individual selection
- Bottom bar: selected count, total amount, "View Cart" button

**Example View:**
```
+------------------------------------------+
| I TERM - 2024-2025                       |
|   [ ] School Fee         Due: 15/06  5000|
|   [ ] Lab Fee            Due: 15/06  1000|
|       Term Total:                    6000 |
+------------------------------------------+
| VAN FEES - January                       |
|   [ ] Van Fee            Due: 05/01  1500|
+------------------------------------------+
| Selected: 3 fees    Total: Rs.7,500      |
| [=============== View Cart ==============]|
+------------------------------------------+
```

---

### Screen 4: Cart Screen

**File:** `lib/presentation/screens/cart/cart_screen.dart`

Aggregates all selected fees from multiple groups into one cart.

**Display:**
- Fees grouped by category with color-coded badges:
  - Bus Fees (orange)
  - Tuition Fees (purple)
  - Hostel Fees (blue)
  - Term Fees (green, grouped by term)
- Table format per group: Fee Name | Amount
- Remove entire group option
- Grand total at bottom
- **"Pay Now"** button triggers payment

**Example Cart:**
```
+------------------------------------------+
| BUS FEES                          Orange  |
|   Van Fee - January              Rs.1,500 |
|   Van Fee - February             Rs.1,500 |
|   Subtotal:                      Rs.3,000 |
+------------------------------------------+
| TERM FEES - I TERM                Green   |
|   School Fee                     Rs.5,000 |
|   Lab Fee                        Rs.1,000 |
|   Subtotal:                      Rs.6,000 |
+------------------------------------------+
|                                           |
|   Grand Total:              Rs.9,000      |
| [=============== Pay Now ================]|
+------------------------------------------+
```

**Key Point:** All fees from different groups/accounts are combined into ONE cart with ONE total amount.

---

## Payment Processing (4 Steps)

When user taps **"Pay Now"**, the following 4-step process executes:

### Step 1: Save Cart to Database

**Function:** `saveCartToDatabase()` in `payment_provider.dart`

```
Input:  List of selected fees + Student ID
Output: carId (shopping cart ID)

Process:
  1. Check for existing active cart for this student
  2. Clean up stale initiated carts from failed payments
  3. Create/update shoppingcart record:
     - yr_id, yrlabel, transdate
     - transtotalamount (sum of all fees)
     - carinitiated: 'N' (not yet initiated)
  4. Insert shoppingcartdetails (one row per fee):
     - dem_id (fee demand ID)
     - transtotalamount (individual fee amount)
```

**Database Records:**
```
shoppingcart (1 record):
  car_id: 100
  stu_id: 1001
  transtotalamount: 9000
  carinitiated: 'N'

shoppingcartdetails (4 records):
  car_id: 100, dem_id: 1, amount: 5000  (School Fee - I Term)
  car_id: 100, dem_id: 2, amount: 1000  (Lab Fee - I Term)
  car_id: 100, dem_id: 3, amount: 1500  (Van Fee - Jan)
  car_id: 100, dem_id: 4, amount: 1500  (Van Fee - Feb)
```

---

### Step 2: Create Payment Record

**Function:** `initiatePayment()` in `payment_provider.dart`

```
Input:  carId, cart items, cart total
Output: payId (payment ID)

Process:
  1. Double-payment prevention:
     - Re-fetch fee balances from DB
     - Remove any fees already paid since cart was created
     - Recalculate total if fees were removed
  2. Generate payment number from sequence table:
     - Format: "FC25/00044" (prefix + incrementing number)
  3. Create payment record:
     - paystatus: 'I' (Initiated)
     - paynumber: "FC25/00044"
     - transtotalamount: 9000
     - paymethod: '' (empty, set on success)
     - payreference: '' (empty, set to Razorpay ID on success)
  4. Create paymentdetails (one row per fee):
     - pay_id, dem_id, transtotalamount
  5. Update shoppingcart: carinitiated = 'I'
  6. Increment sequence counter
```

**Payment Status Values:**
| Status | Meaning |
|--------|---------|
| `I` | Initiated (payment in progress) |
| `C` | Complete (payment successful) |
| `F` | Failed (payment failed/cancelled) |
| `R` | Refunded |

---

### Step 3: Create Razorpay Order

**Function:** `createRazorpayOrder()` in `payment_provider.dart`

```
Input:  payId, amount in paise, receipt number
Output: orderId (Razorpay order ID)

Process:
  1. Call Supabase Edge Function: 'create-razorpay-order'
  2. Edge Function calls Razorpay Orders API:
     POST https://api.razorpay.com/v1/orders
     {
       "amount": 900000,           // Rs.9000 in paise
       "currency": "INR",
       "receipt": "PAY-50",
       "payment_capture": 1        // Auto-capture on success
     }
  3. Store order_id in payment table (payorderid column)
  4. Return order_id to app
```

**Why Edge Function?**
- Razorpay secret key must never be in the mobile app
- Edge Function securely holds API credentials
- Server-side order creation prevents amount tampering

---

### Step 4: Open Razorpay Checkout

**Code:** `cart_screen.dart` - `_handleProceedToPayment()`

```dart
_razorpay.open({
  'key': 'rzp_test_RQsgJgVFwM7kov',    // Public key (safe for client)
  'amount': 900000,                      // Amount in paise
  'currency': 'INR',
  'name': 'Krishnasamy Institution',
  'description': 'School Fees Payment',
  'order_id': orderId,                   // From Step 3
  'prefill': {
    'name': 'Student Name',
    'contact': '9876543210',
    'email': 'parent@email.com'
  },
  'theme': { 'color': '#1A73E8' },
  'notes': {
    'pay_id': '50',
    'car_id': '100',
    'student_id': '1001'
  }
});
```

Razorpay opens its native checkout UI. Parent can pay via:
- UPI
- Credit/Debit Card
- Net Banking
- Wallet

---

## After Payment

### On Success

**Function:** `handlePaymentSuccess()` in `payment_provider.dart`

```
Process:
  1. Update payment record:
     - paystatus: 'C' (Complete)
     - paymethod: 'razorpay'
     - payreference: razorpay_payment_id
     - paydate: current timestamp

  2. Update each fee (feedemand) in the payment:
     - paidamount: paidamount + balancedue
     - balancedue: 0 (or remaining if partial)
     - paidstatus: 'P' (Paid)
     - pay_id: link to payment record

  3. Cleanup:
     - Delete all shopping carts for this student
     - Clear in-memory cart

  4. Refresh data:
     - Reload fees provider (shows updated balances)
     - Reload payments provider (shows in history)
     - Reload notifications
```

**Navigation:** Redirects to Payment History screen

---

### On Failure

**Function:** `handlePaymentFailure()` in `payment_provider.dart`

```
Process:
  1. Update payment record:
     - paystatus: 'F' (Failed)
     - paydate: current timestamp

  2. Reset shopping cart:
     - carinitiated: 'N' (back to not initiated)
     - Cart data preserved for retry

  3. Show error message to user
```

**User can retry:** Cart remains intact, user taps "Pay Now" again.

---

## Receipt & Transaction Details

### Transaction Details Screen

**File:** `lib/presentation/screens/payments/transaction_details_screen.dart`
**Route:** `/transaction/:paymentId`

Displays:
```
+------------------------------------------+
|        PAYMENT SUCCESSFUL                |
|        Transaction Completed             |
+------------------------------------------+
|           Amount Paid                     |
|           Rs. 9,000                       |
+------------------------------------------+
| Payment No      |        FC25/00044      |
| Student         |        KAMESH L        |
| Class           |        VI              |
| Admission No    |        5451            |
| Transaction ID  |  pay_SFztLKiQBcIrhs   |
| Payment Method  |        razorpay        |
| Date & Time     |  14 Feb 2026 . 4:15pm  |
+------------------------------------------+
| [  Download  ]     [    Share    ]        |
+------------------------------------------+
```

### Receipt PDF Generation

**File:** `lib/core/utils/receipt_pdf_generator.dart`

Generates a PDF receipt containing:
- School name & address (from institution data)
- Payment status badge (Completed/Failed)
- Payment details: number, date, method, transaction ID
- Student details: name, class, admission number, year
- Total amount (Indian number format)
- "Computer-generated receipt" disclaimer

**Actions:**
- **Download:** Opens system print/save dialog via `printing` package
- **Share:** Saves PDF to temp file, opens Android/iOS share sheet via `share_plus`

---

## Database Schema

### Tables Involved in Payment Flow

```
STUDENT (stu_id)
    |
    +---> FEEDEMAND (dem_id, stu_id)
    |         |
    |         +---> SHOPPINGCARTDETAILS (car_id, dem_id)
    |         |         |
    |         |         +---> SHOPPINGCART (car_id, stu_id)
    |         |
    |         +---> PAYMENTDETAILS (pay_id, dem_id)
    |                   |
    |                   +---> PAYMENT (pay_id, stu_id)
    |
    +---> SEQUENCE (for payment number generation)
```

### Key Fields

**feedemand (Fee Demand):**
| Field | Description |
|-------|-------------|
| dem_id | Primary key |
| stu_id | Student reference |
| demfeetype | Fee type ID (links to fee group) |
| feeamount | Original fee amount |
| conamount | Concession amount |
| paidamount | Amount paid so far |
| balancedue | Remaining balance |
| paidstatus | 'P' = Paid, 'U' = Unpaid |
| pay_id | Links to payment (set on success) |

**payment:**
| Field | Description |
|-------|-------------|
| pay_id | Primary key |
| stu_id | Student reference |
| paynumber | Receipt number (FC25/00044) |
| paystatus | I/C/F/R (Initiated/Complete/Failed/Refunded) |
| paymethod | 'razorpay' |
| payreference | Razorpay payment ID |
| payorderid | Razorpay order ID |
| transtotalamount | Total amount paid |
| paydate | Payment timestamp |

**paymentdetails:**
| Field | Description |
|-------|-------------|
| pay_id | Payment reference |
| dem_id | Fee demand reference |
| transtotalamount | Individual fee amount |

---

## Multi-Group Single Receipt Example

### Scenario
Parent selects fees from **3 different groups** for one child:

| Fee | Group | Amount |
|-----|-------|--------|
| School Fee - I Term | School Fees | Rs.5,000 |
| Lab Fee - I Term | School Fees | Rs.1,000 |
| Van Fee - January | Van Fees | Rs.1,500 |
| Tuition Fee - January | Tuition Fees | Rs.2,000 |
| **Total** | | **Rs.9,500** |

### What Happens in Database

**1 Shopping Cart:**
```
shoppingcart: car_id=100, stu_id=1001, total=9500, carinitiated='I'
```

**4 Cart Details:**
```
shoppingcartdetails: car_id=100, dem_id=1, amount=5000
shoppingcartdetails: car_id=100, dem_id=2, amount=1000
shoppingcartdetails: car_id=100, dem_id=3, amount=1500
shoppingcartdetails: car_id=100, dem_id=4, amount=2000
```

**1 Payment (single transaction):**
```
payment: pay_id=50, paynumber='FC25/00044', total=9500, status='C'
```

**4 Payment Details:**
```
paymentdetails: pay_id=50, dem_id=1, amount=5000
paymentdetails: pay_id=50, dem_id=2, amount=1000
paymentdetails: pay_id=50, dem_id=3, amount=1500
paymentdetails: pay_id=50, dem_id=4, amount=2000
```

**1 Razorpay Transaction:**
```
Order: order_JnEq2cXyz12345, amount=950000 paise, status=paid
Payment: pay_SFztLKiQBcIrhs
```

**1 Receipt:** FC25/00044 - Total Rs.9,500

### Result
- Parent pays **once** through Razorpay
- Gets **one receipt** (FC25/00044)
- All 4 fees marked as **Paid** in feedemand table
- All 4 fees linked to **same pay_id** (50)

---

## Safety & Error Handling

| Scenario | How It's Handled |
|----------|-----------------|
| Double payment prevention | Fresh DB check before initiating payment; removes already-paid fees |
| Payment abandoned mid-way | Cart restored on app restart from DB; initiated payments reset |
| App crash during payment | Razorpay webhook/order status can be verified server-side |
| Fee paid by another device | Balance re-checked before payment; cart auto-corrected |
| Network failure | Cart persisted in DB; user can retry anytime |
| Student switch | Cart cleared from memory; restored from DB when switching back |

---

## Current Limitation: Single Razorpay Account

Currently, **all fees go through one Razorpay account** regardless of fee group. The money settles into a single bank account.

### For Split Payments to Multiple Accounts (Future)

If school fees and van fees need to go to **different bank accounts**, use **Razorpay Route (Transfer API)**:

1. Parent pays full amount to primary Razorpay account
2. After success, use Transfers API to split:
   - Rs.6,000 to School's bank account
   - Rs.3,500 to Van Provider's bank account
3. Parent still gets one receipt
4. Money auto-routes to respective accounts

**Requirement:** Enable Razorpay Route on your merchant account.

---

*Document generated: February 2026*
*App Version: 1.0.0*
