import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investment_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investment_calculator_form.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investment_amount_form.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_confirmation_sheet.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_property_image.dart';

class InvestmentScreen extends StatelessWidget {
  const InvestmentScreen({
    super.key,
    required this.store,
    required this.id,
    this.calculator = false,
  });
  final InvestmentStore store;
  final String id;
  final bool calculator;
  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) => PopScope<Object?>(
      canPop:
          store.project == null ||
          store.stage == InvestmentStage.amount ||
          store.stage == InvestmentStage.success,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(context);
      },
      child: _page(context),
    ),
  );

  Widget _page(BuildContext context) {
    final project = store.project;
    if (project == null) {
      return InvestorPage(
        title: calculator ? 'Investment Calculator' : 'Invest in projects',
        child: store.status == LoadStatus.error
            ? ErrorView(
                message: store.error ?? 'Unable to load this project.',
                onRetry: () => store.load(id),
              )
            : const LoadingView(),
      );
    }
    final reviewing = store.stage != InvestmentStage.amount;
    final currency = project.minimumInvestment.currency;
    final amount = store.amount ?? MonetaryAmount(0, currency);
    final projected = store.projectedPayout ?? MonetaryAmount(0, currency);
    return InvestorPage(
      footerBottomInset: calculator ? 0 : 18,
      headerLeadingInset: calculator ? 14 : null,
      headerTopInset: calculator ? 18 : null,
      titleTopOffset: calculator ? -4 : 0,
      titleOverflow: calculator ? TextOverflow.ellipsis : TextOverflow.visible,
      title: calculator
          ? 'Investment Calculator'
          : reviewing
          ? 'Review Investment'
          : 'Invest in projects',
      onBack: () => _back(context),
      bottom: Padding(
        padding: EdgeInsets.only(left: calculator ? 2.w : 0),
        child: AppButton(
          label: calculator
              ? 'Invest this amount'
              : reviewing
              ? 'Authorize with PIN'
              : 'Review Investment',
          loading: store.stage == InvestmentStage.processing,
          onPressed: !project.canInvest
              ? null
              : reviewing
              ? store.agreed
                    ? () => _authorize(context)
                    : null
              : !store.validAmount
              ? null
              : () {
                  if (calculator) {
                    if (!store.prepareQuote()) return;
                    context.pushNamed(
                      InvestorRoutes.invest,
                      pathParameters: {'id': id},
                      queryParameters: {
                        'amountCents': '${store.amount!.minorUnits}',
                      },
                    );
                  } else {
                    store.review();
                  }
                },
        ),
      ),
      child: ListView(
        key: ValueKey(reviewing ? 'investment-review' : 'investment-amount'),
        children: [
          ...[
            SizedBox(height: 16.w),
            InvestorSurface(
              padding: EdgeInsets.fromLTRB(8.w, 7.w, 8.w, 11.w),
              border: AppColors.border,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: InvestorPropertyImage(
                      project.thumbnailAsset ?? project.imageAsset,
                      width: 63.w,
                      height: 63.w,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  SizedBox(width: 17.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, style: AppTextStyles.section),
                        SizedBox(height: 7.w),
                        Text(
                          reviewing
                              ? '${project.city} • ${project.area}'
                              : 'ROI ${project.annualReturnBasisPoints / 100}%   ${project.durationMonths} Months   ${project.fundedBasisPoints ~/ 100}% Funded',
                          style: AppTextStyles.text(
                            14,
                            color: AppColors.iconMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: calculator
                  ? 16.w
                  : reviewing
                  ? 19.w
                  : 41.w,
            ),
          ],
          if (!reviewing && !calculator) InvestmentAmountForm(store: store),
          if (!reviewing && calculator) ...[
            InvestmentCalculatorForm(
              project: project,
              amountText: store.amountText,
              amount: amount,
              projectedPayout: projected,
              onChanged: store.editAmount,
              error: store.amountError,
            ),
          ],
          if (reviewing) ...[
            InvestorSurface(
              border: AppColors.border,
              child: Column(
                children: [
                  Text(
                    'Investment Amount',
                    style: AppTextStyles.text(
                      14,
                      color: AppColors.muted,
                      weight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 14.w),
                  Text(
                    Money.amount(amount),
                    style: AppTextStyles.text(
                      36,
                      weight: FontWeight.w700,
                      letterSpacing: -.72,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.w),
            InvestorSurface(
              border: AppColors.border,
              radius: 8,
              padding: EdgeInsets.fromLTRB(12.w, 18.w, 12.w, 7.w),
              child: Column(
                children: [
                  _InvestmentDetailRow('Source', 'Wallet (${currency.code})'),
                  _InvestmentDetailRow(
                    'ROI (Estimated)',
                    '${project.annualReturnBasisPoints / 100}%',
                  ),
                  _InvestmentDetailRow(
                    'Terms',
                    '${project.durationMonths} months',
                  ),
                  _InvestmentDetailRow(
                    'Monthly',
                    project.projection(amount).paymentRangeLabel,
                  ),
                  _InvestmentDetailRow(
                    'Projected payout',
                    Money.amount(projected),
                  ),
                  const _InvestmentDetailRow('Risk', 'Moderate'),
                ],
              ),
            ),
            SizedBox(height: 27.w),
            Semantics(
              label: 'Accept investment risks',
              checked: store.agreed,
              enabled: store.stage != InvestmentStage.processing,
              excludeSemantics: true,
              onTap: store.stage == InvestmentStage.processing
                  ? null
                  : () => store.setAgreement(!store.agreed),
              child: InkWell(
                onTap: store.stage == InvestmentStage.processing
                    ? null
                    : () => store.setAgreement(!store.agreed),
                borderRadius: BorderRadius.circular(8.r),
                child: InvestorSurface(
                  radius: 8,
                  border: AppColors.border,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 15.5.w,
                  ),
                  child: Row(
                    children: [
                      AppIcon(
                        store.agreed
                            ? AppAssets.investorConsentChecked
                            : AppAssets.investorConsentUnchecked,
                        size: 22,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'I confirm I’ve read the '),
                              TextSpan(
                                text: 'offering memorandum',
                                style: AppTextStyles.text(
                                  14,
                                  color: AppColors.primary,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    ' and understand the risks of property investment',
                              ),
                            ],
                          ),
                          style: AppTextStyles.text(14, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (project.investmentUnavailableReason != null)
            InlineError(project.investmentUnavailableReason),
          if (store.error != null) InlineError(store.error),
          SizedBox(height: 24.w),
        ],
      ),
    );
  }

  void _back(BuildContext context) {
    if (store.stage == InvestmentStage.processing) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (store.stage != InvestmentStage.amount &&
        store.stage != InvestmentStage.success) {
      store.adjustAmount();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(InvestorRoutes.explore);
    }
  }

  Future<void> _authorize(BuildContext context) async {
    store.authorize();
    final success = await showInvestorAuthorization(
      context,
      authorize: (pin, {simulateBiometric = false}) async {
        if (await store.confirm(pin, simulateBiometric: simulateBiometric)) {
          return InvestorAuthorizationOutcome.success;
        }
        return store.stage == InvestmentStage.authorizing
            ? InvestorAuthorizationOutcome.retryPin
            : InvestorAuthorizationOutcome.failed;
      },
      error: () => store.error,
      processingTitle: 'Processing your\ninvestment',
      processingMessage:
          'Allocating simulated funds to this project. No real money is moved.',
    );
    if (!context.mounted) return;
    if (success == null) {
      store.cancelAuthorization();
      return;
    }
    final choice = await showInvestorResult(
      context,
      success: success,
      title: success ? 'You’re an investor!' : 'Couldn’t complete',
      message: success
          ? '${Money.amount(store.amount!, decimals: false)} invested in ${store.project!.name} in this demo. View your portfolio for updates.'
          : store.error ?? 'Please try again.',
      primary: success ? 'View my portfolio' : 'Top up wallet',
      secondary: success ? 'Find another project' : 'Adjust amount',
    );
    if (!context.mounted) return;
    if (success) {
      context.goNamed(
        choice == 'secondary'
            ? InvestorRoutes.explore
            : InvestorRoutes.portfolio,
      );
    } else {
      store.adjustAmount();
      if (choice == 'primary') await context.pushNamed(InvestorRoutes.addMoney);
    }
  }
}

class _InvestmentDetailRow extends StatelessWidget {
  const _InvestmentDetailRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6.w),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.text(
              14,
              weight: FontWeight.w500,
              color: AppColors.muted,
              height: 26 / 14,
              letterSpacing: -.28,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.text(
              16,
              weight: FontWeight.w600,
              color: AppColors.gray900,
              height: 26 / 16,
              letterSpacing: -.32,
            ),
          ),
        ),
      ],
    ),
  );
}
