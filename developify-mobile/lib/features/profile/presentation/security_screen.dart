import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/password_visibility_button.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/profile_menu_row.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/security_device_card.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/security_success_sheet.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/transaction_pin_field.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/two_factor_methods.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/authenticator_code_formatter.dart';
import 'package:developify_mobile/core/widgets/app_switch.dart';
import 'package:developify_mobile/core/widgets/phone_number_field.dart';
import 'package:developify_mobile/features/profile/presentation/stores/security_store.dart';

enum SecurityPage {
  menu,
  password,
  pin,
  biometrics,
  devices,
  twoFactor,
  sms,
  authenticator,
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({
    super.key,
    required this.store,
    required this.page,
    this.onLogout,
    this.routePrefix = '',
  });
  final SecurityStore store;
  final SecurityPage page;
  final VoidCallback? onLogout;
  final String routePrefix;
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  SecurityStore get store => widget.store;
  bool get _investor => widget.routePrefix == 'investor-';
  final _visiblePasswordFields = <String>{};
  final _passwordControllers = <String, TextEditingController>{};
  String _phoneCountry = 'US';
  bool _pinCompleted = false;
  @override
  void initState() {
    super.initState();
    if (_investor && widget.page == SecurityPage.password) {
      _passwordControllers.addAll({
        'Current Password': TextEditingController(text: store.password),
        'New Password': TextEditingController(text: store.newPassword),
        'Confirm New Password': TextEditingController(text: store.confirmation),
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _passwordControllers.values) {
      controller.dispose();
    }
    store.dispose();
    super.dispose();
  }

  String get _title => switch (widget.page) {
    SecurityPage.menu => 'Security',
    SecurityPage.password => 'Change Password',
    SecurityPage.pin => 'Change Transaction PIN',
    SecurityPage.biometrics => 'Biometric Login',
    SecurityPage.devices => 'Devices & Sessions',
    SecurityPage.sms when _investor && store.stage > 0 => 'Verify Setup',
    SecurityPage.authenticator when !_investor && store.stage > 0 =>
      'Verify Setup',
    _ => 'Setup 2FA',
  };
  void _back() {
    if (store.status == LoadStatus.loading) return;
    if (store.stage > 0) {
      store.previousStage();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        '${widget.routePrefix}${widget.page == SecurityPage.menu ? Routes.profile : Routes.security}',
      );
    }
  }

  void _open(String route) {
    context.pushNamed('${widget.routePrefix}$route');
  }

  String get _action => switch (widget.page) {
    SecurityPage.password when _investor => 'change-password',
    SecurityPage.pin ||
    SecurityPage.password when store.stage == 0 => 'verify-password',
    SecurityPage.pin => 'change-pin',
    SecurityPage.password => 'change-password',
    SecurityPage.sms when store.stage == 0 => 'send-code',
    SecurityPage.authenticator when store.stage == 0 => 'link-authenticator',
    _ => 'verify-code',
  };

  Future<void> _continue() async {
    final action = _action;
    if (!await store.perform(action) || !mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (action == 'verify-password' ||
        action == 'send-code' ||
        action == 'link-authenticator') {
      store.nextStage();
      return;
    }
    if (_investor) {
      if (action == 'change-pin') {
        setState(() => _pinCompleted = true);
      }
      store.clearSensitive();
      for (final controller in _passwordControllers.values) {
        controller.clear();
      }
    }
    await showSecuritySuccessSheet(
      context,
      title: widget.page == SecurityPage.pin
          ? 'Pin Changed'
          : widget.page == SecurityPage.password
          ? 'Password Changed'
          : '2FA Enabled',
      message: _investor && widget.page == SecurityPage.password
          ? 'Your password has been updated successfully. Use your new password the next time you sign in.'
          : _investor && widget.page == SecurityPage.sms
          ? 'SMS verification is enabled for this demo. No SMS service is connected.'
          : _investor && widget.page == SecurityPage.authenticator
          ? 'Authenticator verification is enabled for this demo. No live account has been linked.'
          : widget.page == SecurityPage.pin
          ? 'Your pin has been updated successfully. Use your new pin to confirm transactions.'
          : widget.page == SecurityPage.password
          ? 'Your password has been updated successfully.'
          : 'Your account is now protected with Google Authenticator.',
    );
    if (mounted) context.goNamed('${widget.routePrefix}${Routes.security}');
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final hasButton = [
        SecurityPage.password,
        SecurityPage.pin,
        SecurityPage.sms,
        SecurityPage.authenticator,
      ].contains(widget.page);
      return PopScope(
        canPop: store.stage == 0 && store.status != LoadStatus.loading,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: AppPage(
          title: _title,
          onBack: _back,
          headerLeadingInset: 22,
          titleCenterOffset: !_investor
              ? 0
              : switch (widget.page) {
                  SecurityPage.password => -5,
                  SecurityPage.pin => -13,
                  SecurityPage.biometrics => 5.5,
                  SecurityPage.sms when store.stage > 0 => 6.5,
                  _ => 0,
                },
          bottom: hasButton
              ? Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        ((widget.page == SecurityPage.pin ||
                                    widget.page == SecurityPage.password)
                                ? 23
                                : widget.page == SecurityPage.sms &&
                                      store.stage == 0
                                ? 4
                                : 26)
                            .w,
                  ),
                  child: AppButton(
                    label: _investor && widget.page == SecurityPage.password
                        ? 'Update Password'
                        : widget.page == SecurityPage.sms && store.stage == 0
                        ? 'Send code'
                        : (widget.page == SecurityPage.sms ||
                              widget.page == SecurityPage.authenticator &&
                                  store.stage > 0)
                        ? 'Verify'
                        : 'Continue',
                    loading: store.status == LoadStatus.loading,
                    onPressed: store.canPerform(_action) ? _continue : null,
                  ),
                )
              : widget.page == SecurityPage.devices
              ? Transform.translate(
                  offset: Offset(_investor ? 5.w : 0, 0),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 5.w),
                    child: AppButton(
                      label: 'Sign out all sessions',
                      style: AppButtonStyle.danger,
                      onPressed: widget.onLogout,
                    ),
                  ),
                )
              : null,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: (switch (widget.page) {
                SecurityPage.menu => _investor ? 31.0 : 10.0,
                SecurityPage.devices => 15.0,
                SecurityPage.biometrics || SecurityPage.twoFactor => 24.0,
                SecurityPage.password when _investor => 24.0,
                SecurityPage.pin || SecurityPage.password => 22.0,
                _ => 14.0,
              }).w,
              bottom: 24.w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _body(),
                InlineError(store.codeRejected ? null : store.error),
              ],
            ),
          ),
        ),
      );
    },
  );
  Widget _gap([double height = 24]) => SizedBox(height: height.w);
  Widget _switch(bool value, VoidCallback onTap) => SizedBox(
    width: 32.w,
    height: 20.w,
    child: OverflowBox(
      maxWidth: 44,
      maxHeight: 44,
      child: Semantics(
        toggled: value,
        button: true,
        child: InkResponse(
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: AppSwitch(
                value: value,
                inactiveColor: _investor ? AppColors.gray300 : null,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _body() {
    switch (widget.page) {
      case SecurityPage.menu:
        return Column(
          children: [
            for (final item in [
              ('Biometric', AppAssets.securityBiometric, Routes.biometrics),
              ('Change Password', AppAssets.securityPassword, Routes.password),
              ('Change  Transaction PIN', AppAssets.securityPin, Routes.pin),
            ]) ...[
              ProfileMenuRow(
                title: item.$1,
                icon: item.$2,
                onTap: () => _open(item.$3),
              ),
              _gap(19),
            ],
            ProfileMenuRow(
              title: 'Setup 2FA',
              icon: AppAssets.securityTwoFactor,
              trailing: _switch(store.twoFactorEnabled, () {
                if (store.twoFactorEnabled) {
                  store.enableTwoFactor(false);
                } else {
                  _open(Routes.twoFactor);
                }
              }),
              onTap: () => _open(Routes.twoFactor),
            ),
            _gap(19),
            ProfileMenuRow(
              title: 'Devices and sessions',
              icon: AppAssets.securityDevices,
              onTap: () => _open(Routes.devices),
            ),
          ],
        );
      case SecurityPage.biometrics:
        return Column(
          children: [
            for (final item in store.biometrics.entries) ...[
              if (item.key != store.biometrics.keys.first) _gap(19),
              ProfileMenuRow(
                title: item.key,
                trailing: _switch(
                  item.value,
                  () => store.toggleBiometric(item.key, !item.value),
                ),
                onTap: () => store.toggleBiometric(item.key, !item.value),
              ),
            ],
          ],
        );
      case SecurityPage.devices:
        return Padding(
          padding: EdgeInsets.only(left: 5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _deviceHeading(' ACTIVE DEVICES', true),
              _gap(11),
              SecurityDeviceCard(
                current: true,
                expanded: store.expandedDevices.contains('current'),
                onToggle: () => store.toggleDevice('current'),
                onRemove: () {},
              ),
              _gap(27),
              _deviceHeading('PREVIOUS DEVICE', false),
              _gap(11),
              for (final id in store.previousDevices) ...[
                SecurityDeviceCard(
                  current: false,
                  expanded: store.expandedDevices.contains(id),
                  onToggle: () => store.toggleDevice(id),
                  onRemove: () => store.removeDevice(id),
                ),
                _gap(11),
              ],
            ],
          ),
        );
      case SecurityPage.twoFactor:
        return TwoFactorMethods(
          simulated: _investor,
          onSms: () =>
              context.pushNamed('${widget.routePrefix}${Routes.twoFactorSms}'),
          onAuthenticator: () =>
              context.pushNamed('${widget.routePrefix}${Routes.twoFactorApp}'),
        );
      case SecurityPage.pin || SecurityPage.password:
        if (_investor && widget.page == SecurityPage.password) {
          return _passwordForm();
        }
        if (store.stage == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Password',
                style: AppTextStyles.text(
                  28,
                  weight: FontWeight.w700,
                  color: AppColors.text,
                  height: 34 / 28,
                ),
              ),
              _gap(17),
              Text(
                'For security reasons, confirm your password first',
                style: AppTextStyles.body,
              ),
              _gap(30),
              AppField(
                label: 'Enter Current Password',
                hint: 'Min. of 8 characters',
                value: store.password,
                obscure: !store.visible,
                onChanged: store.setPassword,
                suffix: PasswordVisibilityButton(
                  visible: store.visible,
                  onPressed: store.toggleVisible,
                ),
              ),
            ],
          );
        }
        if (widget.page == SecurityPage.pin) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Transaction PIN',
                style: AppTextStyles.text(
                  28,
                  weight: FontWeight.w700,
                  color: AppColors.text,
                  height: 34 / 28,
                ),
              ),
              _gap(17),
              Text(
                _investor
                    ? 'You can use your pin to confirm transactions.\nEnsure that you do not share your pin with anyone'
                    : 'You can use your pin to confirm transactions. Ensure that you do not share your pin with anyone',
                style: AppTextStyles.body,
              ),
              _gap(32.5569),
              TransactionPinField(
                value: store.pin,
                completed: _pinCompleted,
                onChanged: store.setPin,
                onSubmitted: _continue,
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _gap(16),
            Text('Set a new password', style: AppTextStyles.heading),
            _gap(28),
            AppField(
              label: 'New Password',
              hint: 'Min. of 8 characters',
              value: store.newPassword,
              obscure: !store.visible,
              onChanged: store.setNewPassword,
              suffix: PasswordVisibilityButton(
                visible: store.visible,
                onPressed: store.toggleVisible,
              ),
            ),
            _gap(),
            AppField(
              label: 'Confirm Password',
              hint: 'Re-enter password',
              value: store.confirmation,
              obscure: !store.visible,
              onChanged: store.setConfirmation,
            ),
          ],
        );
      case SecurityPage.sms:
        if (store.stage == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _investor ? 'SMS Authentication' : 'SMS Authenticatoin',
                      style: AppTextStyles.text(
                        20,
                        weight: FontWeight.w600,
                        color: AppColors.black,
                        height: 24 / 20,
                      ),
                    ),
                    _gap(14),
                    Text(
                      _investor
                          ? 'Try SMS verification with a test phone number. No message is sent.'
                          : 'We’ll send a code via SMS when you sign in. password regularly.',
                      style: AppTextStyles.text(
                        16,
                        weight: FontWeight.w500,
                        color: AppColors.muted,
                        height: 19 / 16,
                      ),
                    ),
                  ],
                ),
              ),
              _gap(21),
              PhoneNumberField(
                value: store.phone,
                countryCode: _phoneCountry,
                onChanged: store.setPhone,
                onCountryChanged: (country, dial) =>
                    setState(() => _phoneCountry = country),
              ),
            ],
          );
        }
        return _verifyCode();
      case SecurityPage.authenticator:
        if (store.stage > 0) return _verifyCode();
        return Padding(
          padding: EdgeInsets.only(left: 8.w, right: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _investor
                    ? 'Try authenticator setup in this demo. This QR code does not link a live account.'
                    : 'Add a second layer of security with a code from your authenticator app',
                style: AppTextStyles.text(
                  16,
                  weight: FontWeight.w500,
                  color: AppColors.black,
                  height: 19 / 16,
                ),
              ),
              _gap(46),
              Center(
                child: Image.asset(
                  AppAssets.authenticatorQr,
                  width: 208.w,
                  height: 208.w,
                  semanticLabel: _investor
                      ? 'Sample authenticator setup QR code'
                      : 'Authenticator setup QR code',
                ),
              ),
              _gap(24),
              Center(
                child: Text(
                  'Or paste this key: A28K-XX19-7732',
                  style: AppTextStyles.text(
                    14,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                    height: 16 / 14,
                  ),
                ),
              ),
              _gap(25),
              Text(
                'ENTER THE 6-DIGIT CODE',
                style: AppTextStyles.text(
                  12,
                  weight: FontWeight.w500,
                  color: AppColors.muted,
                  height: 14 / 12,
                ).copyWith(letterSpacing: .6.sp),
              ),
              _gap(7),
              Padding(
                padding: EdgeInsets.only(right: 7.w),
                child: TextFormField(
                  key: const ValueKey('authenticator-setup-code'),
                  initialValue: store.code,
                  onChanged: store.setCode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _continue(),
                  inputFormatters: [const AuthenticatorCodeFormatter()],
                  style: AppTextStyles.text(
                    22,
                    weight: FontWeight.w700,
                    color: AppColors.gray900,
                    height: 26 / 22,
                  ).copyWith(letterSpacing: 4.sp),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: EdgeInsets.symmetric(vertical: 15.w),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.w),
                      borderSide: const BorderSide(
                        color: AppColors.borderStrong,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.w),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _passwordForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (index, label, value, onChanged) in [
        (0, 'Current Password', store.password, store.setPassword),
        (1, 'New Password', store.newPassword, store.setNewPassword),
        (2, 'Confirm New Password', store.confirmation, store.setConfirmation),
      ]) ...[
        if (index > 0) _gap(17),
        AppField(
          label: label,
          hint: 'Min. of 8 characters',
          value: value,
          controller: _passwordControllers[label],
          obscure: !_visiblePasswordFields.contains(label),
          onChanged: onChanged,
          error:
              index == 2 &&
                  store.confirmation.isNotEmpty &&
                  store.confirmation != store.newPassword
              ? 'Passwords do not match'
              : null,
          suffix: PasswordVisibilityButton(
            visible: _visiblePasswordFields.contains(label),
            onPressed: () => setState(() {
              if (!_visiblePasswordFields.remove(label)) {
                _visiblePasswordFields.add(label);
              }
            }),
          ),
        ),
      ],
      _gap(19),
      Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.emerald50,
          border: Border.all(color: AppColors.emerald100),
          borderRadius: BorderRadius.circular(14.w),
        ),
        child: Text(
          'For your protection, you’ll be logged out of other devices after changing your password.',
          style: AppTextStyles.text(
            13,
            weight: FontWeight.w500,
            color: AppColors.emerald900,
            height: 14 / 13,
          ),
        ),
      ),
    ],
  );

  Widget _verifyCode() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 6 digit code',
              style: AppTextStyles.text(
                20,
                weight: FontWeight.w600,
                color: AppColors.black,
                height: 24 / 20,
              ),
            ),
            _gap(14),
            if (_investor)
              Text(
                widget.page == SecurityPage.sms
                    ? 'Demo only. Enter 123456 to simulate SMS verification. No message is sent.'
                    : 'Demo only. Enter 123456 to simulate authenticator verification.',
                style: AppTextStyles.text(
                  16,
                  weight: FontWeight.w500,
                  color: AppColors.muted,
                  height: 19 / 16,
                ),
              )
            else if (widget.page == SecurityPage.sms)
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Open your '),
                    TextSpan(
                      text: 'Google Authenticator',
                      style: AppTextStyles.text(
                        16,
                        weight: FontWeight.w700,
                        color: AppColors.gray900,
                        height: 19 / 16,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ' app and enter the code generated for your account.',
                    ),
                  ],
                ),
                style: AppTextStyles.text(
                  16,
                  weight: FontWeight.w500,
                  color: AppColors.muted,
                  height: 19 / 16,
                ),
              )
            else
              Text(
                'We’ll send a code via SMS when you sign in. password regularly.',
                style: AppTextStyles.text(
                  16,
                  weight: FontWeight.w500,
                  color: AppColors.muted,
                  height: 19 / 16,
                ),
              ),
          ],
        ),
      ),
      _gap(38),
      Padding(
        padding: EdgeInsets.only(
          left:
              (_investor
                  ? widget.page == SecurityPage.sms
                  : widget.page == SecurityPage.authenticator)
              ? 8.w
              : 0,
        ),
        child: SizedBox(
          height: 55.245285.w,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: 367.w,
            minWidth: 367.w,
            child: CodeField(
              length: 6,
              value: store.code,
              onChanged: store.setCode,
              invalid: store.codeRejected,
              onSubmitted: _continue,
            ),
          ),
        ),
      ),
      _gap(47.254715),
      Padding(
        padding: EdgeInsets.only(
          left: (widget.page == SecurityPage.authenticator ? 109 : 107).w,
        ),
        child: SizedBox(
          height: 44.w,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: store.status == LoadStatus.loading
                ? null
                : () async {
                    if (await store.perform('resend-code')) {
                      store.setCode('');
                    }
                  },
            child: Text(
              'Didn’t receive a code?',
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w600,
                color: AppColors.cyanLink,
                height: 17 / 14,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _deviceHeading(String title, bool active) => Row(
    children: [
      Container(
        width: 9.w,
        height: 9.w,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.errorOrange,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(width: 6.w),
      Text(
        title,
        style: AppTextStyles.text(
          12,
          weight: FontWeight.w600,
          color: AppColors.text,
          height: 14 / 12,
        ).copyWith(letterSpacing: 2.sp),
      ),
    ],
  );
}
