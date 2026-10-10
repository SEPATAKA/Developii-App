import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/phone_number_field.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_member_plan.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_member_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_fields.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_form_panel.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class KycInviteForm extends StatelessWidget {
  const KycInviteForm({super.key, required this.store});
  final KycMemberStore store;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Send a signing link to the ${store.draft!.role.label.toLowerCase()}’s email.',
        style: AppTextStyles.text(16, color: AppColors.muted),
      ),
      SizedBox(height: 27.w),
      _heading('1. Who are you sending to?'),
      KycFormPanel(
        spacing: 22,
        children: [
          _field(
            const KycFieldDefinition(
              'email',
              'Email Address',
              hint: 'Enter email address',
              kind: KycFieldKind.email,
            ),
          ),
          _phone(),
        ],
      ),
      if (store.entity == EntityType.trust) ...[
        SizedBox(height: 20.w),
        _heading('2. What to attach'),
        for (final (index, entry)
            in KycMemberPlan.inviteAttachments.entries.indexed) ...[
          if (index > 0) SizedBox(height: 16.w),
          _attachment(entry.key, entry.value),
        ],
        if (store.errors['attachments'] case final error?) InlineError(error),
      ],
      SizedBox(height: 20.w),
      _heading(
        '${store.entity == EntityType.trust ? 3 : 2}. Personal message (Optional)',
      ),
      KycFormPanel(
        children: [
          _field(
            const KycFieldDefinition(
              'message',
              'Add a note for the email you input above',
              hint: 'Type a message...',
              kind: KycFieldKind.multiline,
              required: false,
            ),
            lines: 11,
          ),
        ],
      ),
      SizedBox(height: 20.w),
      _heading('${store.entity == EntityType.trust ? 4 : 3}. Sending Options'),
      KycFormPanel(
        spacing: 10,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
        children: [
          _option(
            'sms',
            'Send SMS with link too',
            'Backup if the email lands in spam',
          ),
          const Divider(height: 1, color: AppColors.borderStrong),
          _option(
            'reminders',
            'Auto-remind every 3 days',
            'Up to 3 reminders every 3 days',
          ),
          const Divider(height: 1, color: AppColors.borderStrong),
          _option(
            'opened',
            'Notify me when they open it',
            'Push notifications + in-app alert',
          ),
        ],
      ),
      SizedBox(height: 18.w),
      InvestorSurface(
        color: AppColors.mint,
        border: AppColors.mint,
        padding: EdgeInsets.all(14.w),
        child: Text(
          'Simulated invitation. No email, SMS or WhatsApp message will be sent.',
          style: AppTextStyles.text(14, color: AppColors.mintText),
        ),
      ),
    ],
  );

  Widget _heading(String text) => Padding(
    padding: EdgeInsets.only(left: 5.w, bottom: 14.w),
    child: Text(text, style: AppTextStyles.text(14, weight: FontWeight.w500)),
  );
  Widget _phone() {
    final phone = store.values['phone'] ?? '';
    final countries = PhoneNumberField.countries;
    final previous = countries
        .where((country) => phone.startsWith(country.$2))
        .firstOrNull;
    final country =
        countries
            .where((country) => country.$1 == store.values['phoneCountry'])
            .firstOrNull ??
        previous ??
        countries[1];
    final national = previous == null
        ? phone
        : phone.substring(previous.$2.length).trimLeft();
    return PhoneNumberField(
      key: const ValueKey('invite-phone'),
      label: 'Mobile number (optional)',
      hint: 'Enter phone number',
      fillColor: AppColors.border,
      hintColor: AppColors.muted,
      hintWeight: FontWeight.w400,
      value: national,
      countryCode: country.$1,
      enabled: store.editable && !store.busy,
      error: store.errors['phone'],
      onChanged: (value) => store.edit(
        'phone',
        value.trim().isEmpty ? '' : '${country.$2} ${value.trim()}',
      ),
      onCountryChanged: (code, dial) {
        store.edit('phoneCountry', code);
        store.edit('phone', national.isEmpty ? '' : '$dial $national');
      },
    );
  }

  Widget _field(
    KycFieldDefinition field, {
    int lines = 3,
    String? toggleSubtitle,
  }) => KycField(
    key: ValueKey('invite-${field.key}'),
    definition: field,
    value: store.values[field.key] ?? '',
    grouped: true,
    multilineLines: lines,
    toggleSubtitle: toggleSubtitle,
    enabled: store.editable && !store.busy,
    error: store.errors[field.key],
    onChanged: (value) => store.edit(field.key, value),
  );
  Widget _option(String key, String label, String hint) => _field(
    KycFieldDefinition(key, label, kind: KycFieldKind.toggle, required: false),
    toggleSubtitle: hint,
  );
  Widget _attachment(String key, (String, String, bool) value) {
    final selected = store.values['attach-$key'] == 'true';
    return Semantics(
      checked: selected,
      enabled: store.editable && !store.busy,
      child: InkWell(
        onTap: store.editable && !store.busy
            ? () => store.edit('attach-$key', '${!selected}')
            : null,
        borderRadius: BorderRadius.circular(10.r),
        child: InvestorSurface(
          radius: 10,
          border: AppColors.border,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.w),
          child: Row(
            children: [
              SizedBox(
                width: 32.w,
                height: 32.w,
                child: Center(
                  child: AppIcon(
                    selected
                        ? AppAssets.investorCheckboxChecked
                        : AppAssets.investorCheckboxUnchecked,
                    size: selected ? 32 : 20,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.$1,
                      style: AppTextStyles.text(14, weight: FontWeight.w600),
                    ),
                    SizedBox(height: 8.w),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.w,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 5.w,
                          ),
                          decoration: BoxDecoration(
                            color: value.$3
                                ? AppColors.errorSurface
                                : AppColors.borderStrong,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Text(
                            value.$3 ? 'Required' : 'Optional',
                            style: AppTextStyles.text(
                              12,
                              color: value.$3
                                  ? AppColors.error
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                        if (value.$2.isNotEmpty)
                          Text(
                            value.$2,
                            style: AppTextStyles.text(
                              14,
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KycInvitePreview extends StatelessWidget {
  const KycInvitePreview({super.key, required this.store});
  final KycMemberStore store;
  @override
  Widget build(BuildContext context) {
    final trust = store.entity == EntityType.trust;
    final name = store.values['firstName']?.trim() ?? '';
    final fullName = [
      name,
      store.values['lastName'] ?? '',
    ].where((value) => value.isNotEmpty).join(' ');
    final founder = store.application!.values['founderName']?.trim() ?? '';
    final entityName =
        store.application!.values[trust
            ? 'trustName'
            : store.entity == EntityType.company
            ? 'companyName'
            : 'stokvelName'] ??
        (trust
            ? 'the Trust'
            : store.entity == EntityType.company
            ? 'the Company'
            : 'the Stokvel');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          name.isEmpty
              ? 'What the recipient sees in their inbox.'
              : 'What $name sees in their inbox.',
          style: AppTextStyles.text(14, color: AppColors.muted),
        ),
        SizedBox(height: 14.w),
        InvestorSurface(
          color: AppColors.white,
          radius: 16,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 13.5.w,
                ),
                decoration: BoxDecoration(
                  color: AppColors.investorCard,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  children: [
                    for (final color in [
                      AppColors.investorMailRed,
                      AppColors.investorMailYellow,
                      AppColors.investorMailGreen,
                    ]) ...[
                      Container(
                        width: 10.5.w,
                        height: 10.5.w,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.3.w),
                    ],
                    SizedBox(width: 4.w),
                    Text(
                      'Mail · Inbox',
                      style: AppTextStyles.text(
                        9.45,
                        weight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 7.w, 14.w, 14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _mailHeader(
                      'FROM',
                      trust
                          ? 'Developify Trust <trust@developify.com>'
                          : 'Developify',
                    ),
                    _mailHeader(
                      'TO',
                      fullName.isEmpty
                          ? store.invitation.email
                          : '$fullName <${store.invitation.email}>',
                    ),
                    _mailHeader(
                      'SUBJECT',
                      'Please sign your ${store.draft!.role.label} Appointment',
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10.w, 10.w, 10.w, 14.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: const Center(
                              child: AppIcon(AppAssets.brandSymbol, size: 22),
                            ),
                          ),
                          SizedBox(height: 14.w),
                          Text(
                            'Welcome to ${entityName.startsWith('the ') ? entityName : 'the $entityName'}',
                            style: AppTextStyles.text(
                              14,
                              weight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 24.w),
                          Text(
                            name.isEmpty ? 'Hello,' : 'Hi $name,',
                            style: AppTextStyles.text(12),
                          ),
                          SizedBox(height: 6.w),
                          Text(
                            trust && founder.isNotEmpty
                                ? '$founder has appointed you as co-trustee and asked us to send the paperwork.'
                                : 'You have been invited to complete the ${store.draft!.role.label.toLowerCase()} paperwork.',
                            style: AppTextStyles.text(
                              12,
                              color: AppColors.muted,
                            ),
                          ),
                          if (store.invitation.message.isNotEmpty) ...[
                            SizedBox(height: 15.w),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 14.w,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.mint,
                                border: Border(
                                  left: BorderSide(
                                    color: AppColors.primary,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Text(
                                store.invitation.message,
                                style: AppTextStyles.text(
                                  10,
                                  height: 1.4,
                                  color: AppColors.mintText,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 9.w),
                          Center(
                            child: Text(
                              'Preview only · No signing link has been issued',
                              style: AppTextStyles.text(
                                9,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.w),
                          if (store.invitation.attachments.isNotEmpty) ...[
                            Text(
                              'ATTACHED',
                              style: AppTextStyles.text(
                                9,
                                color: AppColors.muted,
                                letterSpacing: .5,
                              ),
                            ),
                            for (final key in store.invitation.attachments) ...[
                              SizedBox(height: 12.w),
                              InvestorSurface(
                                border: AppColors.investorCard,
                                radius: 8,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 10.w,
                                ),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      AppAssets.investorInviteDocument,
                                      width: 14.w,
                                      height: 14.w,
                                      filterQuality: FilterQuality.high,
                                    ),
                                    SizedBox(width: 17.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            key == 'trustDeed'
                                                ? '$entityName Deed'
                                                : KycMemberPlan
                                                      .inviteAttachments[key]!
                                                      .$1,
                                            style: AppTextStyles.text(
                                              10,
                                              weight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 4.w),
                                          Text(
                                            key == 'appointment'
                                                ? 'for signing'
                                                : 'for supporting',
                                            style: AppTextStyles.text(
                                              10,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                          SizedBox(height: 26.w),
                          Text(
                            'This is a simulated invitation preview. No message has been sent.',
                            style: AppTextStyles.text(
                              12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mailHeader(String label, String value) => Padding(
    padding: EdgeInsets.only(bottom: 18.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.text(
            10,
            weight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        SizedBox(height: 1.w),
        Text(
          value,
          style: AppTextStyles.text(
            12,
            weight: label == 'TO' ? FontWeight.w400 : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
