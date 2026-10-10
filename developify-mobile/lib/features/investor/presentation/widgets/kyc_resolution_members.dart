import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/dashed_border.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_member_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class KycResolutionMembers extends StatelessWidget {
  const KycResolutionMembers({super.key, required this.store});
  final KycStore store;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final trust = store.entity == EntityType.trust;
      final members = store.members;
      final signed = members.where((member) => member.signed).length;
      final allSigned = members.isNotEmpty && signed == members.length;
      final requested = members.any(
        (member) =>
            member.resolutionSignature.status !=
            KycSignatureStatus.notRequested,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(
            trust
                ? 'All Serving Trustees'
                : 'Signed by $signed of ${members.length}',
            lineHeight: trust ? 17 : 22,
            bottom: trust ? 8 : 10,
          ),
          if (trust) ...[
            InvestorSurface(
              color: AppColors.emerald50,
              border: AppColors.mintBorder,
              radius: 14,
              padding: EdgeInsets.fromLTRB(14.w, 14.w, 19.w, 14.w),
              child: Text(
                'Trustees are taken from your Letters of Authority. In this demo, enter their names and ID numbers manually and check them against the resolution.',
                style: AppTextStyles.text(
                  13,
                  color: AppColors.mintText,
                  height: 14 / 13,
                ),
              ),
            ),
            SizedBox(height: 16.w),
          ],
          for (final member in members.where(
            (member) =>
                trust ||
                member.resolutionSignature.status !=
                    KycSignatureStatus.notRequested,
          )) ...[
            _SignatureCard(
              member: member,
              enabled: !store.busy,
              editable: store.editable,
              onPreview: () => _preview(context, member.id),
              onRequest: () => store.requestSignatures(memberId: member.id),
            ),
            SizedBox(height: (trust ? 14 : 10).w),
          ],
          if (!trust || members.isEmpty) ...[
            CustomPaint(
              foregroundPainter: const DashedBorderPainter(
                strokeWidth: 1,
                color: AppColors.borderStrong,
                radius: 10,
                dashLength: 5,
                gapLength: 4,
              ),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: (requested ? 149 : 210).w,
                ),
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 22.w),
                decoration: BoxDecoration(
                  color: AppColors.investorCard,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      allSigned
                          ? 'All signatures recorded'
                          : requested
                          ? 'Signatures in progress'
                          : 'No signatures yet',
                      style: AppTextStyles.text(14, weight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.w),
                    Text(
                      allSigned
                          ? 'Demo signatures are complete. Add the signed resolution to continue.'
                          : members.isEmpty
                          ? 'Add the required signatories to preview this resolution.'
                          : 'This demo simulates signature requests. No email or SMS is sent.',
                      style: AppTextStyles.text(12, color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                    if (!allSigned && members.isNotEmpty && store.editable) ...[
                      SizedBox(height: 10.w),
                      SizedBox(
                        width: 218.w,
                        child: AppButton(
                          label: requested
                              ? 'Resend pending requests'
                              : 'Send for signature',
                          loading: store.busy,
                          onPressed: store.busy
                              ? null
                              : () => store.requestSignatures(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (trust || members.isEmpty) SizedBox(height: 20.w),
          ],
          if (store.editable && (trust || members.isEmpty)) ...[
            AppButton(
              label: trust ? 'Add a trustee not on the LoA' : 'Add a director',
              style: AppButtonStyle.mintOutline,
              labelSize: 14,
              onPressed: store.busy ? null : () => _add(context, trust),
            ),
          ],
          if (trust) ...[
            SizedBox(height: 24.w),
            _heading('How signing works'),
            InvestorSurface(
              color: AppColors.investorCard,
              border: AppColors.border,
              radius: 10,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.w),
              child: Column(
                children: [
                  for (final (index, item) in const [
                    (
                      'Preview each trustee’s resolution',
                      'Review the saved details before simulating a signature.',
                    ),
                    (
                      'Simulate a trustee’s signature',
                      'No document is legally signed in this demo.',
                    ),
                    (
                      'Add the signed resolution',
                      'Use the upload simulation to attach the completed document.',
                    ),
                  ].indexed) ...[
                    if (index > 0)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.w),
                        child: const Divider(
                          height: 1,
                          color: AppColors.borderStrong,
                        ),
                      ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 15.w,
                          backgroundColor: AppColors.emerald700,
                          child: Text(
                            '${index + 1}',
                            style: AppTextStyles.text(
                              14,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$1,
                                style: AppTextStyles.text(
                                  14,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 6.w),
                              Text(
                                item.$2,
                                style: AppTextStyles.text(
                                  12,
                                  color: AppColors.muted,
                                  height: 17 / 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (store.errors['members'] != null)
            InlineError(store.errors['members']),
        ],
      );
    },
  );

  Widget _heading(String label, {double lineHeight = 17, double bottom = 12}) =>
      Padding(
        padding: EdgeInsets.only(bottom: bottom.w),
        child: Text(
          label,
          style: AppTextStyles.text(
            14,
            weight: FontWeight.w500,
            height: lineHeight / 14,
          ),
        ),
      );

  Future<void> _add(BuildContext context, bool trust) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await context.pushNamed<bool>(
      InvestorRoutes.kycMember,
      pathParameters: {
        'entity': store.entity.name,
        'role': trust ? 'trustee' : 'director',
        'section': 'details',
      },
      queryParameters: const {'return': 'resolution'},
    );
    if (context.mounted && !store.isDisposed) {
      await store.load(requestedStep: 'resolution');
    }
  }

  Future<void> _preview(BuildContext context, String memberId) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _ResolutionPreview(store: store, memberId: memberId),
      );
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({
    required this.member,
    required this.enabled,
    required this.editable,
    required this.onPreview,
    required this.onRequest,
  });
  final KycMember member;
  final bool enabled;
  final bool editable;
  final VoidCallback onPreview;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final awaiting =
        member.resolutionSignature.status == KycSignatureStatus.awaiting;
    final date = member.resolutionSignature.signedAt;
    final badge = Container(
      decoration: BoxDecoration(
        color: member.signed ? AppColors.mint : AppColors.amber50,
        borderRadius: BorderRadius.circular(14.r),
        border: member.signed ? null : Border.all(color: AppColors.amber300),
      ),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.w),
      child: Text(
        member.signed
            ? 'Signed'
            : awaiting
            ? 'Awaiting signature'
            : 'Not requested',
        style: AppTextStyles.text(
          12,
          weight: FontWeight.w500,
          color: member.signed ? AppColors.mintText : AppColors.warning,
        ),
      ),
    );
    return Semantics(
      key: ValueKey('signature-${member.id}'),
      button: true,
      label: 'Review signature for ${member.name}',
      child: InkWell(
        onTap: enabled ? onPreview : null,
        borderRadius: BorderRadius.circular(10.r),
        child: InvestorSurface(
          color: AppColors.investorCard,
          radius: 10,
          border: AppColors.border,
          padding: EdgeInsets.symmetric(
            horizontal: 18.w,
            vertical: member.signed ? 13.w : 10.w,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21.w,
                backgroundColor: AppColors.mint,
                child: Text(
                  '${member.firstName.characters.firstOrNull ?? ''}${member.lastName.characters.firstOrNull ?? ''}'
                      .toUpperCase(),
                  style: AppTextStyles.text(
                    16,
                    weight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (MediaQuery.textScalerOf(context).scale(14) > 18)
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 6.w,
                        children: [
                          Text(
                            member.name,
                            style: AppTextStyles.text(
                              14,
                              weight: FontWeight.w600,
                            ),
                          ),
                          badge,
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.name,
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          badge,
                        ],
                      ),
                    SizedBox(height: 6.w),
                    Text(
                      member.details?.position.isNotEmpty == true
                          ? member.details!.position
                          : member.details?.isDirector == true
                          ? 'Director'
                          : member.role.label,
                      style: AppTextStyles.text(14, color: AppColors.muted),
                    ),
                    SizedBox(height: 7.w),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.w,
                      children: [
                        Text(
                          'ID: ${member.identityNumber}',
                          style: AppTextStyles.text(
                            12,
                            color: AppColors.gray900,
                          ),
                        ),
                        if (member.email.isNotEmpty)
                          Text(
                            member.email,
                            style: AppTextStyles.text(
                              12,
                              color: AppColors.gray900,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 7.w),
                    if (member.signed)
                      Text(
                        'Signed in demo${date == null ? '' : ' · ${AppDateFormat.longDate(date)}'}',
                        style: AppTextStyles.text(12, color: AppColors.muted),
                      )
                    else
                      Wrap(
                        spacing: 8.w,
                        children: [
                          if (editable)
                            _SignatureAction(
                              label: awaiting ? 'Resend' : 'Request',
                              onPressed: enabled ? onRequest : null,
                            ),
                          _SignatureAction(
                            label: 'Preview',
                            outlined: true,
                            onPressed: enabled ? onPreview : null,
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

class _SignatureAction extends StatelessWidget {
  const _SignatureAction({
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: EdgeInsets.zero,
      foregroundColor: outlined ? AppColors.mintText : AppColors.white,
    ),
    onPressed: onPressed,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.w),
      decoration: BoxDecoration(
        color: onPressed == null
            ? AppColors.borderStrong
            : outlined
            ? AppColors.mint
            : AppColors.primary,
        borderRadius: BorderRadius.circular(24.r),
        border: outlined ? Border.all(color: AppColors.primary) : null,
      ),
      child: Text(
        label,
        style: AppTextStyles.text(
          12,
          weight: FontWeight.w500,
          color: onPressed == null
              ? AppColors.muted
              : outlined
              ? AppColors.mintText
              : AppColors.white,
        ),
      ),
    ),
  );
}

class _ResolutionPreview extends StatefulWidget {
  const _ResolutionPreview({required this.store, required this.memberId});
  final KycStore store;
  final String memberId;
  @override
  State<_ResolutionPreview> createState() => _ResolutionPreviewState();
}

class _ResolutionPreviewState extends State<_ResolutionPreview> {
  bool copied = false;
  String? copyError;
  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final store = widget.store;
      final member = store.members
          .where((member) => member.id == widget.memberId)
          .firstOrNull;
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Resolution preview',
                style: AppTextStyles.text(20, weight: FontWeight.w700),
              ),
              SizedBox(height: 12.w),
              if (member == null)
                const InlineError('This signatory is no longer available.')
              else ...[
                Text(
                  member.name,
                  style: AppTextStyles.text(16, weight: FontWeight.w600),
                ),
                SizedBox(height: 12.w),
                for (final field in store.step!.fields) ...[
                  Text(
                    field.label,
                    style: AppTextStyles.text(12, color: AppColors.muted),
                  ),
                  Text(
                    store.draft!.values[field.key]?.isNotEmpty == true
                        ? store.draft!.values[field.key]!
                        : 'Not provided',
                    style: AppTextStyles.text(14),
                  ),
                  SizedBox(height: 12.w),
                ],
                Text(
                  'This is a simulated resolution. No email, SMS, signing link or legal signature is issued.',
                  style: AppTextStyles.text(12, color: AppColors.muted),
                ),
                SizedBox(height: 18.w),
                AppButton(
                  label: member.signed
                      ? 'Signature recorded in demo'
                      : 'Simulate signature',
                  loading: store.busy,
                  onPressed:
                      !store.editable ||
                          store.busy ||
                          member.signed ||
                          member.resolutionSignature.status !=
                              KycSignatureStatus.awaiting
                      ? null
                      : () => store.simulateSignature(member.id),
                ),
                TextButton(
                  onPressed: () async {
                    final text = [
                      'Demo resolution for ${member.name}',
                      for (final field in store.step!.fields)
                        '${field.label}: ${store.draft!.values[field.key] ?? 'Not provided'}',
                      'Preview only. No legal signature has been issued.',
                    ].join('\n');
                    try {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (mounted) {
                        setState(() {
                          copied = true;
                          copyError = null;
                        });
                      }
                    } on PlatformException {
                      if (mounted) {
                        setState(
                          () => copyError =
                              'The preview could not be copied. Please try again.',
                        );
                      }
                    }
                  },
                  child: Text(copied ? 'Preview copied' : 'Copy preview'),
                ),
              ],
              if (copyError != null) InlineError(copyError),
              if (store.error != null) InlineError(store.error),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
