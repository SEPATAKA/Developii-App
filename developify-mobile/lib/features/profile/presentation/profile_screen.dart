import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:developify_mobile/core/widgets/app_switch.dart';
import 'package:developify_mobile/core/widgets/phone_number_field.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/profile_photo_control.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/payout_account_content.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/profile_country_field.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/language_choice.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/preference_group.dart';
import 'package:developify_mobile/core/widgets/feedback.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/profile_menu_row.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/landowner_profile_header.dart';
import 'package:developify_mobile/core/widgets/sheets.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/profile/presentation/stores/profile_store.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

enum ProfilePage { overview, edit, payout, preferences, language }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.store,
    this.page = ProfilePage.overview,
    this.onLogout,
    this.routePrefix = '',
    this.landowner,
  });
  final ProfileStore store;
  final ProfilePage page;
  final VoidCallback? onLogout;
  final String routePrefix;
  final LandownerRepository? landowner;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileStore get store => widget.store;
  bool get _investor => widget.routePrefix == 'investor-';
  bool _allowPop = false;
  String? _phoneCountryCode;
  int _propertyCount = 0;
  int _approvedCount = 0;
  String _earnedLabel = 'R0';
  StreamSubscription<void>? _landownerChanges;
  @override
  void initState() {
    super.initState();
    unawaited(store.load());
    _landownerChanges = widget.landowner?.changes.listen((_) {
      unawaited(_loadLandownerStats());
    });
    unawaited(_loadLandownerStats());
  }

  Future<void> _loadLandownerStats() async {
    final repository = widget.landowner;
    if (repository == null || !mounted) return;
    final result = await repository.overview();
    if (!mounted) return;
    if (result case Success(:final value)) {
      setState(() {
        _propertyCount = value.propertyCount;
        _approvedCount = value.approvedCount;
        _earnedLabel = Money.compact(
          MonetaryAmount(value.earnedCents, Currency.zar),
          lowercaseSuffix: true,
        );
      });
    }
  }

  @override
  void dispose() {
    unawaited(_landownerChanges?.cancel());
    store.dispose();
    super.dispose();
  }

  Future<void> _open(String name) async {
    await context.pushNamed('${widget.routePrefix}$name');
    if (mounted) await store.load();
  }

  Future<void> _back() async {
    if (store.saving) return;
    if (store.dirty && !await confirmExit(context)) return;
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed('${widget.routePrefix}${Routes.profile}');
        }
      }
    });
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (await store.save() && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed('${widget.routePrefix}${Routes.profile}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.page == ProfilePage.overview) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(body: _content()),
      );
    }
    final titles = {
      ProfilePage.edit: 'Edit Profile',
      ProfilePage.payout: 'Payout Account',
      ProfilePage.preferences: 'Notifications',
      ProfilePage.language: 'Language',
    };
    if (widget.page != ProfilePage.edit) {
      return AppPage(
        title: titles[widget.page],
        onBack: _back,
        headerLeadingInset:
            widget.page == ProfilePage.preferences ||
                widget.page == ProfilePage.language
            ? 22
            : widget.page == ProfilePage.payout
            ? 19
            : null,
        headerTopInset: widget.page == ProfilePage.payout ? 13 : null,
        titleCenterOffset: switch (widget.page) {
          ProfilePage.preferences => -2.5,
          ProfilePage.language => -18,
          ProfilePage.payout => 2.5,
          _ => 0,
        },
        child: _content(),
      );
    }
    return Observer(
      builder: (_) => PopScope(
        canPop: !store.saving && (!store.dirty || _allowPop),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_back());
        },
        child: AppPage(
          title: titles[widget.page],
          onBack: _back,
          headerLeadingInset: 18.5,
          headerTopInset: 13,
          titleCenterOffset: 5,
          bottom: _investor && store.status == LoadStatus.success
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InlineError(
                      store.error ??
                          (store.errors.isEmpty
                              ? null
                              : store.errors.values.first),
                    ),
                    _saveButton(),
                  ],
                )
              : null,
          child: _content(),
        ),
      ),
    );
  }

  Widget _content() => Observer(
    builder: (_) {
      if (store.status == LoadStatus.loading ||
          store.status == LoadStatus.initial) {
        return const LoadingView();
      }
      if (store.status == LoadStatus.error) {
        return ErrorView(message: store.error!, onRetry: store.load);
      }
      return switch (widget.page) {
        ProfilePage.overview => _overview(),
        ProfilePage.edit => _edit(),
        ProfilePage.payout => _payout(),
        ProfilePage.preferences => _preferences(),
        ProfilePage.language => _language(),
      };
    },
  );
  Widget _overview() {
    final user = store.user!;
    return RefreshIndicator(
      onRefresh: () async {
        await store.load();
        await _loadLandownerStats();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LandownerProfileHeader(
              user: user,
              propertyCount: _propertyCount,
              approvedCount: _approvedCount,
              earnedLabel: _earnedLabel,
              onBack: () =>
                  context.goNamed('${widget.routePrefix}${Routes.home}'),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(13.w, 38.w, 11.w, 60.w),
            sliver: SliverList.list(
              children: [
                ProfileMenuRow(
                  title: 'Edit Profile',
                  subtitle: 'Personal Info, Photo',
                  icon: AppAssets.profileMenuEdit,
                  onTap: () => _open(Routes.editProfile),
                ),
                SizedBox(height: 19.w),
                ProfileMenuRow(
                  title: 'Entity type',
                  subtitleWidget: Row(
                    children: [
                      Text(
                        '${user.entity.name[0].toUpperCase()}${user.entity.name.substring(1)}',
                        style: AppTextStyles.text(
                          12,
                          weight: FontWeight.w500,
                          color: AppColors.iconMuted,
                          height: 14 / 12,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        width: 4.w,
                        height: 4.w,
                        decoration: const BoxDecoration(
                          color: AppColors.iconMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          'Switch to others',
                          style: AppTextStyles.text(
                            12,
                            weight: FontWeight.w500,
                            color: AppColors.iconMuted,
                            height: 14 / 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  icon: AppAssets.profileMenuEntity,
                  onTap: () async {
                    final entity = await showChoiceSheet<EntityType>(
                      context,
                      title: 'Entity type',
                      choices: {
                        for (final item in EntityType.values)
                          item:
                              '${item.name[0].toUpperCase()}${item.name.substring(1)}',
                      },
                      selected: user.entity,
                    );
                    if (entity == null || !mounted) return;
                    store.setEntity(entity);
                    if (!await store.save() && mounted && store.error != null) {
                      showFeedback(context, store.error!);
                    }
                  },
                ),
                SizedBox(height: 19.w),
                ProfileMenuRow(
                  title: 'Entity Verification',
                  subtitle: 'Documents, directors, trustees & resolutions',
                  icon: AppAssets.profileMenuVerification,
                  onTap: () {
                    context.pushNamed(
                      Routes.submit,
                      pathParameters: {'step': '7'},
                      queryParameters: {'draft': 'entity-verification'},
                    );
                  },
                ),
                SizedBox(height: 19.w),
                ProfileMenuRow(
                  title: 'Bank Details',
                  subtitle: 'Account setup for withdrawals',
                  icon: AppAssets.profileMenuBank,
                  onTap: () => _open(Routes.payout),
                ),
                SizedBox(height: 19.w),
                ProfileMenuRow(
                  title: 'Notifications Peferences',
                  subtitle: 'Push, SMS, email',
                  icon: AppAssets.profileMenuNotification,
                  onTap: () => _open(Routes.notificationPreferences),
                ),
                SizedBox(height: 19.w),
                ProfileMenuRow(
                  title: 'Language',
                  subtitle: store.preferences.language,
                  icon: AppAssets.profileMenuNotification,
                  onTap: () => _open(Routes.language),
                ),
                SizedBox(height: 19.w),
                ProfileMenuRow(
                  title: 'Security',
                  subtitle: 'Password, Biometrics,PIN',
                  icon: AppAssets.profileMenuSecurity,
                  onTap: () => _open(Routes.security),
                ),
                SizedBox(height: 19.w),
                ProfileMenuRow(
                  title: 'Help & Support',
                  subtitle: 'Get fast help and responses',
                  icon: AppAssets.profileMenuHelp,
                  onTap: () => _open(Routes.help),
                ),
                SizedBox(height: 19.w),
                ProfileMenuRow(
                  title: 'About Developity',
                  subtitle: 'Versions, Terms & Privacy',
                  icon: AppAssets.profileMenuAbout,
                  onTap: () => _open(Routes.about),
                ),
                SizedBox(height: 19.w),
                ProfileMenuRow(
                  title: 'Logout',
                  icon: AppAssets.profileMenuLogout,
                  danger: true,
                  onTap: widget.onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _edit() {
    final user = store.user!;
    final country = PhoneNumberField.countries.firstWhere(
      (c) => _phoneCountryCode == null
          ? user.phone.startsWith(c.$2)
          : c.$1 == _phoneCountryCode,
      orElse: () => PhoneNumberField.countries.first,
    );
    final phoneNumber = user.phone.startsWith(country.$2)
        ? user.phone.substring(country.$2.length).trimLeft()
        : user.phone;
    return ListView(
      key: const ValueKey('profile-edit-content'),
      padding: EdgeInsets.only(top: 32.w, bottom: 13.w),
      children: [
        Center(
          child: ProfilePhotoControl(
            photoAsset: _investor
                ? AppAssets.investorProfileAvatar
                : AppAssets.avatar,
            hasPhoto: user.hasProfilePhoto,
            onChanged: store.selectPhoto,
          ),
        ),
        SizedBox(height: (user.hasProfilePhoto ? 13.5 : 18.5).w),
        AppField(
          label: 'Full Name',
          value: user.name,
          textColor: AppColors.iconMuted,
          onChanged: (v) => store.edit('name', v),
          error: store.errors['name'],
        ),
        SizedBox(height: 21.w),
        const AppField(
          label: 'Developify ID',
          value: '2621671972',
          readOnly: true,
          textColor: AppColors.neutralBorder,
        ),
        SizedBox(height: 21.w),
        AppField(
          label: 'Email Address',
          value: user.email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => store.edit('email', v),
          error: store.errors['email'],
        ),
        SizedBox(height: 21.w),
        PhoneNumberField(
          value: phoneNumber,
          countryCode: country.$1,
          onChanged: (value) => store.edit('phone', '${country.$2} $value'),
          onCountryChanged: (code, prefix) {
            _phoneCountryCode = code;
            store.edit('phone', '$prefix $phoneNumber');
          },
          error: store.errors['phone'],
        ),
        SizedBox(height: 21.w),
        ProfileCountryField(
          countryCode: user.countryCode,
          onChanged: (value) => store.edit('country', value),
        ),
        if (!_investor) ...[
          SizedBox(height: 21.w),
          AppField(
            label: 'Residential',
            value: user.address,
            maxLines: 5,
            fieldHeight: 102.w,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.w,
            ),
            onChanged: (v) => store.edit('address', v),
            textInputAction: TextInputAction.newline,
          ),
          SizedBox(height: (user.hasProfilePhoto ? 38 : 33).w),
          InlineError(store.error),
          Padding(
            padding: EdgeInsets.only(left: 1.w),
            child: _saveButton(),
          ),
        ],
      ],
    );
  }

  Widget _saveButton() => AppButton(
    key: const ValueKey('profile-save'),
    label: 'Save Changes',
    loading: store.saving,
    onPressed: _save,
  );

  Widget _payout() => PayoutAccountContent(
    account: store.payoutAccount,
    onAdd: () => _open(Routes.newPayout),
    onHistory: () => context.goNamed('${widget.routePrefix}${Routes.earnings}'),
  );

  Widget _preferences() => ListView(
    padding: EdgeInsets.only(top: 30.w, bottom: 24.w),
    children: [
      Text('CHANNELS', style: AppTextStyles.label),
      SizedBox(height: 12.w),
      PreferenceGroup(
        values: store.preferences.channels,
        inactiveColor: _investor ? AppColors.iconMuted : null,
        onChanged: store.saving
            ? null
            : (key, value) => store.togglePreference(key, value, channel: true),
      ),
      SizedBox(height: 20.w),
      Text('TOPICS', style: AppTextStyles.label),
      SizedBox(height: 12.w),
      PreferenceGroup(
        values: store.preferences.topics,
        inactiveColor: _investor ? AppColors.iconMuted : null,
        onChanged: store.saving
            ? null
            : (key, value) => store.togglePreference(key, value),
      ),
      InlineError(store.error),
    ],
  );
  Widget _language() => ListView(
    padding: EdgeInsets.only(top: 22.w, bottom: 24.w),
    children: [
      for (final entry in [
        ('English (UK)', AppAssets.languageFlagUk),
        ('English (US)', AppAssets.languageFlagUs),
      ])
        Padding(
          padding: EdgeInsets.only(bottom: 12.w),
          child: LanguageChoice(
            label: entry.$1,
            flag: entry.$2,
            selected: store.preferences.language == entry.$1,
            onTap: store.saving ? null : () => store.setLanguage(entry.$1),
          ),
        ),
      InlineError(store.error),
    ],
  );
}

class CompactSwitch extends StatelessWidget {
  const CompactSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    enabled: onChanged != null,
    child: InkResponse(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: SizedBox.square(
        dimension: 44,
        child: Center(child: AppSwitch(value: value)),
      ),
    ),
  );
}
