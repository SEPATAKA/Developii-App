import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class DepositAccountDetails extends StatefulWidget {
  const DepositAccountDetails({super.key});
  @override
  State<DepositAccountDetails> createState() => _DepositAccountDetailsState();
}

class _DepositAccountDetailsState extends State<DepositAccountDetails> {
  String? _feedback;
  bool _failed = false;
  @override
  Widget build(BuildContext context) => InvestorSurface(
    radius: 12,
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detail('Bank', InvestorDepositAccount.method.name),
        SizedBox(height: 24.w),
        Row(
          children: [
            Expanded(
              child: _detail(
                'Account number',
                InvestorDepositAccount.formattedNumber,
              ),
            ),
            SizedBox(
              width: 44,
              height: 40.w,
              child: OverflowBox(
                minHeight: 44,
                maxHeight: 44,
                child: InvestorIconButton(
                  asset: AppAssets.investorCopy,
                  label: 'Copy demo account number',
                  onPressed: _copy,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.w),
        _detail('Account name', InvestorDepositAccount.method.holder),
        SizedBox(height: 24.w),
        _detail('Unique ID', InvestorDepositAccount.reference),
        if (_feedback != null) ...[
          SizedBox(height: 12.w),
          Semantics(
            liveRegion: true,
            child: Text(
              _feedback!,
              style: AppTextStyles.text(
                12,
                color: _failed ? AppColors.error : AppColors.mintText,
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _detail(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.text(
          14,
          color: AppColors.iconMuted,
          weight: FontWeight.w500,
        ),
      ),
      SizedBox(height: 4.w),
      Text(value, style: AppTextStyles.text(16, weight: FontWeight.w600)),
    ],
  );

  Future<void> _copy() async {
    try {
      await Clipboard.setData(
        const ClipboardData(text: InvestorDepositAccount.number),
      );
      if (mounted) {
        setState(() {
          _failed = false;
          _feedback = 'Copied demo account number.';
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          _failed = true;
          _feedback = 'Unable to copy. Please try again.';
        });
      }
    }
  }
}
