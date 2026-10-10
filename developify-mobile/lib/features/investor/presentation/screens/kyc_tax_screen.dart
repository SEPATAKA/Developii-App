import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_tax_details_form.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_result_sheet.dart';

class KycTaxScreen extends StatelessWidget {
  const KycTaxScreen({
    super.key,
    required this.store,
    required this.section,
    this.residencyId,
  });
  final KycStore store;
  final KycTaxSection section;
  final String? residencyId;

  Future<void> _load() async {
    await store.load(requestedStep: 'tax');
    if (!store.isDisposed && section == KycTaxSection.residency) {
      store.beginTaxResidency(residencyId);
    }
  }

  void _finish(BuildContext context, bool saved) {
    if (store.busy || !store.saveAndExit()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (context.canPop()) {
      context.pop(saved);
    } else {
      context.goNamed(
        InvestorRoutes.kyc,
        pathParameters: {'entity': 'individual', 'step': 'tax'},
      );
    }
  }

  Future<void> _submit(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!store.saveTaxSection(section)) return;
    if (section == KycTaxSection.wealth) {
      await showKycProgressSheet(context);
      if (!context.mounted) return;
    }
    if (section == KycTaxSection.pep) {
      final complete = await context.pushNamed<bool>(
        InvestorRoutes.kycTax,
        pathParameters: {'section': 'wealth'},
      );
      if (!context.mounted || store.isDisposed) return;
      await _load();
      if (!context.mounted || complete != true) return;
    }
    if (context.mounted) _finish(context, true);
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final title = section == KycTaxSection.residency
          ? 'Second Tax residency'
          : 'PEP Details';
      if (store.status == LoadStatus.initial ||
          store.status == LoadStatus.loading) {
        return InvestorPage(
          title: title,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      if (store.status == LoadStatus.error || store.draft == null) {
        return InvestorPage(
          title: title,
          child: ErrorView(
            message: store.error ?? 'Unable to load these details.',
            onRetry: _load,
          ),
        );
      }
      return PopScope(
        canPop: !store.busy,
        child: InvestorPage(
          title: title,
          headerLeadingInset: 22,
          onBack: () => _finish(context, false),
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label:
                    section == KycTaxSection.wealth &&
                        store.draft!.documents.containsKey(
                          KycTaxPlan.wealthDocument.key,
                        )
                    ? 'Continue'
                    : 'Save & Continue',
                loading: store.busy,
                onPressed: store.canSaveTaxSection(section)
                    ? () => _submit(context)
                    : null,
              ),
              if (section != KycTaxSection.wealth) ...[
                SizedBox(height: 19.w),
                AppButton(
                  label: 'Cancel',
                  style: AppButtonStyle.secondary,
                  onPressed: store.busy ? null : () => _finish(context, false),
                ),
              ],
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: 14.w, bottom: 28.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KycTaxDetailsForm(store: store, section: section),
                  if (store.error != null) InlineError(store.error),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
