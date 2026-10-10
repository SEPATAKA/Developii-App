import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_drafts.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/transfer_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_amount_field.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_confirmation_sheet.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/empty_payment_methods.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/deposit_account_details.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/transfer_summary.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/withdrawal_amount_form.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/withdrawal_review.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({
    super.key,
    required this.store,
    this.returnProjectId,
    this.returnAmountCents,
  });
  final TransferStore store;
  final String? returnProjectId;
  final String? returnAmountCents;
  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) => PopScope<Object?>(
      canPop:
          widget.store.account == null ||
          widget.store.stage == TransferStage.success ||
          widget.store.stage == TransferStage.method ||
          (widget.store.kind == InvestorTransferKind.withdrawal &&
              widget.store.stage == TransferStage.amount),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _page(context),
    ),
  );

  Widget _page(BuildContext context) {
    final store = widget.store;
    final withdrawal = store.kind == InvestorTransferKind.withdrawal;
    if (store.account == null) {
      return InvestorPage(
        title: withdrawal ? 'Withdrawal' : 'Add funds',
        onBack: _back,
        child: store.status == LoadStatus.error
            ? ErrorView(
                message: store.error ?? 'Unable to load payment methods.',
                onRetry: () => store.load(store.kind),
              )
            : const LoadingView(),
      );
    }
    if (store.stage == TransferStage.bankDetails) {
      return InvestorPage(
        title: 'Bank Transfer',
        onBack: _back,
        bottom: AppButton(
          label: 'Continue',
          onPressed: () {
            store.chooseKind(PaymentMethodKind.bankAccount);
          },
        ),
        child: ListView(
          key: const ValueKey('transfer-bank-details'),
          children: [
            SizedBox(height: 18.w),
            Text(
              'Demo account details. Continue below to simulate a bank transfer.',
              style: AppTextStyles.body,
            ),
            SizedBox(height: 14.w),
            const DepositAccountDetails(),
            SizedBox(height: 24.w),
          ],
        ),
      );
    }
    if (store.stage == TransferStage.method) {
      return InvestorPage(
        title: 'Add funds',
        onBack: _back,
        child: ListView(
          key: const ValueKey('transfer-payment-type'),
          children: [
            SizedBox(height: 18.w),
            Text('How will you pay?', style: AppTextStyles.heading),
            SizedBox(height: 17.w),
            Text(
              'Easily add funds to your account and keep your balance ready for everyday transactions.',
              style: AppTextStyles.body,
            ),
            SizedBox(height: 18.w),
            InvestorMenuRow(
              icon: AppAssets.investorTransferCard,
              radius: 12,
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.w),
              iconGap: 16,
              subtitleGap: 4,
              title: 'Debit Card',
              titleSize: 16,
              subtitleSize: 14,
              subtitleColor: AppColors.iconMuted,
              subtitleWeight: FontWeight.w500,
              badge: Container(
                constraints: BoxConstraints(minWidth: 91.w),
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.w),
                decoration: BoxDecoration(
                  color: AppColors.mintBorder,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Most popular',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    11,
                    color: AppColors.mintText,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              subtitle: 'Instant • 1.5% fee',
              trailing: const AppIcon(AppAssets.profileMenuChevron),
              onTap: () => store.chooseKind(PaymentMethodKind.card),
            ),
            SizedBox(height: 19.w),
            InvestorMenuRow(
              icon: AppAssets.investorBank,
              iconGap: 16,
              radius: 12,
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 16.w),
              subtitleGap: 4,
              title: 'Bank Transfer',
              titleSize: 16,
              subtitleSize: 14,
              subtitleColor: AppColors.iconMuted,
              subtitleWeight: FontWeight.w500,
              subtitle: 'Instant • No Fee',
              trailing: const AppIcon(AppAssets.profileMenuChevron),
              onTap: store.showBankDetails,
            ),
          ],
        ),
      );
    }
    final reviewing = store.stage != TransferStage.amount;
    final amount = store.amount ?? const MonetaryAmount(0, Currency.zar);
    final method = store.method;
    if (!store.methods.any((method) => method.kind == store.paymentKind) &&
        store.stage == TransferStage.amount) {
      return InvestorPage(
        title: withdrawal ? 'Withdraw' : 'Pay with Card',
        onBack: _back,
        child: EmptyPaymentMethods(withdrawal: withdrawal, onAdd: _addMethod),
      );
    }
    final bankDeposit =
        !withdrawal && method?.kind == PaymentMethodKind.bankAccount;
    final methodTitle = method == null
        ? 'No payment method'
        : '${method.name} • ****** ${method.lastFour}';
    return InvestorPage(
      footerBottomInset: withdrawal ? 9 : 18,
      title: reviewing
          ? withdrawal
                ? 'Confirm Withdrawal'
                : 'Confirm Top- Up'
          : withdrawal
          ? 'Withdraw'
          : bankDeposit
          ? 'Bank Transfer'
          : 'Pay with Card',
      onBack: _back,
      bottom: AppButton(
        label: reviewing
            ? withdrawal
                  ? 'Authorize with PIN'
                  : 'Confirm Payment'
            : withdrawal
            ? 'Withdraw'
            : 'Continue',
        loading: store.stage == TransferStage.processing,
        onPressed: reviewing
            ? _authorize
            : store.validAmount && method != null
            ? () => store.review()
            : null,
      ),
      child: ListView(
        key: ValueKey(reviewing ? 'transfer-review' : 'transfer-amount'),
        children: [
          SizedBox(
            height: withdrawal
                ? reviewing
                      ? 21.w
                      : store.amountText.isEmpty
                      ? 36.w
                      : 38.w
                : reviewing
                ? 45.w
                : 39.w,
          ),
          if (withdrawal)
            reviewing
                ? WithdrawalReview(
                    amount: amount,
                    fee: store.fee,
                    received: store.received,
                    method: method,
                  )
                : WithdrawalAmountForm(store: store, onAdd: _addMethod)
          else if (!reviewing) ...[
            InvestorAmountField(
              value: store.amountText,
              onChanged: store.editAmount,
              error: store.inputError,
              fontSize: 61,
              fontWeight: FontWeight.w600,
              labelGap: 8,
            ),
            SizedBox(height: 86.w),
            InvestorAmountPresets(
              values: const [500, 1000, 2000, 5000],
              onSelected: store.editAmount,
              selectedValue: store.amountText,
            ),
            SizedBox(height: 24.w),
            InvestorMenuRow(
              icon: method!.kind == PaymentMethodKind.card
                  ? AppAssets.investorTransferCard
                  : AppAssets.investorBank,
              iconColor: AppColors.investorPaymentIcon,
              titleSize: 16,
              subtitleSize: 14,
              subtitleColor: AppColors.iconMuted,
              subtitleWeight: FontWeight.w500,
              subtitleGap: 4,
              radius: 12,
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 16.w),
              title: methodTitle,
              subtitle: method.expiry.isEmpty
                  ? method.holder
                  : 'Default • expires ${method.expiry}',
              trailing: Text(
                'Change',
                style: AppTextStyles.text(
                  16,
                  weight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              onTap: bankDeposit ? store.showBankDetails : _selectMethod,
            ),
            SizedBox(height: 15.w),
            TransferFees(
              amount: amount,
              fee: store.fee,
              bankDeposit: bankDeposit,
            ),
          ] else
            TransferReview(amount: amount, fee: store.fee, method: method),
          if (store.error != null) InlineError(store.error),
          SizedBox(height: 24.w),
        ],
      ),
    );
  }

  void _back() {
    final store = widget.store;
    if (store.stage == TransferStage.processing) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (store.stage == TransferStage.bankDetails) {
      store.leaveBankDetails();
    } else if (store.stage == TransferStage.review ||
        store.stage == TransferStage.authorizing ||
        store.stage == TransferStage.failure) {
      store.adjustAmount();
    } else if (store.account != null &&
        store.kind == InvestorTransferKind.topUp &&
        store.stage == TransferStage.amount) {
      store.showPaymentTypes();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(InvestorRoutes.wallet);
    }
  }

  Future<void> _selectMethod() async {
    final id = await context.pushNamed<String>(
      InvestorRoutes.paymentMethods,
      queryParameters: {
        'select': 'true',
        'kind': widget.store.kind == InvestorTransferKind.withdrawal
            ? 'bankAccount'
            : 'card',
      },
    );
    if (mounted && id != null) {
      await widget.store.refreshMethods();
      if (mounted) widget.store.selectMethod(id);
    }
  }

  Future<void> _addMethod() async {
    final id = await context.pushNamed<String>(
      widget.store.kind == InvestorTransferKind.withdrawal
          ? InvestorRoutes.addBank
          : InvestorRoutes.addCard,
      queryParameters: const {'select': 'true'},
    );
    if (mounted && id != null) {
      await widget.store.refreshMethods();
      if (mounted) widget.store.selectMethod(id);
    }
  }

  Future<void> _authorize() async {
    final store = widget.store;
    final withdrawal = store.kind == InvestorTransferKind.withdrawal;
    final destination = store.method;
    store.authorize();
    final success = await showInvestorAuthorization(
      context,
      processingTitle: withdrawal
          ? 'Recording withdrawal'
          : 'Processing your request',
      processingMessage: withdrawal
          ? 'Please wait while we record this simulated withdrawal.'
          : 'Please wait while we confirm this simulation.',
      processingBottomSpacing: withdrawal ? 106 : 39,
      authorize: (pin, {simulateBiometric = false}) async {
        if (await store.confirm(pin, simulateBiometric: simulateBiometric)) {
          return InvestorAuthorizationOutcome.success;
        }
        return store.stage == TransferStage.authorizing
            ? InvestorAuthorizationOutcome.retryPin
            : InvestorAuthorizationOutcome.failed;
      },
      error: () => store.error,
    );
    if (!mounted) return;
    if (success == null) {
      store.cancelAuthorization();
      return;
    }
    final receiptId = store.receipt?.transactionId;
    final choice = await showInvestorResult(
      context,
      success: success,
      style: success
          ? withdrawal
                ? InvestorResultStyle.withdrawal
                : InvestorResultStyle.topUp
          : InvestorResultStyle.investment,
      title: success
          ? withdrawal
                ? 'Withdrawal Sent'
                : 'Top - up Successful'
          : 'Couldn’t complete',
      message: success
          ? withdrawal
                ? '${Money.amount(store.received)} simulated withdrawal to ${destination?.name ?? 'the selected bank'}${destination == null ? '' : ' • ${destination.lastFour}'}. No money was moved.'
                : '${Money.amount(store.amount!)} added to your demo wallet.'
          : store.error ?? 'Please try again.',
      primary: success
          ? withdrawal
                ? 'Back to Wallet'
                : widget.returnProjectId != null
                ? 'Return to investment'
                : 'Find a project to invest in'
          : 'Try again',
      secondary: success
          ? withdrawal
                ? 'View Receipt'
                : 'Back to Wallet'
          : null,
    );
    if (!mounted) return;
    if (success) {
      if (withdrawal && choice == 'secondary' && receiptId != null) {
        context.pushReplacementNamed(
          InvestorRoutes.transaction,
          pathParameters: {'id': receiptId},
        );
        return;
      }
      if (!withdrawal &&
          choice == 'primary' &&
          widget.returnProjectId != null) {
        context.goNamed(
          InvestorRoutes.invest,
          pathParameters: {'id': widget.returnProjectId!},
          queryParameters: {
            if (widget.returnAmountCents != null)
              'amountCents': widget.returnAmountCents!,
          },
        );
        return;
      }
      context.goNamed(
        !withdrawal && choice == 'primary'
            ? InvestorRoutes.explore
            : InvestorRoutes.wallet,
      );
    } else {
      store.adjustAmount();
    }
  }
}
