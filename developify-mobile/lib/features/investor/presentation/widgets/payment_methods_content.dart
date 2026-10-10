import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/stores/payment_methods_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/payment_card_preview.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/payment_method_options.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/payment_method_row.dart';

class PaymentMethodsContent extends StatelessWidget {
  const PaymentMethodsContent({
    super.key,
    required this.store,
    required this.kind,
    required this.onAdd,
    required this.onChange,
    required this.onSelect,
    this.select = false,
    this.manage = false,
  });
  final PaymentMethodsStore store;
  final PaymentMethodKind kind;
  final VoidCallback onAdd;
  final VoidCallback onChange;
  final ValueChanged<String> onSelect;
  final bool select;
  final bool manage;

  @override
  Widget build(BuildContext context) =>
      Observer(builder: (_) => _content(context));

  Widget _content(BuildContext context) {
    if ((store.status == LoadStatus.initial ||
            store.status == LoadStatus.loading) &&
        store.methods.isEmpty) {
      return const LoadingView();
    }
    if (store.status == LoadStatus.error && store.methods.isEmpty) {
      return ErrorView(
        message: store.error ?? 'Unable to load payment methods.',
        onRetry: store.load,
      );
    }
    final methods = store.methods.where((item) => item.kind == kind).toList();
    final card = kind == PaymentMethodKind.card;
    if (methods.isEmpty) {
      return _EmptyMethods(
        card: card,
        select: select,
        onAdd: onAdd,
        onRefresh: store.load,
      );
    }
    final featured =
        methods.where((item) => item.isDefault).firstOrNull ?? methods.first;
    return RefreshIndicator(
      onRefresh: store.load,
      child: ListView(
        key: PageStorageKey('payment-methods-${kind.name}-$select-$manage'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: (card ? 19 : 14).w),
          if (store.error != null) InlineError(store.error),
          if (card && !select && !manage) ...[
            PaymentCardPreview(method: featured),
            SizedBox(height: 19.w),
            PaymentMethodRow(
              method: featured,
              onPressed: onChange,
              change: true,
            ),
            SizedBox(height: 37.w),
          ] else ...[
            for (final method in methods) ...[
              PaymentMethodRow(
                method: method,
                onPressed: store.saving
                    ? null
                    : () {
                        if (select) {
                          onSelect(method.id);
                        } else {
                          showPaymentMethodOptions(
                            context,
                            store: store,
                            methodId: method.id,
                          );
                        }
                      },
                selecting: select,
                selected: !select && method.isDefault,
                onSelect: select
                    ? () => onSelect(method.id)
                    : card
                    ? null
                    : () => store.setDefault(method.id, true),
              ),
              SizedBox(height: 19.w),
            ],
            SizedBox(height: 5.w),
          ],
          if (!manage)
            AppButton(
              label: card
                  ? select
                        ? 'Add card'
                        : 'Add payment method'
                  : 'Add a new bank account',
              style: AppButtonStyle.secondary,
              onPressed: onAdd,
            ),
          SizedBox(height: 24.w),
        ],
      ),
    );
  }
}

class _EmptyMethods extends StatelessWidget {
  const _EmptyMethods({
    required this.card,
    required this.select,
    required this.onAdd,
    required this.onRefresh,
  });
  final bool card;
  final bool select;
  final VoidCallback onAdd;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.only(
              bottom:
                  (card
                          ? select
                                ? 30
                                : 27
                          : 34)
                      .w,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card ? 'No Cards Added Yet' : 'No Bank Account Added',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    16,
                    weight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.gray900,
                  ),
                ),
                SizedBox(height: (card ? 12 : 8).w),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: (card ? 17 : 55).w),
                  child: Text(
                    card
                        ? "You haven't added any cards yet. Add a card to start making payments and managing your transactions."
                        : 'No bank account has been linked to your account. Add one to get started.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.text(
                      card ? 16 : 14,
                      height: card ? 1.2 : 1.4,
                      letterSpacing: card ? 0 : -.28,
                      color: card
                          ? AppColors.muted
                          : AppColors.investorBankEmptyHint,
                    ),
                  ),
                ),
                SizedBox(
                  height:
                      (card
                              ? select
                                    ? 35
                                    : 19
                              : 33)
                          .w,
                ),
                AppButton(
                  label: card ? 'Add card' : 'Add bank account',
                  style: AppButtonStyle.secondary,
                  onPressed: onAdd,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
