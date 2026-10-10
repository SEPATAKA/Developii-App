import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_fields.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_form_panel.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_tax_components.dart';

class NaturalTaxForm extends StatelessWidget {
  const NaturalTaxForm({super.key, required this.store});
  final KycStore store;

  Future<void> _open(
    BuildContext context,
    KycTaxSection section, {
    String? id,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await context.pushNamed<bool>(
      InvestorRoutes.kycTax,
      pathParameters: {'section': section.name},
      queryParameters: {'residency': ?id},
    );
    if (context.mounted && !store.isDisposed) {
      await store.load(requestedStep: 'tax');
    }
  }

  Widget _field(BuildContext context, String key) => KycField(
    grouped: true,
    showChoiceIndicator: false,
    definition: KycTaxPlan.fields.firstWhere((field) => field.key == key),
    value: store.draft!.values[key] ?? '',
    error: store.errors[key],
    enabled: !store.busy,
    onLabelTap: key == 'secondaryTax' && store.draft!.values[key] == 'true'
        ? () => _open(context, KycTaxSection.residency)
        : null,
    onChanged: (value) {
      store.edit(key, value);
      if (key == 'secondaryTax' && value == 'true') {
        _open(context, KycTaxSection.residency);
      }
    },
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'TAX RESIDENCY',
        style: AppTextStyles.text(14, weight: FontWeight.w500, height: 22 / 14),
      ),
      SizedBox(height: 8.w),
      KycFormPanel(
        spacing: 21,
        children: [
          _field(context, 'taxCountry'),
          Column(
            children: [
              _field(context, 'tin'),
              SizedBox(height: 9.w),
              _field(context, 'secondaryTax'),
            ],
          ),
        ],
      ),
      if (store.draft!.values['secondaryTax'] == 'true' &&
          store.draft!.taxResidencies.isNotEmpty) ...[
        for (final residency in store.draft!.taxResidencies)
          Padding(
            padding: EdgeInsets.only(top: 12.w),
            child: KycTaxChoice(
              label: residency.country,
              subtitle: 'TIN ${residency.tin}',
              selected: false,
              onTap: store.busy
                  ? null
                  : () => _open(
                      context,
                      KycTaxSection.residency,
                      id: residency.id,
                    ),
            ),
          ),
        TextButton(
          onPressed: store.busy
              ? null
              : () => _open(context, KycTaxSection.residency),
          child: Text(
            'Add another residency',
            style: AppTextStyles.text(14, color: AppColors.primary),
          ),
        ),
      ],
      SizedBox(height: 17.w),
      const KycTaxNotice(
        text:
            'A PEP is anyone holding prominent public functions (head of state, minister, judge, senior military, central bank official) – or a close family member or associate of one.',
      ),
      SizedBox(height: 17.w),
      KycTaxFieldRow(
        gap: 13,
        children: [
          KycTaxChoice(
            label: 'No I’m not a PEP',
            centered: true,
            selected: store.draft!.values['pep'] == KycTaxPlan.pepNo,
            onTap: store.busy
                ? null
                : () => store.edit('pep', KycTaxPlan.pepNo),
          ),
          KycTaxChoice(
            label: KycTaxPlan.pepYes,
            centered: true,
            selected: store.draft!.values['pep'] == KycTaxPlan.pepYes,
            onTap: store.busy
                ? null
                : () {
                    store.edit('pep', KycTaxPlan.pepYes);
                    _open(context, KycTaxSection.pep);
                  },
          ),
        ],
      ),
      if (store.errors['pep'] case final error?) InlineError(error),
      SizedBox(height: 17.w),
      KycTaxDeclarations(store: store),
    ],
  );
}
