import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/sheets.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/payout_notice.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/payout_proof_control.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/payout_success_sheet.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/payout_selection_sheet.dart';
import 'package:developify_mobile/features/profile/presentation/stores/payout_store.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key, required this.store});
  final PayoutStore store;
  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  bool _allowPop = false;
  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (widget.store.dirty && !await confirmExit(context)) return;
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(Routes.payout);
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!await widget.store.submit() || !mounted) return;
    setState(() => _allowPop = true);
    await showPayoutSuccessSheet(context);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Routes.payout);
    }
  }

  Future<void> _select(bool bank) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final value = await showPayoutSelectionSheet(
      context,
      bank: bank,
      selected: bank ? widget.store.bank : widget.store.type,
    );
    if (mounted && value != null) {
      if (bank) {
        widget.store.setBank(value);
      } else {
        widget.store.setType(value);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final store = widget.store;
      return PopScope(
        canPop: !store.dirty || _allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_back());
        },
        child: AppPage(
          title: 'New Payouts',
          headerLeadingInset: 19,
          headerTopInset: 13,
          titleCenterOffset: 12,
          onBack: _back,
          child: ListView(
            padding: EdgeInsets.only(
              top: 17.w,
              bottom: (store.proofAttached ? 29 : 12).w,
            ),
            children: [
              const PayoutNotice(
                message:
                    'The account must be in your own name —\u00a0Themba Nkosi. Third-party accounts cannot be used for payouts under FICA.',
              ),
              SizedBox(height: 18.w),
              AppSelect(
                label: 'Bank',
                value: store.bank,
                hint: 'Select Bank',
                fillColor: AppColors.border,
                hintColor: AppColors.muted,
                error: store.errors['bank'],
                onTap: () => _select(true),
              ),
              SizedBox(height: 18.w),
              AppField(
                label: 'Account Number',
                hint: 'Enter Account Number',
                value: store.number,
                fillColor: AppColors.border,
                hintColor: AppColors.muted,
                textColor: AppColors.gray900,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(20),
                ],
                onChanged: store.setNumber,
                error: store.errors['number'],
              ),
              SizedBox(height: 18.w),
              AppSelect(
                label: 'Account Type',
                value: store.type,
                hint: 'Select Accout Type',
                fillColor: AppColors.border,
                hintColor: AppColors.muted,
                error: store.errors['type'],
                onTap: () => _select(false),
              ),
              SizedBox(height: 18.w),
              AppField(
                label: 'Branch Code',
                hint: 'Enter Branch Code',
                value: store.branch,
                fillColor: AppColors.border,
                hintColor: AppColors.muted,
                textColor: AppColors.gray900,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: store.setBranch,
                error: store.errors['branch'],
              ),
              SizedBox(height: 18.w),
              PayoutProofControl(
                attached: store.proofAttached,
                onAttach: () => store.attachProof(true),
                onRemove: () => store.attachProof(false),
              ),
              if (store.errors['proof'] != null)
                InlineError(store.errors['proof']),
              SizedBox(height: 21.w),
              const PayoutNotice(
                verification: true,
                message:
                    'Verification typically completes within 1 business day. Your existing\naccount stay active until the new one is verified.',
              ),
              SizedBox(height: (store.proofAttached ? 66 : 64).w),
              InlineError(store.error),
              AppButton(
                label: 'Submit for verification',
                loading: store.status == LoadStatus.loading,
                onPressed: store.canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      );
    },
  );
}
