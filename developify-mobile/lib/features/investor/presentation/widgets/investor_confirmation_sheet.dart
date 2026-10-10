import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

enum InvestorAuthorizationOutcome { success, retryPin, failed }

Future<bool?> showInvestorAuthorization(
  BuildContext context, {
  required Future<InvestorAuthorizationOutcome> Function(
    String, {
    bool simulateBiometric,
  })
  authorize,
  required String? Function() error,
  String processingTitle = 'Processing your request',
  String processingMessage = 'Please wait while we confirm this simulation.',
  double processingBottomSpacing = 39,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  barrierColor: AppColors.modalScrim,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
  ),
  builder: (_) => _AuthorizationSheet(
    authorize: authorize,
    error: error,
    processingTitle: processingTitle,
    processingMessage: processingMessage,
    processingBottomSpacing: processingBottomSpacing,
  ),
);

class _AuthorizationSheet extends StatefulWidget {
  const _AuthorizationSheet({
    required this.authorize,
    required this.error,
    required this.processingTitle,
    required this.processingMessage,
    required this.processingBottomSpacing,
  });
  final Future<InvestorAuthorizationOutcome> Function(
    String, {
    bool simulateBiometric,
  })
  authorize;
  final String? Function() error;
  final String processingTitle;
  final String processingMessage;
  final double processingBottomSpacing;
  @override
  State<_AuthorizationSheet> createState() => _AuthorizationSheetState();
}

class _AuthorizationSheetState extends State<_AuthorizationSheet> {
  String _pin = '';
  bool _usePin = false;
  bool _busy = false;
  String? _error;
  Future<void> _submit(String pin, {bool simulateBiometric = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.authorize(
      pin,
      simulateBiometric: simulateBiometric,
    );
    if (!mounted) return;
    if (result != InvestorAuthorizationOutcome.retryPin) {
      Navigator.pop(context, result == InvestorAuthorizationOutcome.success);
      return;
    }
    setState(() {
      _busy = false;
      _pin = '';
      _error = widget.error();
    });
  }

  void _digit(String value) {
    if (_busy || _pin.length >= 4) return;
    setState(() => _pin += value);
    if (_pin.length == 4) _submit(_pin);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AuthorizationClose(
              height: _busy ? 88 : 100.7,
              onPressed: _busy ? null : () => Navigator.pop(context),
              label: 'Cancel authorization',
            ),
            if (_busy) ...[
              Container(
                width: 72.w,
                height: 72.w,
                padding: EdgeInsets.all(20.w),
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 4.w,
                  backgroundColor: AppColors.mintBorder,
                  value: MediaQuery.disableAnimationsOf(context) ? .75 : null,
                  semanticsLabel: 'Confirming simulation',
                ),
              ),
              SizedBox(height: 40.w),
            ],
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 35.w),
              child: Text(
                _busy
                    ? widget.processingTitle
                    : _usePin
                    ? 'Enter PIN'
                    : 'Authorize Payment',
                textAlign: TextAlign.center,
                style: AppTextStyles.text(
                  29.33,
                  weight: FontWeight.w700,
                  height: 35 / 29.33,
                ),
              ),
            ),
            SizedBox(height: 8.w),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 43.w),
              child: Text(
                _busy
                    ? widget.processingMessage
                    : _usePin
                    ? 'This confirms the payment and keeps your account secure.'
                    : 'Confirm your identity with Touch ID to continue.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ),
            if (_error != null)
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 12.w, 24.w, 0),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(14, color: AppColors.error),
                ),
              ),
            if (_busy)
              SizedBox(height: widget.processingBottomSpacing.w)
            else if (!_usePin) ...[
              SizedBox(height: 39.w),
              Semantics(
                button: true,
                label: 'Simulate Touch ID authorization',
                child: InkWell(
                  onTap: () => _submit('', simulateBiometric: true),
                  borderRadius: BorderRadius.circular(56.r),
                  child: const AppIcon(
                    AppAssets.investorAuthorizationBiometric,
                    size: 112,
                  ),
                ),
              ),
              SizedBox(height: 45.w),
              SizedBox(
                height: 56.w,
                child: TextButton(
                  onPressed: () => setState(() => _usePin = true),
                  child: Text(
                    'Use PIN Instead',
                    style: AppTextStyles.text(
                      18,
                      color: AppColors.primary,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(height: 56.w),
              Semantics(
                label: 'PIN',
                value: '${_pin.length} of 4 digits entered',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 4; i++)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Container(
                            width: 15.r,
                            height: 15.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < _pin.length
                                  ? AppColors.primary
                                  : AppColors.neutralTrack,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 62.w),
              _PinPad(
                onDigit: _digit,
                onBiometric: () => setState(() => _usePin = false),
                onDelete: () {
                  if (_pin.isNotEmpty) {
                    setState(() => _pin = _pin.substring(0, _pin.length - 1));
                  }
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _AuthorizationClose extends StatelessWidget {
  const _AuthorizationClose({
    required this.height,
    required this.onPressed,
    this.label = 'Close',
    this.rightInset = 15.6,
  });
  final double height;
  final VoidCallback? onPressed;
  final String label;
  final double rightInset;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height.w,
    child: Stack(
      children: [
        Positioned(
          top: 32.3.w,
          right: rightInset.w,
          child: InvestorIconButton(
            asset: AppAssets.investorModalClose,
            size: 32.26,
            label: label,
            onPressed: onPressed,
          ),
        ),
      ],
    ),
  );
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.onDigit,
    required this.onBiometric,
    required this.onDelete,
  });
  final ValueChanged<String> onDigit;
  final VoidCallback onBiometric;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.slate100,
    child: Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Row(
              children: [
                for (var column = 0; column < 3; column++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: SizedBox(
                        height:
                            (MediaQuery.textScalerOf(context).scale(36.sp) +
                                    8.w)
                                .clamp(56.w, double.infinity),
                        child: TextButton(
                          onPressed: row < 3
                              ? () => onDigit('${row * 3 + column + 1}')
                              : column == 0
                              ? onBiometric
                              : column == 1
                              ? () => onDigit('0')
                              : onDelete,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              side: const BorderSide(color: AppColors.slate200),
                            ),
                          ),
                          child: row == 3 && column != 1
                              ? AppIcon(
                                  column == 0
                                      ? AppAssets.investorPinBiometric
                                      : AppAssets.investorPinDelete,
                                  semanticLabel: column == 0
                                      ? 'Use biometrics'
                                      : 'Delete PIN digit',
                                )
                              : Text(
                                  row == 3 ? '0' : '${row * 3 + column + 1}',
                                  style: AppTextStyles.text(
                                    24,
                                    weight: FontWeight.w600,
                                    color: AppColors.mutedSlate,
                                    height: 1.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    ),
  );
}

enum InvestorResultStyle {
  verification,
  investment,
  topUp,
  withdrawal,
  paymentCard,
  paymentCardSelection,
}

class _ResultGeometry {
  const _ResultGeometry({
    this.header = 78,
    this.icon = 96,
    this.iconGap = 27,
    this.messageHeight = 38,
    this.messageInset = 33,
    this.actionGap = 56,
    this.bottom = 0,
    this.horizontalInset = 10,
    this.titleSize = 29.33,
    this.buttonSize = 16,
  });
  final double header;
  final double icon;
  final double iconGap;
  final double messageHeight;
  final double messageInset;
  final double actionGap;
  final double bottom;
  final double horizontalInset;
  final double titleSize;
  final double buttonSize;
}

Future<String?> showInvestorResult(
  BuildContext context, {
  required bool success,
  required String title,
  required String message,
  required String primary,
  String? secondary,
  InvestorResultStyle style = InvestorResultStyle.investment,
}) {
  final geometry = switch (style) {
    InvestorResultStyle.verification => const _ResultGeometry(
      header: 78,
      icon: 88,
      iconGap: 20,
      messageHeight: 57,
      messageInset: 21.5,
      actionGap: 40.134,
      bottom: 5.134,
      horizontalInset: 12,
      titleSize: 29.32836,
    ),
    InvestorResultStyle.investment => const _ResultGeometry(),
    InvestorResultStyle.topUp => const _ResultGeometry(
      header: 112,
      icon: 88,
      iconGap: 45,
      messageHeight: 19,
      actionGap: 36,
      bottom: 4.13,
    ),
    InvestorResultStyle.withdrawal => const _ResultGeometry(
      header: 65,
      icon: 88,
      messageInset: 11.5,
      actionGap: 35,
      bottom: 4.13,
    ),
    InvestorResultStyle.paymentCard => const _ResultGeometry(
      header: 135,
      icon: 107.6115,
      iconGap: 36.2055,
      messageInset: 22.125,
      actionGap: 45,
      bottom: 22.283,
      horizontalInset: 20,
      titleSize: 29.496,
      buttonSize: 15.7861,
    ),
    InvestorResultStyle.paymentCardSelection => const _ResultGeometry(
      header: 97,
      icon: 88,
      iconGap: 20,
      messageInset: 33.5,
      actionGap: 60,
      bottom: 10.134,
      titleSize: 29.3284,
    ),
  };
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: AppColors.modalScrim,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: geometry.horizontalInset.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AuthorizationClose(
                height: geometry.header,
                rightInset: style == InvestorResultStyle.paymentCard
                    ? -4.362
                    : 5.6,
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(
                height: geometry.icon.w,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AppIcon(
                    success
                        ? style == InvestorResultStyle.paymentCardSelection
                              ? AppAssets.investorCardLinked
                              : style == InvestorResultStyle.paymentCard
                              ? AppAssets.investorCardAdded
                              : style == InvestorResultStyle.investment
                              ? AppAssets.investorSuccess
                              : AppAssets.investorTransferSuccess
                        : AppAssets.investorFailureBadge,
                    size: success ? geometry.icon : 82.52,
                  ),
                ),
              ),
              SizedBox(height: geometry.iconGap.w),
              Text(
                title,
                style: AppTextStyles.text(
                  geometry.titleSize,
                  weight: FontWeight.w700,
                  height: 35 / geometry.titleSize,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.w),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: geometry.messageInset.w,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: geometry.messageHeight.w,
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                ),
              ),
              SizedBox(height: geometry.actionGap.w),
              AppButton(
                label: primary,
                labelSize: geometry.buttonSize,
                onPressed: () => Navigator.pop(context, 'primary'),
              ),
              if (secondary != null) ...[
                SizedBox(height: 12.w),
                AppButton(
                  label: secondary,
                  labelSize: geometry.buttonSize,
                  style: AppButtonStyle.secondary,
                  onPressed: () => Navigator.pop(context, 'secondary'),
                ),
              ],
              SizedBox(height: geometry.bottom.w),
            ],
          ),
        ),
      ),
    ),
  );
}
