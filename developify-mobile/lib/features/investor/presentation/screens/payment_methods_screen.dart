import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/app_switch.dart';
import 'package:developify_mobile/core/widgets/sheets.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/payment_methods_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_confirmation_sheet.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/payment_methods_content.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({
    super.key,
    required this.store,
    this.form,
    this.select = false,
    this.filter,
    this.manage = false,
  });
  final PaymentMethodsStore store;
  final PaymentMethodKind? form;
  final bool select;
  final PaymentMethodKind? filter;
  final bool manage;
  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) => PopScope(canPop: !store.saving, child: _page(context)),
  );

  Widget _page(BuildContext context) {
    final card = form == PaymentMethodKind.card;
    return InvestorPage(
      onBack: store.saving ? () {} : null,
      headerLeadingInset: form == null && !select ? 19 : null,
      headerTopInset: form == null && !select ? 13 : null,
      titleCenterOffset: card
          ? 9
          : form != null
          ? 0
          : filter == PaymentMethodKind.bankAccount
          ? -1
          : select
          ? 8
          : -6,
      title: form == null
          ? filter == PaymentMethodKind.bankAccount
                ? 'Bank Details'
                : select
                ? 'Pay with Card'
                : 'Payment Methods'
          : card
          ? 'Add New Card'
          : 'Add Bank Account',
      bottom: form == null
          ? null
          : Observer(
              builder: (_) => Padding(
                padding: EdgeInsets.only(bottom: card ? 23.w : 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (store.error != null) ...[
                      InlineError(store.error),
                      SizedBox(height: 8.w),
                    ],
                    AppButton(
                      label: card ? 'Add Card' : 'Save Bank Account',
                      loading: store.saving,
                      onPressed:
                          (card ? store.cardComplete : store.bankComplete)
                          ? () => _save(context)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
      child: form == null
          ? _methods(context)
          : Observer(
              builder: (_) {
                return ListView(
                  key: ValueKey(store.formRevision),
                  children: [
                    SizedBox(height: card ? 29.w : 20.w),
                    if (!card) ...[
                      _select(context, 'bank', 'Bank', [
                        'Standard Bank',
                        'ABSA',
                        'FNB',
                        'Nedbank',
                        'Capitec',
                        'Access Bank',
                      ]),
                      SizedBox(height: 20.w),
                    ],
                    _field(
                      'holder',
                      card ? 'Card Holder' : 'Account Name',
                      'Enter Full Name',
                    ),
                    SizedBox(height: 20.w),
                    _field(
                      'number',
                      card ? 'Card Number' : 'Account Number',
                      card
                          ? 'Enter the 16 digit number'
                          : 'Enter account number',
                      keyboard: TextInputType.number,
                    ),
                    SizedBox(height: 20.w),
                    if (card)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              'expiry',
                              'Expiry',
                              'MM / YY',
                              keyboard: TextInputType.datetime,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: _field(
                              'cvv',
                              'CVV',
                              'XXX',
                              keyboard: TextInputType.number,
                              obscure: true,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _select(context, 'type', 'Account Type', [
                        'Savings',
                        'Current',
                        'Cheque',
                        'Business',
                      ]),
                      SizedBox(height: 20.w),
                      _field(
                        'branch',
                        'Branch Code',
                        'Enter Code',
                        keyboard: TextInputType.number,
                      ),
                    ],
                    SizedBox(height: 26.w),
                    if (card) ...[
                      Semantics(
                        toggled: store.values['save'] == 'true',
                        label: 'Save card for future payments',
                        hint: 'You can remove it anytime from settings',
                        excludeSemantics: true,
                        onTap: () => store.edit(
                          'save',
                          '${store.values['save'] != 'true'}',
                        ),
                        child: InkWell(
                          onTap: () => store.edit(
                            'save',
                            '${store.values['save'] != 'true'}',
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                          child: InvestorSurface(
                            color: AppColors.mint,
                            border: AppColors.mint,
                            radius: 10,
                            padding: EdgeInsets.fromLTRB(
                              10.w,
                              15.w,
                              16.w,
                              20.w,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Save card for future payments',
                                        style: AppTextStyles.text(
                                          16,
                                          weight: FontWeight.w600,
                                          color: AppColors.gray900,
                                        ),
                                      ),
                                      SizedBox(height: 3.w),
                                      Text(
                                        'You can remove it anytime from settings',
                                        style: AppTextStyles.text(
                                          14,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppSwitch(
                                  activeColor: AppColors.investorLink,
                                  value: store.values['save'] == 'true',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.w),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppIcon(AppAssets.investorCardLock, size: 24),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              'Demo only. Use test card details. No card is charged or linked to a bank.',
                              style: AppTextStyles.text(
                                14,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 24.w),
                  ],
                );
              },
            ),
    );
  }

  Widget _methods(BuildContext context) => PaymentMethodsContent(
    store: store,
    kind: filter ?? PaymentMethodKind.card,
    select: select,
    manage: manage,
    onAdd: () => _add(
      context,
      filter == PaymentMethodKind.bankAccount
          ? InvestorRoutes.addBank
          : InvestorRoutes.addCard,
    ),
    onChange: () => _add(context, InvestorRoutes.manageCards),
    onSelect: (id) {
      if (context.canPop()) {
        context.pop(id);
      } else {
        context.goNamed(InvestorRoutes.wallet);
      }
    },
  );

  Widget _field(
    String key,
    String label,
    String hint, {
    TextInputType? keyboard,
    bool obscure = false,
  }) => AppField(
    label: label,
    hint: hint,
    value: store.values[key] ?? '',
    onChanged: (value) => store.edit(key, value),
    error: store.errors[key],
    keyboardType: keyboard,
    obscure: obscure,
    textInputAction: TextInputAction.next,
  );
  Widget _select(
    BuildContext context,
    String key,
    String label,
    List<String> options,
  ) => AppSelect(
    label: label,
    hint: 'Select $label',
    value: store.values[key] ?? '',
    error: store.errors[key],
    onTap: () async {
      final value = await showChoiceSheet<String>(
        context,
        title: label,
        choices: {for (final option in options) option: option},
        selected: store.values[key],
      );
      if (value != null) store.edit(key, value);
    },
  );
  Future<void> _save(BuildContext context) async {
    if (!await store.save(form!)) return;
    if (!context.mounted) return;
    final choice = await showInvestorResult(
      context,
      success: true,
      style: form == PaymentMethodKind.card
          ? select
                ? InvestorResultStyle.paymentCardSelection
                : InvestorResultStyle.paymentCard
          : InvestorResultStyle.investment,
      title: form == PaymentMethodKind.card
          ? 'Card Added'
          : 'Bank Account Added',
      message: form == PaymentMethodKind.card
          ? 'Your test card has been added. You can now use it for simulated payments.'
          : 'Your bank account is ready for simulated withdrawals.',
      primary: 'Done',
      secondary: 'Add another',
    );
    if (context.mounted && choice != 'secondary') {
      context.pop(store.lastSavedId);
    }
  }

  Future<void> _add(BuildContext context, String route) async {
    final id = await context.pushNamed<String>(
      route,
      queryParameters: select ? const {'select': 'true'} : const {},
    );
    if (context.mounted && select && id != null) context.pop(id);
  }
}
