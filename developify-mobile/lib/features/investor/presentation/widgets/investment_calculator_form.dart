import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_amount_field.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class InvestmentCalculatorForm extends StatelessWidget {
  const InvestmentCalculatorForm({
    super.key,
    required this.project,
    required this.amountText,
    required this.amount,
    required this.projectedPayout,
    required this.onChanged,
    this.error,
  });

  final InvestorProject project;
  final String amountText;
  final MonetaryAmount amount;
  final MonetaryAmount projectedPayout;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final filled = amountText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InvestorSurface(
          color: AppColors.white,
          border: AppColors.border,
          radius: 11,
          padding: EdgeInsets.fromLTRB(
            13.w,
            (filled ? 37 : 34).w,
            13.w,
            24.4.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InvestorAmountField(
                value: amountText,
                onChanged: onChanged,
                currency: amount.currency,
                error: error,
                fontSize: filled ? 40 : 36,
                fontWeight: FontWeight.w600,
                valueColor: AppColors.gray900,
                centered: false,
                groupDigits: true,
              ),
              SizedBox(height: (filled ? 21.2 : 29).w),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Terms',
                      style: AppTextStyles.text(14, weight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${project.durationMonths} months',
                    style: AppTextStyles.text(
                      14,
                      weight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.w),
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill.r),
                  child: SizedBox(
                    height: 8.8601.w,
                    child: ColoredBox(
                      color: AppColors.borderStrong,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FractionallySizedBox(
                          widthFactor: 235.6788 / 342,
                          heightFactor: 1,
                          child: const ColoredBox(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.w),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ROI ( project rate )',
                      style: AppTextStyles.text(14, weight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${project.annualReturnBasisPoints / 100}%',
                    style: AppTextStyles.text(
                      12,
                      weight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 17.w),
        Text(
          'Results',
          style: AppTextStyles.text(
            14,
            weight: FontWeight.w600,
            height: 26 / 14,
            letterSpacing: -.28,
          ),
        ),
        SizedBox(height: 11.w),
        InvestorSurface(
          border: AppColors.border,
          radius: 8,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.5.w),
          child: Column(
            children: [
              _CalculatorResultRow(
                'Monthly Distribution',
                project.supportsProjection
                    ? _distributionLabel()
                    : 'Schedule unavailable',
              ),
              SizedBox(height: 7.w),
              _CalculatorResultRow(
                'Total Earning',
                project.supportsProjection
                    ? Money.amount(projectedPayout - amount)
                    : 'Unavailable',
                valueColor: AppColors.primary,
              ),
              SizedBox(height: 7.w),
              _CalculatorResultRow(
                'Payout at maturity',
                project.supportsProjection
                    ? Money.amount(projectedPayout)
                    : 'Unavailable',
                labelColor: AppColors.gray900,
                valueColor: AppColors.primary,
              ),
            ],
          ),
        ),
        if (project.supportsProjection &&
            project.projection(amount).payments.first !=
                project.projection(amount).payments.last) ...[
          SizedBox(height: 10.w),
          Text(
            _scheduleDetail(),
            style: AppTextStyles.text(14, color: AppColors.muted, height: 1.4),
          ),
        ],
        SizedBox(height: 16.w),
        Text(
          InvestmentPolicy.calculatorDisclaimer,
          style: AppTextStyles.text(14, color: AppColors.muted, height: 1.4),
        ),
      ],
    );
  }

  String _scheduleDetail() {
    final payments = project.projection(amount).payments;
    final count = payments.where((p) => p == payments.first).length;
    return '$count payments of ${Money.amount(payments.first)} and ${payments.length - count} of ${Money.amount(payments.last)}.';
  }

  String _distributionLabel() {
    final projection = project.projection(amount);
    final payments = projection.payments;
    final count = payments.where((p) => p == payments.first).length;
    if (count == payments.length) {
      return '${Money.amount(payments.first)} × ${payments.length}';
    }
    return '${Money.amount(payments.last)}–${Money.amount(payments.first)} × ${payments.length}';
  }
}

class _CalculatorResultRow extends StatelessWidget {
  const _CalculatorResultRow(
    this.label,
    this.value, {
    this.labelColor = AppColors.muted,
    this.valueColor = AppColors.gray900,
  });
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTextStyles.text(
            14,
            weight: FontWeight.w500,
            color: labelColor,
            height: 26 / 14,
            letterSpacing: -.28,
          ),
        ),
      ),
      SizedBox(width: 10.w),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: AppTextStyles.text(
            16,
            weight: FontWeight.w600,
            color: valueColor,
            height: 26 / 16,
            letterSpacing: -.32,
          ),
        ),
      ),
    ],
  );
}
