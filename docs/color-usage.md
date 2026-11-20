# Color Usage — by screen and component

A practical map of which colors paint which UI element across the app. For the underlying palette and meaning of each token, see [`colors.md`](colors.md).

**Color shorthand:**
- **Navy** = `AppColors.primary` = `#002147`
- **Amber** = `AppColors.secondary` / `accent` / `buttonPrimary` = `#D2913C`
- **Amber-dark** = `AppColors.buttonPrimaryHover` / `textLink` = `#B5752A`
- **Brand gradient** = `AppColors.brandGradient` = `#3A5A8C → #002147 → #00132E` diagonal
- Brightness-aware helpers (`scaffoldBg(context)` etc.) shown as **`scaffoldBg`**

---

## Splash & Onboarding

### `splash_screen.dart`
| Element | Color |
|---|---|
| Page background | white / `surface` |
| Decorative orbs (large faint circles) | `AppColors.primary.withValues(alpha: 0.05)` (navy 5%) |
| Loading dots | navy |
| "SchoolPay" title | dark text |
| "Secure & Easy Fee Payments" pill | green success bg + green icon |

### `onboarding_screen.dart`
| Element | Color |
|---|---|
| Page background | white |
| Illustration card | `#E8F4FD` (light blue) |
| Title text | dark `#1A1A1A` |
| Subtitle text | `#6B6B6B` (dim gray, bumped from `#9E9E9E`) |
| Active page-indicator dot | navy `AppColors.primary` |
| Inactive dots | `gray300` / `borderC` |
| **Next button** | amber `#D2913C` filled, white text |
| **Skip** link | text link `#B5752A` |

### `welcome_screen.dart`
| Element | Color |
|---|---|
| Page background | white |
| Card border | navy `AppColors.primary` (desktop) / `#E8E7E4` (mobile) |
| Card icons | navy on desktop / `#1A1A1A` on mobile |
| Subtitle text | `#6B6B6B` |
| **Sign In** button | amber `#D2913C` filled, white text + amber glow under |
| **Create Account** button | white card, amber border, amber icon + label |

---

## Auth (sign in / sign up / OTP / forgot / set password)

Common style across all auth screens.

| Element | Color |
|---|---|
| Scaffold | `scaffoldBg` (`#F1F5F9` light) |
| Card surface | `cardBg` (white light) |
| Heading text | `textPrimaryC` (`#1F2937`) |
| Helper / hint text | `textSecondaryC` (`#6B7280`), `textHintC` (`#9CA3AF`) |
| Input border | `borderC` (`#E5E7EB`) |
| Input focus border | `#007DFC` (blue) on auth-screen text inputs / amber on OTP boxes |
| Input error border | `#EF4444` |
| **Get OTP / Sign In / Submit / Continue button** | amber `#D2913C` filled, white text, soft amber glow (`primary` 40%) |
| **Forgot Password ?** link | navy `AppColors.primary` (text link in row) |
| **Sign up / Sign In switch link** | navy `AppColors.primary` (since palette swap) |
| OTP cell — empty | `cardBg`, border `borderC` |
| OTP cell — focused | border navy `AppColors.primary` (2px) |
| OTP cell — filled | bg `cardPurple` `#F0EEFF`, border navy |
| OTP error banner | bg `error 10%`, border `error 30%`, text/icon `error` |
| Snackbar — success | `AppColors.success` `#10B981` |
| Snackbar — error | `AppColors.error` `#EF4444` |
| Country picker — flag emojis | OS emoji font (🇮🇳 🇦🇪 🇸🇦 🇸🇬 🇦🇺 🇺🇸 🇬🇧) |
| Country picker — country code | dark text |

---

## Main scaffold (mobile shell + desktop sidebar)

### Mobile header
| Element | Color |
|---|---|
| Header container | white with subtle drop shadow `0x0A000000` |
| **Small student-chip avatar** (sidebar) | amber tint (`secondary.withValues(alpha: 0.15)`), initials in amber |
| Settings icon circle | navy `AppColors.primary`, white icon |

### Bottom navigation
| Element | Color |
|---|---|
| Bar background | white |
| Selected tab icon/label | dark `#1A1A1A` |
| Unselected | `gray400` |
| Active tab indicator | (currently solid dark — could be moved to navy/amber for brand match) |

### Desktop sidebar
| Element | Color |
|---|---|
| Sidebar bg | white / `cardBg` |
| Logo title | navy `AppColors.primary` |
| Selected nav item | amber tint bg, amber icon + label |
| Search input — focused border | `primary` 50% |
| Search input — focused glow | `primary` 12% |

---

## Home screen

| Element | Color |
|---|---|
| Page background | `scaffoldBg` (`#F1F5F9`) |
| Header card | white with `0x0A000000` drop shadow |
| **"NK" profile avatar** | **amber** `AppColors.secondary` solid, **white initials**, soft black shadow `0x14000000` |
| **Cart icon** (header) | amber `#D2913C` circle, white SVG, drop shadow `0x26000000` |
| **Notification bell** (header) | amber circle, white SVG, drop shadow, red badge (`AppColors.error`) with white border |
| "Hey, NIRMAL" greeting | dark text |
| Year/class subtitle | gray-medium |
| **Balance Fees Due hero card** | **`brandGradient`** (navy diagonal), white text, white wallet icon, navy glow `primary 40%` |
| Fees Breakup title | dark heading |
| "Show all" link | text link `#B5752A` |
| **Fees Breakup carousel — first card (amount > 0)** | **`brandGradient`**, white text/icon, navy 30% shadow |
| Fees Breakup carousel — other cards | white card, border `borderC`, soft shadow |
| Fees Breakup empty slot | `filterBg` 40% bg, faint border |
| Fee category icon — School Fees | amber `#D2913C` icon on `#FAF1E4` |
| Fee category icon — Van/Transport | `#F59E0B` on `#FEF3C7` |
| Fee category icon — Hostel | `#3B82F6` on `#DBEAFE` |
| Fee category icon — Exam | `#06B6D4` on `#CFFAFE` |
| Fee category icon — Library | `#0EA5E9` on `#E0F2FE` |
| Fee category icon — Sports/Activity | `#10B981` on `#D1FAE5` |
| Fee category icon — Lab/Computer | `#14B8A6` on `#CCFBF1` |
| Fee category icon — Uniform | `#EC4899` on `#FCE7F3` |
| Fee category icon — Health/Medical | `#EF4444` on `#FEE2E2` |
| Fee category icon — Food/Canteen | `#F97316` on `#FFEDD5` |
| Fee category icon — Admission | `#6366F1` on `#E0E7FF` |
| Fee category icon — Annual/Term | `#D2913C` on `#FAF1E4` |
| Fee category icon — Other / unknown | `#8B5CF6` on `#F3E8FF` |
| Due badge | `#F59E0B` on `#FEF3C7` |
| Fee Status card | white, soft drop shadow |
| Status icon — overdue row | `AppColors.error` `#EF4444` |
| Status icon — due soon row | `AppColors.warning` `#F59E0B` |
| Currency symbol | `₹` (proper Unicode after mojibake fix) |
| Subtitle text (year, term, due-date meta) | `_textLight = #6B6B6B` (bumped from `#9E9E9E`) |

---

## Fees screens (Fees / Paid / All Pending / Pay All / Fee Details)

Common patterns across all fees screens.

| Element | Color |
|---|---|
| Page background | `scaffoldBg` |
| **Back button (44×44 circle)** | amber `iconButtonBg(context)` (`#D2913C`), white SVG arrow, drop shadow `0x26000000` |
| **Notification bell (44×44 circle)** | same amber circle + shadow, red badge |
| **Header student avatar (48×48)** | amber `AppColors.secondary` solid bg, white initials, soft drop shadow |
| Page title | `textPrimaryC` |
| Stat cards | `cardBg` (white) with `cardShadow`, dark numbers |
| "Total Pending / Overdue" stat icon | small navy circle with white icon |
| Currency | `₹` |
| Subtitle / meta text | `#6B6B6B` |
| Fee list card | white, soft shadow, navy small icon circle |
| Tab — active | amber accent + amber tint border (`fees_screen.dart` filter tabs) |
| Tab — inactive | dark text / transparent |
| **Pay-now / Pay-all button** | amber `#D2913C` filled, white text |
| Selected checkbox in pay-all | amber border + amber check |
| Cart preview bar | dark/black bar (currently — could be amber) |
| Empty / disabled fee row | 0.5 opacity over the white card style |

---

## Cart

| Element | Color |
|---|---|
| Page background | `scaffoldBg` |
| Back / notification buttons | amber `iconButtonBg` circle + shadow |
| Section header text | dark, subtitle `#6B6B6B` |
| Cart item card | white card, soft shadow |
| Fee badges (paid/pending/partial) | their fee-status colour (`#10B981` / `#EF4444` / `#F59E0B`) |
| Total summary card | white, dark text, amber/navy accents |
| "Go to Home" button (empty cart) | navy `AppColors.primary` filled, white text |
| **Proceed to Pay button** | amber `#D2913C` filled, white text, navy 30% shadow |
| Bottom bar | white with top divider |

---

## Payments (history / detail / receipt)

### `payment_history_screen.dart`
| Element | Color |
|---|---|
| Header (back + bell) | amber circles + shadow |
| Header avatar | amber |
| Filter chips — active | navy `AppColors.primary` filled / dark text |
| Payment row card | white, soft shadow |
| Status icon — Paid | green tick on `cardGreen` (`#E6F9F0`), text `cardGreenDark` (`#10B981`) |
| Status icon — Failed | red X on `cardRose` (`#FFF1F2`), text `cardRoseDark` (`#FB7185`) |
| "Paid" pill | `cardGreen` bg, `cardGreenDark` text |
| "Failed" pill | `cardRose` bg, `cardRoseDark` text |
| Amount — paid | dark `#1A1A1A` |
| Amount — failed | red `cardRoseDark` |
| Subtitle text (year, razorpay, date) | `_textLight = #6B6B6B` (was `#9E9E9E`) |
| Calendar icon + date row | `#6B6B6B` |

### `transaction_details_screen.dart`
| Element | Color |
|---|---|
| Header | white card with shadow |
| Back / bell | amber circles + shadow |
| Status banner | green / red per `cardGreen` / `cardRose` palette |
| Detail rows | dark labels / dark values |
| Receipt preview wrapper (B5 499×709) | white card centered in dialog |
| Action buttons | Download (outlined amber) / Print (filled amber) / Close (gray circle) |

### `payment_receipt_screen.dart`
The receipt itself follows its own minimal palette — see **Receipt** below.

---

## Notifications

| Element | Color |
|---|---|
| Header | amber back + bell circles, **amber avatar** |
| Notification row card | white, soft shadow |
| Notification type icon (small 36 circle) | navy `AppColors.primary`, white SVG |
| Unread dot indicator | navy `AppColors.primary` with navy 40% glow |
| Empty state icon | navy `AppColors.primary` |
| Detail screen card | white, dark text, gray timestamp `#6B6B6B` |
| Bell empty / clock icon | `#6B6B6B` |

---

## Profile

| Element | Color |
|---|---|
| Page background | `scaffoldBg` |
| Header card | white with drop shadow |
| **Small profile avatar (48)** | amber `AppColors.secondary`, white initials |
| **Big profile avatar (200, no photo)** | amber `AppColors.secondary`, large white initials, deep drop shadow |
| Header title "Hey, NIRMAL" | dark text |
| Section card | white, transparent border, `0x0A000000` shadow |
| Field label | `_textMedium = #6B6B6B` |
| Field value | `_textDark = #1A1A1A` |
| **"Switch Student" quick-action button** | amber `#D2913C` filled, white icon+label |
| **"Get Support" quick-action button** | white, **amber 1.5px stroke**, amber icon+label |
| Sign Out card | white, soft border, gray icon+label, opens dialog |
| Sign Out dialog button | dark `_textDark` background, white text |
| Sign Out dialog cancel | gray text |

---

## Student selection / switch

| Element | Color |
|---|---|
| Page bg | `scaffoldBg` |
| Header | amber circles + shadow |
| Student card — unselected | white, border `borderC` |
| Student card — selected | navy border 2px, navy gradient `primary → primary600` photo bg, "Selected" radio: filled navy, border navy |
| Class badge | navy text on light bg |
| Empty state icon circle | light purple `cardPurple` bg, purple icon `cardPurpleDark` |

---

## Support

| Element | Color |
|---|---|
| Page bg | `scaffoldBg` |
| Header | amber back / bell circles + shadow |
| Contact cards | white, dark text, gray meta `#6B6B6B` |
| Action buttons | follow profile-screen pattern |

---

## Receipt (B5 widget + B5 PDF — must stay 1:1)

| Element | Color |
|---|---|
| Page background | pure white |
| Page border (table) | 1pt **black** with 4pt rounded corners |
| Section dividers (table internal) | 1pt black |
| Vertical PARTICULARS \| AMOUNTS divider | 1pt black |
| Header — fallback logo | network image (no tint) |
| Header — school name | 20pt **black**, weight 800 (`w800`), letter-spacing 0.5, centered |
| Header — school address | 10pt black, weight 500, centered |
| "RECEIPT" label | 9pt black, weight 700 |
| Info row labels (Name : / Receipt No :) | 9pt black, weight 600 |
| Info row values | 9pt black, weight 400 |
| Empty value placeholder | dash `-` |
| Section header (PARTICULARS / AMOUNTS) | 9pt black, weight 700 |
| Fee line items (numbered) | 9pt black, weight 400 |
| TOTAL row | 9pt black, weight 700 |
| Amount in words ("Rupees ... Only") | 9pt black, weight 600 |
| **"* Subject to Realization"** (recon pending) | 9pt **orange `#B85C00`**, weight 600 — only when `reconStatus != 'R'` |
| Cashier signature line | 9pt black, weight 700, right-aligned |

> The receipt is the **only** part of the app that uses pure `#000000` text throughout and the orange `#B85C00` accent — both deliberate per `docs/receipt-design.md`.

---

## Drawer (`app_drawer.dart`)

| Element | Color |
|---|---|
| Drawer bg | white |
| Drawer header | white |
| User name / school name | navy `AppColors.primary` |
| Initials circle | `primary100` (`#C6D3E4`) bg, dark initials |
| Menu item icons | navy when selected / dark otherwise |
| Logout icon | red `AppColors.error` |

---

## Breadcrumb bar (desktop drill-downs)

| Element | Color |
|---|---|
| Pill bg | white, light gray border, soft shadow |
| "Back" segment | text link amber `textLink` (`#B5752A`), hover tint 8% amber |
| Current section icon | `AppColors.primary` (navy) |
| Trail segment | `textPrimaryC` |

---

## Status / system colors used app-wide

| Use case | Token / hex |
|---|---|
| Success snackbar / paid badge | `AppColors.success` `#10B981` |
| Warning snackbar / due-soon | `AppColors.warning` `#F59E0B` |
| Error snackbar / failed / red icons | `AppColors.error` `#EF4444` |
| Info | `AppColors.info` `#3B82F6` |
| Notification badge | `AppColors.error` `#EF4444` with white border |
| Realization warning (receipt only) | `#B85C00` |

---

## Theme defaults (`config/theme.dart`)

| Material token | Resolves to |
|---|---|
| `primaryColor` | `AppColors.primary` (navy) |
| `colorScheme.primary` | navy |
| `colorScheme.secondary` | `AppColors.accent` (amber) |
| `elevatedButtonTheme.bg` | navy |
| `outlinedButtonTheme.side` | navy border |
| `textButtonTheme.fg` | navy |
| `bottomNavigationBarTheme.selectedItemColor` | navy |
| `bottomNavigationBarTheme.unselectedItemColor` | `textTertiary` |

Most surfaces override these explicitly (auth buttons use hard-coded amber `#D2913C`, etc.) — the theme is the fallback when a widget doesn't override.

---

## Patterns to know

- **Amber buttons across the app are still hard-coded as `Color(0xFFD2913C)`** in many places (sign-in, sign-up, forgot-password, profile actions). When you change the brand button color, search `Color(0xFFD2913C)` in addition to `AppColors.buttonPrimary`.
- **Header back/bell circles in drill-down pages** all use `iconButtonBg(context)` → amber in light mode → with a unified `BoxShadow(color: 0x26000000, blurRadius: 12, offset: (0,4))` for visual parity with the home page.
- **`primary` (navy) is used in many "small icon" containers** (notification rows, fee row icons) — these are intentionally navy, distinct from the amber "action" buttons.
- **Subtitle gray was bumped project-wide from `#9E9E9E` → `#6B6B6B`** for readability — applied to year labels, payment method, date rows, etc.
- **Currency symbol** is the proper Unicode `₹` everywhere (after the project-wide mojibake fix).
