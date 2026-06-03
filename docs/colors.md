# Color Palette

All colors are defined in [`lib/core/constants/app_colors.dart`](../lib/core/constants/app_colors.dart) as `AppColors.*` constants. Use the constant, not the hex literal.

**Brand summary:**
- **Primary = Deep Navy `#002147`** — trust / data display (balance cards, hero gradients, brand identity)
- **Secondary / Accent = Burnished Amber `#D2913C`** — action / accent (buttons, avatars, focus rings, links)
- Only orange accent on the receipt is `#B85C00` ("Subject to Realization" note)

---

## 1. Primary — Navy

Used for the brand identity: balance card, brand gradients, primary borders, theme `primary`.

| Token | Hex | Swatch |
|---|---|---|
| `primary` / `primary500` | `#002147` | Deep navy (base) |
| `primary50`  | `#E6EAF0` | Lightest navy tint |
| `primary100` | `#C6D3E4` |  |
| `primary200` | `#94A8C3` |  |
| `primary300` | `#6280A3` |  |
| `primary400` | `#315583` |  |
| `primary600` | `#001A38` |  |
| `primary700` | `#00142B` |  |
| `primary800` | `#000D1D` |  |
| `primary900` | `#000610` | Darkest navy |

## 2. Secondary / Accent — Amber

Used for primary action buttons, avatars, focus rings, text links, icon-button backgrounds, "active" highlights.

| Token | Hex | Notes |
|---|---|---|
| `secondary` / `accent` / `buttonPrimary` / `avatarBg` / `borderFocus` | `#D2913C` | Burnished amber (base) |
| `secondaryLight` | `#F3DCB5` | Light amber surface |
| `buttonPrimaryHover` | `#B5752A` | Hover/pressed amber |
| `textLink` | `#B5752A` | Amber text for links and text-buttons |
| `accent2` | `#E4EAF2` | Light blue-grey, decorative |

---

## 3. Gradients

| Constant | Stops | Direction | Use |
|---|---|---|---|
| `brandGradient` | `#3A5A8C → #002147 → #00132E` | top-left → bottom-right | Home Balance / Fees Breakup hero card |
| `brandGradientVertical` | same stops | top → bottom | Splash / full-screen backgrounds |
| `accentGradient` | `#E5A85C → #D2913C → #A66A24` | top-left → bottom-right | Amber active states / highlights |

Helper constants for the navy stops are also exposed: `gradientStart = #3A5A8C`, `gradientMiddle = #002147`, `gradientEnd = #00132E`.

---

## 4. Neutrals — Greys

| Token | Hex | Typical use |
|---|---|---|
| `gray50`  | `#FAFAFC` | Subtle backgrounds |
| `gray100` | `#F4F4F7` |  |
| `gray200` | `#E8E8ED` | Borders on light bg |
| `gray300` | `#D1D1DB` | Disabled / dividers |
| `gray400` | `#9E9EAF` |  |
| `gray500` | `#6B6B80` | Secondary text |
| `gray600` | `#4A4A5E` |  |
| `gray700` | `#363649` | Headings on light bg |
| `gray800` | `#252536` | Card surfaces (dark mode) |
| `gray900` | `#151523` | Deepest neutral |

---

## 5. Status / Semantic

### Success (green)
| Token | Hex |
|---|---|
| `success`      | `#10B981` |
| `successLight` | `#D1FAE5` |
| `successDark`  | `#059669` |

### Warning (amber)
| Token | Hex |
|---|---|
| `warning`      | `#F59E0B` |
| `warningLight` | `#FEF3C7` |
| `warningDark`  | `#D97706` |

### Error (red)
| Token | Hex |
|---|---|
| `error`      | `#EF4444` |
| `errorLight` | `#FEE2E2` |
| `errorDark`  | `#DC2626` |

### Info (blue)
| Token | Hex |
|---|---|
| `info`      | `#3B82F6` |
| `infoLight` | `#DBEAFE` |
| `infoDark`  | `#2563EB` |

### Fee Status
| Token | Hex | Bg pair |
|---|---|---|
| `feePaid`    | `#10B981` | `feePaidBg`    `#D1FAE5` |
| `feePending` | `#EF4444` | `feePendingBg` `#FEE2E2` |
| `feeOverdue` | `#DC2626` | `feeOverdueBg` `#FEE2E2` |
| `feePartial` | `#F59E0B` | `feePartialBg` `#FEF3C7` |

---

## 6. Backgrounds & Surfaces

| Token | Hex | Use |
|---|---|---|
| `background`  | `#F0FBF6` | Page (legacy mint) |
| `surface`     | `#FFFFFF` | Card surface |
| `bgPrimary`   | `#FFFFFF` |  |
| `bgSecondary` | `#F8F9FC` | Subtle off-white |
| `bgTertiary`  | `#F0EFFF` | Very pale lavender |

The actually-used scaffold background is `#F1F5F9` (returned by `scaffoldBg(context)` — see Dark-mode section).

---

## 7. Text

| Token | Hex | Use |
|---|---|---|
| `textPrimary`   | `#1F2937` | Body / headings |
| `textSecondary` | `#4B5563` | Subtitles |
| `textTertiary`  | `#6B7280` | Hint / meta |
| `textHint`      | `#9CA3AF` | Input placeholder |
| `textDisabled`  | `#D1D5DB` | Disabled labels |
| `textInverse`   | `#FFFFFF` | Text on dark bg |
| `textLink`      | `#B5752A` | Amber link colour |

> **Subtitle gray note:** several screens used local `_textLight = #9E9E9E`, which read as washed-out on the home / fees / payment lists. Bumped to **`#6B6B6B`** project-wide for readability.

---

## 8. Borders / Dividers

| Token | Hex | Use |
|---|---|---|
| `border`      | `#E5E7EB` | Standard 1px border |
| `borderLight` | `#F3F4F6` | Soft divider |
| `divider`     | `#E5E7EB` | Same as border |
| `borderFocus` | `#D2913C` | Amber focus ring on inputs |

---

## 9. Card Tints (pastel + dark pair)

Used for category tiles, fee group cards, illustration backgrounds.

| Pair | Light bg | Saturated |
|---|---|---|
| Blue   | `#E8F4FD` / `cardBlue`   | `#4A9FD4` / `cardBlueDark`   |
| Purple | `#F0EEFF` / `cardPurple` | `#8B5CF6` / `cardPurpleDark` |
| Pink   | `#FFE8EF` / `cardPink`   | `#EC4899` / `cardPinkDark`   |
| Green  | `#E6F9F0` / `cardGreen`  | `#10B981` / `cardGreenDark`  |
| Orange | `#FFF4E6` / `cardOrange` | `#F97316` / `cardOrangeDark` |
| Yellow | `#FFFBE6` / `cardYellow` | `#EAB308` / `cardYellowDark` |
| Cyan   | `#E6FFFE` / `cardCyan`   | `#06B6D4` / `cardCyanDark`   |
| Rose   | `#FFF1F2` / `cardRose`   | `#FB7185` / `cardRoseDark`   |

### Category icon tints

| Category | Bg | Icon |
|---|---|---|
| School Fees | `#EDE9FE` / `schoolFeesBg` | `#8B5CF6` / `schoolFeesIcon` |
| Transport   | `#D1FAE5` / `transportBg`  | `#10B981` / `transportIcon`  |
| Hostel      | `#FFE4E6` / `hostelBg`     | `#F43F5E` / `hostelIcon`     |
| Exam        | `#CFFAFE` / `examBg`       | `#06B6D4` / `examIcon`       |
| History     | `#FEF3C7` / `historyBg`    | `#F59E0B` / `historyIcon`    |
| Support     | `#E0E7FF` / `supportBg`    | `#6366F1` / `supportIcon`    |

> Fee-group icon mapping (`_getIconForFeeGroup` in `home_screen.dart`) covers more keywords with their own colours: library `#0EA5E9`, sports `#10B981`, lab `#14B8A6`, uniform `#EC4899`, health `#EF4444`, food `#F97316`, admission `#6366F1`, annual `#D2913C`. Unknown / "Other" falls back to saturated purple `#8B5CF6`.

---

## 10. Avatars & Buttons

| Token | Hex | Use |
|---|---|---|
| `avatarBg`         | `#D2913C` | Header initials circle (amber) |
| `avatarText`       | `#FFFFFF` | Initials text |
| `buttonPrimary`    | `#D2913C` | Amber action button bg |
| `buttonPrimaryHover` | `#B5752A` | Hover/pressed |
| `buttonSecondary`  | `#FFFFFF` | White secondary button |
| `buttonSecondaryBorder` | `#E5E7EB` | Border on white button |
| `buttonDanger`     | `#EF4444` | Destructive action |
| `buttonDangerBg`   | `#FEF2F2` | Soft danger bg |

> Many auth + drill-down screens still hard-code `Color(0xFFD2913C)` for main action buttons (e.g. Sign In) rather than referencing `buttonPrimary` — prefer the constant in new code.

---

## 11. Shadows

| Token | Value | Use |
|---|---|---|
| `shadowLight`  | `0D000000` (5% black)  | Subtle card lift |
| `shadowMedium` | `1A000000` (10% black) | Standard card |
| `shadowDark`   | `26000000` (15% black) | Pronounced drop (icon buttons) |
| `shadowBlue`   | `1A3B82F6` | Blue-tinted shadow |
| `shadowPurple` | `1A8B5CF6` | Purple-tinted |
| `shadowPink`   | `1AEC4899` | Pink-tinted |
| `shadowGreen`  | `1A10B981` | Green-tinted |

Drill-down icon buttons use `BoxShadow(color: 0x26000000, blurRadius: 12, offset: (0,4))` to match the home page header.

---

## 12. Glassmorphism

| Token | Value | Use |
|---|---|---|
| `glassWhite`  | `CCFFFFFF` (80% white)   | Frosted overlay |
| `glassBorder` | `33FFFFFF` (20% white) | 1px highlight border |

---

## 13. Dark-mode-aware tokens

These are **functions** that take `BuildContext` and return the right value for the current `Theme.brightness`. Always prefer these over the static constants when the surface might appear in dark mode.

| Function | Light | Dark |
|---|---|---|
| `scaffoldBg(context)`       | `#F1F5F9` | `#121218` |
| `cardBg(context)`           | `#FFFFFF` | `#1E1E2A` |
| `textPrimaryC(context)`     | `#1F2937` | `#F3F4F6` |
| `textSecondaryC(context)`   | `#6B7280` | `#9CA3AF` |
| `textHintC(context)`        | `#9CA3AF` | `#6B7280` |
| `borderC(context)`          | `#E5E7EB` | `#2D2D3D` |
| `filterBg(context)`         | `#F1F5F9` | `#252536` |
| `iconButtonBg(context)`     | `#D2913C` (amber) | `#374151` |
| `iconButtonBorder(context)` | `#D2913C` | `#374151` |
| `iconButtonColor`           | `#FFFFFF` | `#FFFFFF` (constant) |
| `headerBg(context)`         | `#FFFFFF` | `#1A1A26` |
| `cardShadow(context)`       | 4% black, 4 blur, 1 dy | `[]` (no shadow) |

---

## 14. Special — Receipt

| Use | Hex | Notes |
|---|---|---|
| Realization warning | `#B85C00` | Only accent colour on the receipt; "* Subject to Realization" text. Hard-coded in `receipt_widget.dart` and `receipt_pdf_generator.dart`. |
| Receipt body | `#000000` | Pure black on white throughout |

---

## How to use

```dart
import '../../core/constants/app_colors.dart';

// Static token
Container(color: AppColors.primary)

// Gradient
Container(decoration: BoxDecoration(gradient: AppColors.brandGradient))

// Brightness-aware
Container(color: AppColors.cardBg(context))
```
