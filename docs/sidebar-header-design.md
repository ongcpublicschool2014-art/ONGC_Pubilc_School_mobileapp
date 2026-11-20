# Sidebar & Header Design Spec

Source of truth: [`lib/presentation/widgets/common/main_scaffold.dart`](../lib/presentation/widgets/common/main_scaffold.dart)

This document captures the visual + behavioral spec for the desktop **top header bar** and **left sidebar** that wrap every authenticated page inside `MainScaffold`. Mobile uses a bottom nav (see Section 5) and is documented for completeness.

---

## 1. Layout skeleton (desktop)

```
┌──────────────────────────────────────────────────────────────────────┐
│  [Logo]  School Name        [Search]  [Cart]  [Bell]  [Avatar ▾]     │ 64 px header
├────────────┬─────────────────────────────────────────────────────────┤
│            │                                                         │
│  SIDEBAR   │           CONTENT AREA                                  │
│  260 px    │           (scaffoldBg #F1F5F9, 16 px padding)           │
│            │                                                         │
└────────────┴─────────────────────────────────────────────────────────┘
```

- Outer scaffold bg: `AppColors.cardBg` (white light / `#1E1E2A` dark)
- Header and sidebar share the same white surface and are separated from the content by a `border` 1 px `Divider` on both axes.
- Content pane uses `AppColors.scaffoldBg` = `#F1F5F9` (light) / `#121218` (dark).

---

## 2. Top header bar

| Property | Value |
| --- | --- |
| Height | **64 px** |
| Horizontal padding | 24 px |
| Background | `AppColors.cardBg(context)` (white / `#1E1E2A`) |
| Bottom divider | 1 px, `AppColors.borderC` |

### 2.1 Brand block (left)

| Element | Spec |
| --- | --- |
| Logo container | 48 × 48, radius 12, border `borderC @ 30% alpha` |
| Fallback logo | Primary green bg + `AppIcon('book', size 26, white)` |
| School name | 18 px, `FontWeight.w700`, `textPrimaryC`, max 260 px width, ellipsis |
| Gap after logo | 12 px |

### 2.2 Search field (middle, pushes right with `Spacer`)

Handled by `_TopBarSearchField` (internal widget).

| Property | Value |
| --- | --- |
| Max width | 320 px |
| Shape | 44 px pill |
| Compose | gray icon chip + white input + primary green filter button |
| Filter menu | PopupMenu with fee-focused filters |

### 2.3 Top-right icon buttons

Reusable helper: `_buildTopBarIconButton`.

| Property | Value |
| --- | --- |
| Diameter | **44 × 44**, circular |
| Background | `#121212` (dark chip, both themes) |
| Glyph | 20 × 20 SVG, white tint |
| Shadow | `#26000000`, blur 12, offset `(0, 4)` |
| Unread badge | error red circle, 16 × 16 min, 1.5 px white border, top-right `(-3, -3)` offset, `9+` cap |
| Buttons (in order) | Cart → `Routes.cart`, Bell → `Routes.notifications` |
| Gap | 10 px between icons |

### 2.4 Avatar + student menu (far right)

| Element | Spec |
| --- | --- |
| Avatar | 36 × 36 circle, bg `primary @ 15% alpha`, photo or initials |
| Initials | 13 px, w700, primary green |
| Name | 13 px, w600, `textPrimaryC`, max 120 px, ellipsis |
| Role subtitle | 11 px, `textHintC` ("Student") |
| Dropdown chevron | `AppIcon('arrow-down', 20 px, textHintC)` |
| Menu items | **Switch Account** (`arrow-swap-horizontal`) · **Logout** (`logout`, error red) |
| Popup | radius 12, `cardBg`, 50 px y-offset |

---

## 3. Left sidebar

| Property | Value |
| --- | --- |
| Width | **260 px** |
| Top spacer | 20 px |
| Group spacing | 20 px between `MAIN MENU` and `GENERAL` |
| Right border | 1 px `borderC` vertical divider |

### 3.1 Section labels

| Property | Value |
| --- | --- |
| Labels | `MAIN MENU`, `GENERAL` |
| Type | 11 px, w600, **letterSpacing 1.2**, color `#121212` |
| Padding | `24 px left, 4 top, 20 right` |
| Bottom gap to first item | 8 px |

### 3.2 Sidebar items

Each item (selected **or** idle) shares the same footprint.

| Property | Value |
| --- | --- |
| Item margin | 12 px horizontal, 2 px vertical |
| Item padding | 14 px horizontal, 12 px vertical |
| Icon size | 20 × 20 (uses `line` SVG idle, `fill` SVG selected) |
| Icon-label gap | 12 px |
| Label | 14 px, **w600** |
| Corner radius | **10 px** |
| Selected bg | `AppColors.primary` (green) |
| Selected fg | white |
| Idle fg | `textSecondaryC` |
| Animation | 150 ms `AnimatedContainer` on selection swap |
| Badge (Alerts) | pill 22–32 px, white-alpha bg when selected, error red when idle; cap `99+` |

### 3.3 Nav tree

```
MAIN MENU
├─ Dashboard  →  /home
├─ History    →  /payment-history
└─ Alerts     →  /notifications  (shows unread badge)

GENERAL
├─ Profile    →  /profile
└─ Logout     →  confirm dialog → signOut + /welcome
```

Active index resolution lives in `_calculateSelectedIndex` — drill-down routes map back to their parent tab (e.g. `/transaction/...` highlights **History**).

### 3.4 Logout confirm dialog

| Property | Value |
| --- | --- |
| Shape | `RoundedRectangleBorder` radius 20 |
| Title | "Sign Out" |
| Body | "Are you sure you want to sign out?" |
| Cancel | text button, `textSecondaryC` |
| Confirm | elevated, bg `AppColors.error`, radius 12, label **Sign Out** |

---

## 4. Responsive behavior

- Breakpoint: `context.isDesktop` (handled in `core/utils/extensions.dart`).
- Below that, `MainScaffold` swaps to mobile layout and the sidebar is not rendered.
- Drill-down routes (`_isDrillDownRoute`) bypass the mobile shell entirely and let the target screen own its own Scaffold/header.

---

## 5. Mobile shell (for contrast)

- Scaffold bg: `scaffoldBg` = `#F1F5F9`
- No sidebar; bottom nav with 4 slots:
  - **Home** · **History** · **Alerts** · **Profile**
- Bottom bar surface: `cardBg` (white) with top shadow `#0000000F`, blur 20.
- System UI overlay: transparent status bar, nav bar matches `cardBg`.
- Page-specific headers live inside each screen (e.g. the avatar + cart + bell row on Home).

---

## 6. Color tokens reference

| Token | Light | Dark |
| --- | --- | --- |
| `scaffoldBg`    | `#F1F5F9` | `#121218` |
| `cardBg`        | `#FFFFFF` | `#1E1E2A` |
| `headerBg`      | `#FFFFFF` | `#1A1A26` |
| `borderC`       | `#E5E7EB` | `#2D2D3D` |
| `primary`       | `#0D9B5C` | same |
| `textPrimaryC`  | `#1F2937` | `#F3F4F6` |
| `textSecondaryC`| `#6B7280` | `#9CA3AF` |
| `textHintC`     | `#9CA3AF` | `#6B7280` |
| `error`         | `#EF4444` | same |
| Icon-button bg  | `#121212` | `#374151` |

All tokens resolved via `BuildContext`-aware helpers on `AppColors` — avoid hard-coded hex in new widgets.

---

## 7. Asset paths

| Purpose | Path |
| --- | --- |
| Sidebar line icons | `assets/main icons/line icons/<name>.svg` |
| Sidebar fill icons | `assets/main icons/fill icons/<name>.svg` |
| Cart icon | `assets/icons/Cart.svg` |
| Bell icon | `assets/main icons/line icons/notification.svg` |
| Generic SVG set | `assets/icons/linear/`, `assets/icons/bold/` (used by `AppIcon`) |
