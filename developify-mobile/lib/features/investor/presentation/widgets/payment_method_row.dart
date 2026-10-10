import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class PaymentMethodRow extends StatelessWidget {
  const PaymentMethodRow({
    super.key,
    required this.method,
    required this.onPressed,
    this.onSelect,
    this.change = false,
    this.selected = false,
    this.selecting = false,
  });
  final InvestorPaymentMethod method;
  final VoidCallback? onPressed;
  final VoidCallback? onSelect;
  final bool change;
  final bool selected;
  final bool selecting;

  @override
  Widget build(BuildContext context) {
    final card = method.kind == PaymentMethodKind.card;
    final description = card
        ? '${method.reusable ? 'Debit' : 'Single payment'} • expires ${method.expiry}'
        : '${method.holder} • ****${method.lastFour}';
    return Material(
      color: AppColors.transparent,
      child: InvestorSurface(
        radius: 12,
        border: card ? AppColors.borderStrong : AppColors.border,
        padding: EdgeInsets.fromLTRB(15.w, 14.w, card ? 6.w : 10.w, 14.w),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label:
                    '${change ? 'Change' : 'Manage'} ${method.name} '
                    '${card ? 'card' : 'account'} ending ${method.lastFour}',
                button: true,
                child: InkWell(
                  onTap: onPressed,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Row(
                      children: [
                        AppIcon(
                          card
                              ? AppAssets.investorCardAvatar
                              : AppAssets.investorBankAvatar,
                          size: 40,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                card
                                    ? '${method.name} • ****** ${method.lastFour}'
                                    : '${method.name} -',
                                style: AppTextStyles.text(
                                  16,
                                  weight: FontWeight.w600,
                                  height: 1.2,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(height: 4.w),
                              Text(
                                description,
                                style: AppTextStyles.text(
                                  14,
                                  weight: FontWeight.w500,
                                  height: 1.2,
                                  color: AppColors.iconMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (onSelect != null)
              InvestorIconButton(
                asset: selected
                    ? AppAssets.investorBankSelected
                    : AppAssets.radioUnselected,
                size: 32,
                selected: selected,
                label:
                    '${selecting ? 'Select' : 'Set'} ${method.name} '
                    '${card ? 'card' : 'account'} ending ${method.lastFour}'
                    '${selecting ? '' : ' as default'}',
                onPressed: onSelect,
              )
            else if (change)
              TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                ),
                child: Text(
                  'Change',
                  style: AppTextStyles.text(
                    16,
                    weight: FontWeight.w600,
                    height: 1.2,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              InvestorIconButton(
                asset: AppAssets.investorPaymentOptions,
                label:
                    'More options for ${method.name} ending ${method.lastFour}',
                onPressed: onPressed,
              ),
          ],
        ),
      ),
    );
  }
}
