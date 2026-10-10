import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/password_strength_meter.dart';
import 'package:developify_mobile/core/widgets/password_visibility_button.dart';
import 'package:developify_mobile/core/widgets/phone_number_field.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_signup_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/signup_security_content.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class SignupDetails extends StatelessWidget {
  const SignupDetails({super.key, required this.store});
  final InvestorSignupStore store;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final company = store.entity == EntityType.company;
      final fieldsGap = company ? 23.w : 21.w;
      final passwordInvalid =
          store.errors.containsKey('password') ||
          store.errors.containsKey('confirmation');
      return AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 26.w),
            const SignupHeading(title: 'Create Profile'),
            SizedBox(height: 7.w),
            Text(
              'We’ll use this to set up your ${company ? 'company' : 'investor'} profile.',
              style: AppTextStyles.text(
                16,
                color: AppColors.muted,
                height: 19 / 16,
              ),
            ),
            SizedBox(
              height: (company && store.representatives.length > 1 ? 26 : 19).w,
            ),
            if (company) ...[
              AppField(
                label: 'Registration Number',
                hint: 'Enter Reg Number',
                value: store.values['registration'],
                error: store.errors['registration'],
                readOnly: store.busy,
                onChanged: (value) => store.edit('registration', value),
              ),
              SizedBox(height: fieldsGap),
            ],
            AppField(
              label: company ? 'Company Name' : 'Full Name',
              hint: company ? 'Enter Company Name' : 'Enter Full Name',
              value: store.values['name'],
              error: store.errors['name'],
              readOnly: store.busy,
              autofillHints: const [AutofillHints.name],
              onChanged: (value) => store.edit('name', value),
            ),
            SizedBox(height: fieldsGap),
            AppField(
              label: company ? 'Company Email Address' : 'Email Address',
              hint: 'e.g Thomashook@gmail.com',
              value: store.values['email'],
              error: store.errors['email'],
              readOnly: store.busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: (value) => store.edit('email', value),
            ),
            SizedBox(height: fieldsGap),
            PhoneNumberField(
              label: company ? 'Company Phone Number' : 'Phone Number',
              value: store.values['phone'] ?? '',
              countryCode: store.countryCode,
              countryTrailingGap: 4,
              error: store.errors['phone'],
              enabled: !store.busy,
              onChanged: (value) => store.edit('phone', value),
              onCountryChanged: store.setCountry,
            ),
            SizedBox(
              height: company
                  ? (store.representatives.length > 1 ? 6 : 11).w
                  : fieldsGap,
            ),
            if (company) ...[
              for (var index = 0; index < store.representatives.length; index++)
                _RepresentativeRow(
                  key: ValueKey(
                    'representative-$index-${store.representatives.length}',
                  ),
                  store: store,
                  index: index,
                ),
              InlineError(store.errors['representatives']),
            ],
            AppField(
              label: 'Password',
              hint: 'Min. of 8 characters',
              value: store.values['password'],
              error: store.errors['password'],
              invalid: passwordInvalid,
              errorColor: AppColors.rose600,
              fillColor: passwordInvalid
                  ? AppColors.rose100
                  : AppColors.surface,
              readOnly: store.busy,
              obscure: !store.passwordVisible,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (value) => store.edit('password', value),
              suffix: PasswordVisibilityButton(
                visible: store.passwordVisible,
                solid: true,
                color: passwordInvalid ? AppColors.errorDark : null,
                onPressed: store.togglePassword,
              ),
            ),
            SizedBox(height: fieldsGap),
            AppField(
              label: 'Confirm Password',
              hint: 'Min. of 8 characters',
              value: store.values['confirmation'],
              error: store.errors['confirmation'],
              invalid: passwordInvalid,
              errorColor: AppColors.rose600,
              fillColor: passwordInvalid
                  ? AppColors.rose100
                  : AppColors.surface,
              readOnly: store.busy,
              obscure: !store.confirmationVisible,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onChanged: (value) => store.edit('confirmation', value),
              suffix: PasswordVisibilityButton(
                visible: store.confirmationVisible,
                solid: true,
                color: passwordInvalid ? AppColors.errorDark : null,
                onPressed: store.toggleConfirmation,
              ),
            ),
            SizedBox(height: 14.w),
            SizedBox(
              width: 360.w,
              child: PasswordStrengthMeter(
                filledSegments: store.passwordStrength,
                invalid: passwordInvalid,
                activeColor: AppColors.successBright,
                labelColor: AppColors.placeholder,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _RepresentativeRow extends StatelessWidget {
  const _RepresentativeRow({
    super.key,
    required this.store,
    required this.index,
  });
  final InvestorSignupStore store;
  final int index;

  @override
  Widget build(BuildContext context) {
    final representative = store.representatives[index];
    final canDelete =
        representative.name.isNotEmpty ||
        representative.identityNumber.isNotEmpty ||
        store.representatives.length > 1;
    final fields = [
      Semantics(
        label: 'Representative ${index + 1} name',
        child: AppField(
          key: ValueKey('representative-name-$index'),
          label: '',
          hint: 'Representative Name',
          value: representative.name,
          fillColor: AppColors.white,
          borderColor: AppColors.borderStrong,
          readOnly: store.busy,
          onChanged: (value) => store.updateRepresentative(index, name: value),
        ),
      ),
      Semantics(
        label: 'Representative ${index + 1} ID',
        child: AppField(
          key: ValueKey('representative-id-$index'),
          label: '',
          hint: 'ID',
          value: representative.identityNumber,
          fillColor: AppColors.white,
          borderColor: AppColors.borderStrong,
          readOnly: store.busy,
          onChanged: (value) =>
              store.updateRepresentative(index, identityNumber: value),
        ),
      ),
    ];
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            (index < store.representatives.length - 1
                    ? 6
                    : store.representatives.length > 1
                    ? 23
                    : 14)
                .w,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  index == 0 ? 'Representative' : 'Representative ${index + 1}',
                  style: AppTextStyles.label,
                ),
              ),
              if (canDelete)
                TextButton(
                  style: _actionStyle,
                  onPressed: store.busy
                      ? null
                      : () => store.removeRepresentative(index),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(
                        AppAssets.investorRepresentativeDelete,
                        size: 16,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Delete',
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w500,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              if (index == store.representatives.length - 1 &&
                  store.representatives.length < 20)
                TextButton(
                  style: _actionStyle,
                  onPressed: store.busy ? null : store.addRepresentative,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(
                        AppAssets.investorRepresentativeAdd,
                        size: 16,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Add',
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Container(
            padding: EdgeInsets.fromLTRB(10.w, 11.w, 16.w, 10.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10.w),
            ),
            child: MediaQuery.textScalerOf(context).scale(14.sp) > 20.sp
                ? Column(
                    children: [
                      fields[0],
                      SizedBox(height: 12.w),
                      fields[1],
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: fields[0]),
                      SizedBox(width: 15.w),
                      Expanded(child: fields[1]),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  ButtonStyle get _actionStyle => TextButton.styleFrom(
    minimumSize: const Size(44, 44),
    padding: EdgeInsets.symmetric(horizontal: 8.w),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}
