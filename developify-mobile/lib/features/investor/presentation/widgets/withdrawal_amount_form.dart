import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/presentation/stores/transfer_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_amount_field.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class WithdrawalAmountForm extends StatelessWidget {
  const WithdrawalAmountForm({
    super.key,
    required this.store,
    required this.onAdd,
  });
  final TransferStore store;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InvestorAmountField(
          value: store.amountText,
          onChanged: store.editAmount,
          error: store.inputError,
          fontSize: store.amountText.isEmpty ? 48 : 45,
          fontWeight: FontWeight.w600,
          labelGap: 8,
        ),
        SizedBox(height: 8.w),
        Text(
          'Available : ${Money.amount(store.account!.balance(Currency.zar))}',
          textAlign: TextAlign.center,
          style: AppTextStyles.text(
            14,
            color: AppColors.iconMuted,
            weight: FontWeight.w500,
          ),
        ),
        SizedBox(height: store.amountText.isEmpty ? 45.w : 47.w),
        InvestorAmountPresets(
          values: const [1000, 2000, 5000],
          onSelected: store.editAmount,
          selectedValue: store.amountText,
        ),
        SizedBox(height: 41.w),
        Text(
          'Saved Accounts',
          style: AppTextStyles.text(16, weight: FontWeight.w600),
        ),
        SizedBox(height: 13.w),
        for (final method in store.methods) ...[
          Semantics(
            container: true,
            label: 'Select ${method.name} account ending ${method.lastFour}',
            checked: store.methodId == method.id,
            inMutuallyExclusiveGroup: true,
            button: true,
            excludeSemantics: true,
            onTap: () => store.selectMethod(method.id),
            child: InvestorMenuRow(
              icon: AppAssets.investorBank,
              title: method.name,
              subtitle: '${method.holder} • **** ${method.lastFour}',
              titleSize: 16,
              subtitleSize: 14,
              subtitleColor: AppColors.iconMuted,
              subtitleWeight: FontWeight.w500,
              subtitleGap: 4,
              radius: 12,
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 16.w),
              trailing: AppIcon(
                store.methodId == method.id
                    ? AppAssets.investorBankSelected
                    : AppAssets.radioUnselected,
                size: 32,
              ),
              onTap: () => store.selectMethod(method.id),
            ),
          ),
          SizedBox(height: 19.w),
        ],
        AppButton(
          label: 'Add a new bank account',
          onPressed: onAdd,
          style: AppButtonStyle.secondary,
        ),
      ],
    ),
  );
}
