# Krishnasamy Institution Mobile App

Flutter application for parent-facing school fee management. The app lets parents sign in with their registered mobile number, switch between linked students, review pending and paid fees, pay multiple fee groups in a single Razorpay transaction, and download or share receipts.

## What This Project Includes

- Parent sign-in, sign-up, OTP verification, and password reset flows
- Student selection for parents linked to multiple students
- Pending fee listing with filters and grouped views
- Cart-based payment flow that combines multiple fee items into one transaction
- Razorpay checkout integration backed by Supabase Edge Functions
- Payment history and receipt PDF generation
- Local notifications and fee reminders
- Supabase schema, SQL helpers, and database sync utilities

## Tech Stack

- Flutter
- Riverpod for state management
- GoRouter for navigation
- Supabase for data access and server-side functions
- Razorpay for fee payments
- `printing` and `pdf` for receipt generation
- `awesome_notifications` for scheduled reminders

## Repository Layout

```text
lib/
  app.dart                     App shell
  config/                      Routes, theme, Supabase, SMS config
  core/                        Constants, helpers, services, PDF utilities
  data/                        Models and dummy data
  presentation/                Screens, widgets, Riverpod providers

docs/
  Payment_Flow_Documentation.md

supabase/
  config.toml
  functions/
    create-razorpay-order/
    get-razorpay-payment/

db_sync/
  Full_sync.js                 Local PostgreSQL -> Supabase sync
  Reverse_sync.js              Supabase -> local sync
  *.sql                        RPCs, triggers, schema helpers
```

## Main Application Flow

1. Parent authenticates using the `parents` table and OTP/password flow.
2. Parent selects a linked student from `parentdetail`.
3. App loads pending fee demands from Supabase.
4. Parent adds one or more fee items to a cart.
5. App creates a shopping cart record, initiates a payment record, and requests a Razorpay order through a Supabase Edge Function.
6. After payment success, the app updates `payment`, `paymentdetails`, and `feedemand`, then clears the cart and shows the receipt flow.

For the full transaction lifecycle, see [docs/Payment_Flow_Documentation.md](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/docs/Payment_Flow_Documentation.md).

## Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or a configured Android device/emulator
- Supabase project
- Razorpay merchant account
- Optional: Supabase CLI
- Optional: Node.js for the `db_sync` tools

## Project Setup

### 1. Install dependencies

```bash
flutter pub get
```

If you plan to use the sync utilities:

```bash
cd db_sync
npm install
```

### 2. Configure Supabase client keys

Update [lib/config/supabase_config.dart](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/lib/config/supabase_config.dart):

- `url`
- `anonKey`

`serviceRoleKey` should remain server-side only.

### 3. Provision the database schema

This repository includes the SQL needed for tables, policies, RPCs, and helper functions. At minimum, review and apply:

- [supabase_create_tables.sql](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/supabase_create_tables.sql)
- [supabase_rls_policies.sql](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/supabase_rls_policies.sql)
- [db_sync/setup_pgcrypto.sql](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/db_sync/setup_pgcrypto.sql)
- [db_sync/setup_cart_rpc.sql](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/db_sync/setup_cart_rpc.sql)
- [db_sync/setup_payment_safety.sql](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/db_sync/setup_payment_safety.sql)
- [db_sync/setup_student_parent_triggers.sql](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/db_sync/setup_student_parent_triggers.sql)

These scripts support features such as:

- password verification RPCs
- cart restoration RPCs
- payment number generation
- double-payment protection
- parent-student relationship handling

### 4. Deploy Supabase Edge Functions

The payment flow depends on these functions:

- [supabase/functions/create-razorpay-order/index.ts](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/supabase/functions/create-razorpay-order/index.ts)
- [supabase/functions/get-razorpay-payment/index.ts](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/supabase/functions/get-razorpay-payment/index.ts)

Typical deployment commands:

```bash
supabase functions deploy create-razorpay-order
supabase functions deploy get-razorpay-payment
```

Set these function secrets in Supabase:

- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_URL`

### 5. Configure SMS / OTP delivery

The app currently has two SMS configuration paths:

- [lib/config/twilio_config.dart](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/lib/config/twilio_config.dart) via `--dart-define`
- [lib/config/sms_config.dart](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/lib/config/sms_config.dart) for BulkSMSGateway settings

Example Twilio run command:

```bash
flutter run ^
  --dart-define=TWILIO_ACCOUNT_SID=your_sid ^
  --dart-define=TWILIO_AUTH_TOKEN=your_token ^
  --dart-define=TWILIO_PHONE_NUMBER=your_number
```

### 6. Run the app

```bash
flutter run
```

Useful targets:

```bash
flutter run -d chrome
flutter run -d android
```

## Dummy Data Mode

For UI-only testing, set `useDummyData = true` in [lib/presentation/providers/student_provider.dart](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/lib/presentation/providers/student_provider.dart). This bypasses parts of the auth gating in routing and is intended only for development.

## Payment Notes

- Multiple fee groups are consolidated into one cart and one Razorpay payment.
- The app creates the Razorpay order server-side through Supabase Edge Functions.
- Receipt PDFs are generated in-app after successful payment.
- Web checkout support is wired through Razorpay's JS SDK in [web/index.html](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/web/index.html).

## Database Sync Utilities

The `db_sync` folder contains scripts for syncing between a local PostgreSQL database and Supabase.

Common commands:

```bash
cd db_sync
npm run sync
npm run sync:dry-run
```

Review [db_sync/package.json](/c:/Users/ADMIN/Desktop/Krishnaswamy%20Institution/Krishnasamy_institution_mobile_app/db_sync/package.json) and the SQL files in that folder before running sync jobs against production data.

## Useful Commands

```bash
flutter pub get
flutter test
flutter analyze
```

## Important Implementation Notes

- Authentication is implemented against custom `parents` table records, not standard Supabase Auth user accounts.
- Student linkage is resolved through the `parentdetail` table.
- Notification scheduling is initialized in `main.dart` for non-web builds.
- The codebase contains payment, SMS, and backend configuration points that should be reviewed before production release.

## Security Reminder

Before shipping this app, move all sensitive credentials out of source-controlled files and into secure environment or secret management. In particular, review SMS credentials and all payment-related keys.
