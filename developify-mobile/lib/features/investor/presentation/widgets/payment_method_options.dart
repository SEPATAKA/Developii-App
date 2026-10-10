import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_switch.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/stores/payment_methods_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/payment_card_preview.dart';

Future<void> showPaymentMethodOptions(
  BuildContext context, {
  required PaymentMethodsStore store,
  required String methodId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  barrierColor: AppColors.modalScrim,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
  ),
  builder: (context) => Observer(
    builder: (_) {
      final method = store.methods
          .where((item) => item.id == methodId)
          .firstOrNull;
      final card = method?.kind == PaymentMethodKind.card;
      final canSetDefault = !store.saving && method?.reusable == true;
      return PopScope(
        canPop: !store.saving,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 108.w,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 58.w,
                        right: 58.w,
                        top: 46.w,
                        child: Text(
                          'More Options',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.text(
                            16,
                            height: 1.2,
                            weight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 15.638.w,
                        top: 32.2575.w,
                        child: InvestorIconButton(
                          asset: AppAssets.investorModalClose,
                          label: 'Close payment method options',
                          size: 35,
                          onPressed: store.saving
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (method == null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 32.w),
                    child: Text(
                      'This payment method is no longer available.',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (card)
                          PaymentCardPreview(method: method, compact: true)
                        else
                          InvestorSurface(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(method.name, style: AppTextStyles.section),
                                SizedBox(height: 8.w),
                                Text(
                                  '${method.holder}\n**** ${method.lastFour}',
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                        if (!method.reusable) ...[
                          SizedBox(height: 16.w),
                          Text(
                            'Available for one simulated payment.',
                            style: AppTextStyles.body,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        SizedBox(height: 31.w),
                        Semantics(
                          toggled: method.isDefault,
                          label: 'Set as default',
                          excludeSemantics: true,
                          enabled: canSetDefault,
                          onTap: !canSetDefault
                              ? null
                              : () => store.setDefault(
                                  method.id,
                                  !method.isDefault,
                                ),
                          child: InkWell(
                            onTap: !canSetDefault
                                ? null
                                : () => store.setDefault(
                                    method.id,
                                    !method.isDefault,
                                  ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 44),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Set as default',
                                      style: AppTextStyles.text(
                                        16,
                                        weight: FontWeight.w500,
                                        height: 1.2,
                                        color: AppColors.gray900,
                                      ),
                                    ),
                                  ),
                                  if (store.mutation ==
                                      PaymentMethodMutation.setDefault)
                                    SizedBox.square(
                                      dimension: 20.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.w,
                                        semanticsLabel:
                                            'Updating default payment method',
                                      ),
                                    )
                                  else
                                    AppSwitch(value: method.isDefault),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.w),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                        SizedBox(height: 23.w),
                        if (store.error != null) InlineError(store.error),
                        ConstrainedBox(
                          constraints: BoxConstraints(minHeight: 56.w),
                          child: AppButton(
                            label: card ? 'Delete Card' : 'Delete Bank Account',
                            labelSize: 14,
                            style: AppButtonStyle.danger,
                            icon: AppAssets.investorPaymentDelete,
                            iconSize: 15,
                            iconGap: 16,
                            loading:
                                store.mutation == PaymentMethodMutation.remove,
                            onPressed: store.saving
                                ? null
                                : () async {
                                    if (await store.remove(method.id) &&
                                        context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  ),
);
