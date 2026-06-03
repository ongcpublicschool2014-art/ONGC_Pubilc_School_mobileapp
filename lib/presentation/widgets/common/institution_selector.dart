import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/institution_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import '../../../core/services/supabase_service.dart';
import 'app_icon.dart';

/// Reusable institution selector dropdown for auth screens.
/// Sets [selectedAuthInstitutionProvider] and calls
/// [SupabaseService.determineAndSetSchema] when the user picks an institution.
class InstitutionSelector extends ConsumerStatefulWidget {
  const InstitutionSelector({super.key});

  @override
  ConsumerState<InstitutionSelector> createState() =>
      _InstitutionSelectorState();
}

class _InstitutionSelectorState extends ConsumerState<InstitutionSelector> {
  bool _settingSchema = false;

  Future<void> _onInstitutionSelected(InstitutionModel institution) async {
    setState(() => _settingSchema = true);

    // Set the selected institution
    ref.read(selectedAuthInstitutionProvider.notifier).state = institution;

    // Determine and set the schema for this institution
    final schema =
        await SupabaseService.determineAndSetSchema(institution.insId);

    if (schema == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not determine academic year for this institution. Please contact admin.'),
          backgroundColor: Colors.red,
        ),
      );
      ref.read(selectedAuthInstitutionProvider.notifier).state = null;
    }

    if (mounted) setState(() => _settingSchema = false);
  }

  @override
  Widget build(BuildContext context) {
    final institutionsAsync = ref.watch(institutionsProvider);
    final selectedInstitution = ref.watch(selectedAuthInstitutionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Institution',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimaryC(context),
          ),
        ),
        const SizedBox(height: 8),
        institutionsAsync.when(
          loading: () => _buildContainer(
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading institutions...'),
              ],
            ),
          ),
          error: (_, __) => _buildContainer(
            child: const Text('Failed to load institutions'),
          ),
          data: (institutions) {
            if (institutions.isEmpty) {
              return _buildContainer(
                child: const Text('No institutions available'),
              );
            }

            return GestureDetector(
              onTap: _settingSchema
                  ? null
                  : () => _showInstitutionPicker(institutions),
              child: _buildContainer(
                child: Row(
                  children: [
                    AppIcon(
                      'book',
                      size: 22,
                      color: AppColors.textSecondaryC(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _settingSchema
                          ? Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Setting up...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondaryC(context),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              selectedInstitution?.insname ??
                                  'Select your institution',
                              style: TextStyle(
                                fontSize: 15,
                                color: selectedInstitution != null
                                    ? AppColors.textPrimaryC(context)
                                    : AppColors.textHintC(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    AppIcon(
                      'arrow-down',
                      size: 22,
                      color: AppColors.textSecondaryC(context),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderC(context)),
      ),
      child: child,
    );
  }

  void _showInstitutionPicker(List<InstitutionModel> institutions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Institution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryC(context),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: institutions.length,
                itemBuilder: (context, index) {
                  final inst = institutions[index];
                  final isSelected = ref
                          .read(selectedAuthInstitutionProvider)
                          ?.insId ==
                      inst.insId;

                  return ListTile(
                    leading: inst.inslogo != null && inst.inslogo!.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(inst.inslogo!),
                            radius: 20,
                          )
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                            child: AppIcon(
                              'book',
                              color: AppColors.secondary,
                              size: 20,
                            ),
                          ),
                    title: Text(
                      inst.insname,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.textPrimaryC(context),
                      ),
                    ),
                    subtitle: inst.shortAddress != 'Address not available'
                        ? Text(
                            inst.shortAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryC(context),
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? AppIcon('tick-circle',
                            color: AppColors.primary, size: 22)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _onInstitutionSelected(inst);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
