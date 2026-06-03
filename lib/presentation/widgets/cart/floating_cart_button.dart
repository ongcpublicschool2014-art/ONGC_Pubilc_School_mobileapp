import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../config/routes.dart';
import '../../providers/cart_provider.dart';
import '../common/app_icon.dart';

class FloatingCartButton extends ConsumerWidget {
  const FloatingCartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    // Don't show if cart is empty
    if (cartState.isEmpty) return const SizedBox.shrink();

    return Positioned(
      right: 16,
      bottom: 100, // Above bottom nav
      child: SizedBox(
        width: 60,
        height: 60,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: AppColors.accent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => context.push(Routes.cartStandalone),
              customBorder: const CircleBorder(),
              hoverColor: Colors.black.withValues(alpha: 0.06),
              focusColor: Colors.black.withValues(alpha: 0.10),
              splashColor: Colors.black.withValues(alpha: 0.22),
              highlightColor: Colors.black.withValues(alpha: 0.12),
              mouseCursor: SystemMouseCursors.click,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const AppIcon('shopping-cart', size: 28, color: Colors.white),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        cartState.itemCount > 9 ? '9+' : '${cartState.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
