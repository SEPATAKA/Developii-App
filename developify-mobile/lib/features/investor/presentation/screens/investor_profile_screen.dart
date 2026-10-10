import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_profile_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_entity_sheet.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_profile_header.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_logout_sheet.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/profile_menu_row.dart';

class InvestorProfileScreen extends StatelessWidget {
  const InvestorProfileScreen({
    super.key,
    required this.store,
    required this.onLogout,
  });
  final InvestorProfileStore store;
  final VoidCallback onLogout;
  Future<void> _open(
    BuildContext context,
    String route, {
    Map<String, String> parameters = const {},
    Map<String, String> query = const {},
  }) async {
    await context.pushNamed(
      route,
      pathParameters: parameters,
      queryParameters: query,
    );
    if (context.mounted) await store.load();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      body: Observer(
        builder: (_) {
          if (store.status == LoadStatus.initial ||
              store.status == LoadStatus.loading && store.user == null) {
            return const LoadingView();
          }
          if (store.status == LoadStatus.error && store.user == null) {
            return ErrorView(
              message: store.error ?? 'Unable to load your profile.',
              onRetry: store.load,
            );
          }
          final user = store.user!;
          return RefreshIndicator(
            onRefresh: store.load,
            child: CustomScrollView(
              key: const PageStorageKey('investor-profile-scroll'),
              slivers: [
                SliverToBoxAdapter(
                  child: InvestorProfileHeader(
                    user: user,
                    entityLabel:
                        '${KycPlans.entityName(store.entity)}${store.nonResident ? ', Non-Resident / Diaspora' : ''}',
                    invested: !store.balanceVisible
                        ? 'Hidden'
                        : Money.compact(store.invested, lowercaseSuffix: true),
                    earned: !store.balanceVisible
                        ? 'Hidden'
                        : Money.amount(store.earned, decimals: false),
                    projectCount: store.account?.investments.length ?? 0,
                    onBack: () => context.goNamed(InvestorRoutes.home),
                    onSelectEntity: () => _selectEntity(context),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(13.w, 21.w, 12.w, 28.w),
                  sliver: SliverList.list(
                    children: [
                      if (store.error != null) ...[
                        InlineError(store.error),
                        TextButton(
                          onPressed: store.load,
                          child: const Text('Try again'),
                        ),
                      ],
                      for (final item in [
                        (
                          AppAssets.investorEditProfile,
                          'Edit Profile',
                          'Personal Info, Photo',
                          InvestorRoutes.editProfile,
                        ),
                        (
                          AppAssets.investorIdentity,
                          'Identity Verification (KYC)',
                          'Tier 2 · ${store.kycCompleted} of ${store.kycTotal} Complete',
                          InvestorRoutes.kyc,
                        ),
                        (
                          AppAssets.investorRisk,
                          'Risk Profile',
                          store.account?.verification ==
                                  VerificationStatus.verified
                              ? 'Growth Investor · Last reviewed 14 June'
                              : 'Complete your investor profile',
                          InvestorRoutes.riskProfile,
                        ),
                        (
                          AppAssets.submissionBank,
                          'Bank Details',
                          'Account setup for withdrawals',
                          'investor-bank-details',
                        ),
                        (
                          AppAssets.investorPaymentCard,
                          'Payment Methods',
                          'Cards & Accounts',
                          InvestorRoutes.paymentMethods,
                        ),
                        (
                          AppAssets.investorPreferences,
                          'Notifications Preferences',
                          'Push, SMS, email',
                          'investor-notification-preferences',
                        ),
                        (
                          AppAssets.investorPreferences,
                          'Language',
                          store.language,
                          'investor-language',
                        ),
                        (
                          AppAssets.investorSecurity,
                          'Security',
                          'Password, Biometrics, PIN',
                          InvestorRoutes.security,
                        ),
                        (
                          AppAssets.investorHelp,
                          'Help & Support',
                          'Get fast help and responses',
                          'investor-help',
                        ),
                        (
                          AppAssets.investorAbout,
                          'About Developify',
                          'Versions, Terms & Privacy',
                          'investor-about',
                        ),
                      ])
                        Padding(
                          padding: EdgeInsets.only(bottom: 19.w),
                          child: ProfileMenuRow(
                            icon: item.$1,
                            title: item.$2,
                            subtitle: item.$3,
                            onTap: () => _open(
                              context,
                              item.$4,
                              parameters: item.$4 == InvestorRoutes.kyc
                                  ? {
                                      'entity': store.entity.name,
                                      'step': 'overview',
                                    }
                                  : const {},
                            ),
                          ),
                        ),
                      ProfileMenuRow(
                        icon: AppAssets.profileMenuLogout,
                        title: 'Logout',
                        danger: true,
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
  Future<void> _selectEntity(BuildContext context) async {
    final choice = await showInvestorEntitySheet(
      context,
      initial: store.entity,
      nonResident: store.nonResident,
    );
    if (context.mounted && choice != null) {
      store.selectEntity(choice.entity, nonResident: choice.nonResident);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final logout = await showInvestorLogoutSheet(context);
    if (context.mounted && logout == true) onLogout();
  }
}
