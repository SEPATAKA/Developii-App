import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investment_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_amount_field.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class InvestmentAmountForm extends StatelessWidget {
  const InvestmentAmountForm({super.key, required this.store});
  final InvestmentStore store;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final project = store.project!;
      final currency = project.minimumInvestment.currency;
      final zero = MonetaryAmount(0, currency);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Available Balance : ${Money.amount(store.account?.balance(currency) ?? zero)}',
            textAlign: TextAlign.end,
            style: AppTextStyles.text(14, weight: FontWeight.w500),
          ),
          SizedBox(height: 10.w),
          InvestorSurface(
            color: AppColors.white,
            border: AppColors.border,
            radius: 10,
            padding: EdgeInsets.fromLTRB(18.w, 18.w, 18.w, 8.w),
            child: Column(
              children: [
                InvestorAmountField(
                  value: store.amountText,
                  onChanged: store.editAmount,
                  currency: currency,
                  fontSize: 36,
                  hintColor: AppColors.text,
                  label: 'How much would you like to invest?',
                  error: store.amountError,
                ),
                SizedBox(height: 18.w),
                Text(
                  'Min ${Money.amount(project.minimumInvestment, decimals: false)}      -     Max ${Money.amount(project.maximumInvestment, decimals: false)}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    14,
                    color: AppColors.primary,
                    weight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 30.w),
                InvestorAmountPresets(
                  values: const [
                    InvestmentPolicy.minimumMajorUnits,
                    1000,
                    2000,
                    5000,
                  ],
                  currency: currency,
                  onSelected: store.editAmount,
                  selectedValue: store.amountText,
                ),
              ],
            ),
          ),
          SizedBox(height: 32.w),
          InvestorSurface(
            color: AppColors.mint,
            border: AppColors.mint,
            radius: 7,
            padding: EdgeInsets.fromLTRB(17.w, 10.w, 38.w, 10.w),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projected payout',
                        style: AppTextStyles.text(
                          16,
                          weight: FontWeight.w600,
                          color: AppColors.mintText,
                        ),
                      ),
                      SizedBox(height: 4.w),
                      Text(
                        'in ${project.durationMonths} months',
                        style: AppTextStyles.text(
                          14,
                          color: AppColors.mintText,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    Money.amount(store.projectedPayout ?? zero),
                    textAlign: TextAlign.end,
                    style: AppTextStyles.text(
                      22,
                      weight: FontWeight.w700,
                      color: AppColors.mintText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (store.amountError?.contains('balance') == true)
            Padding(
              padding: EdgeInsets.only(top: 20.w),
              child: AppButton(
                label: 'Top up wallet',
                style: AppButtonStyle.secondary,
                onPressed: () => context.pushNamed(
                  InvestorRoutes.addMoney,
                  queryParameters: {
                    'returnProjectId': store.project!.id,
                    'returnAmountCents': store.amount!.minorUnits.toString(),
                  },
                ),
              ),
            ),
        ],
      );
    },
  );
}
