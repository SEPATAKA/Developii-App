import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_tax_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_member_screen.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/investor/presentation/screens/explore_filter_screen.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investment_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/transfer_screen.dart';
import 'package:developify_mobile/features/investor/presentation/stores/transfer_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investment_store.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'helpers/fidelity_capture.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'helpers/fonts.dart';
import 'helpers/investor_member_fixtures.dart';
import 'helpers/investor_profile_frames.dart';
import 'helpers/investor_signup_frames.dart';
import 'helpers/investor_auth_frames.dart';
import 'helpers/investor_home_frames.dart';
import 'helpers/investor_explore_frames.dart';
import 'helpers/investor_checklist_frames.dart';
import 'helpers/investor_document_frames.dart';
import 'helpers/investor_natural_review_frames.dart';
import 'helpers/investor_entity_document_frames.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';

void main() {
  setUpAll(loadAppFonts);
  final cases = [
    ('43575', '/investor/home', 852.0, true, MockScenario.success),
    for (final node in ['54144', '54254', '54364'])
      (
        node,
        '/investor/kyc/trust/resolution',
        1284.0,
        true,
        MockScenario.incompleteKyc,
      ),
    (
      '57726',
      '/investor/kyc/trust/member/trustee/preview',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '47906',
      '/investor/kyc/individual/identity',
      879.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '48414',
      '/investor/kyc/individual/identity',
      879.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '49316',
      '/investor/kyc/individual/identity',
      879.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '47174',
      '/investor/kyc/individual/bank',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '47728',
      '/investor/kyc/individual/address',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '47817',
      '/investor/kyc/individual/address',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '51410',
      '/investor/kyc/individual/identity',
      855.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '52549',
      '/investor/kyc/individual/tax/wealth',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '54842',
      '/investor/verification',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '54895',
      '/investor/verification/entity',
      941.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '51954',
      '/investor/kyc/individual/tax',
      885.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '52435',
      '/investor/kyc/individual/tax/wealth',
      1322.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '52675',
      '/investor/kyc/individual/tax/residency',
      1728.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '52939',
      '/investor/kyc/individual/funds',
      1303.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '81266',
      '/investor/kyc/company/member/shareholder/details',
      1348.0,
      true,
      MockScenario.incompleteKyc,
    ),
    for (final entry in investorEntityDocumentFrames.entries)
      (
        entry.key,
        '/investor/kyc/${entry.value.$1.name}/${entry.value.$2}',
        entry.value.$3,
        true,
        MockScenario.incompleteKyc,
      ),
    (
      '56091',
      '/investor/kyc/trust/deed',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '56289',
      '/investor/kyc/trust/deed',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '59858',
      '/investor/kyc/trust/deed',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '84283',
      '/investor/kyc/stokvel/bank',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    ...investorChecklistFrameCases,
    for (final node in investorNaturalReviewFrames)
      (
        node,
        '/investor/kyc/individual/review',
        node == '53372' || node == '53660' ? 2408.0 : 1088.0,
        true,
        MockScenario.incompleteKyc,
      ),
    (
      '46730',
      '/investor/kyc/individual/address',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '46883',
      '/investor/kyc/individual/bank',
      1249.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '46980',
      '/investor/kyc/individual/bank',
      1249.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '47076',
      '/investor/kyc/individual/bank',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '47290',
      '/investor/kyc/individual/address',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '47366',
      '/investor/kyc/individual/address',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '47442',
      '/investor/kyc/individual/address',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '47514',
      '/investor/kyc/individual/address',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '47586',
      '/investor/kyc/individual/address',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '47657',
      '/investor/kyc/individual/address',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '46200',
      '/investor/verification',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '46253',
      '/investor/verification',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '46306',
      '/investor/verification/entity',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '50218',
      '/investor/verification/entity',
      855.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '54985',
      '/investor/verification/entity',
      941.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '46396',
      '/investor/verification/documents',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '46467',
      '/investor/verification/documents',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '73566',
      '/investor/explore?category=residential',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '73755',
      '/investor/explore?category=commercial',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '73944',
      '/investor/explore?category=hospitality',
      852.0,
      true,
      MockScenario.success,
    ),
    ('74303', '/investor/explore/search', 852.0, true, MockScenario.success),
    (
      '74436',
      '/investor/explore/search?q=No%20matching%20place',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '75970',
      '/investor/explore/search?q=Capetown',
      852.0,
      true,
      MockScenario.success,
    ),
    ('84794', '/investor/explore/wishlist', 933.0, true, MockScenario.success),
    ('77297', '/investor/wallet', 852.0, true, MockScenario.success),
    (
      '74987',
      '/investor/projects/saffron-towers/calculator',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '75054',
      '/investor/projects/saffron-towers/calculator',
      852.0,
      true,
      MockScenario.success,
    ),
    ('41594', '/investor/home', 1467.0, true, MockScenario.pendingVerification),
    ('42043', '/investor/home', 852.0, true, MockScenario.success),
    ('42496', '/investor/home', 852.0, true, MockScenario.success),
    ('42829', '/investor/home', 1472.0, true, MockScenario.noPortfolio),
    ('43201', '/investor/home', 1472.0, true, MockScenario.noPortfolio),
    ('44088', '/investor/home', 852.0, true, MockScenario.success),
    ('44531', '/investor/home', 852.0, true, MockScenario.success),
    ('44971', '/investor/home', 852.0, true, MockScenario.success),
    ('45427', '/experience', 855.0, true, MockScenario.success),
    ('45456', '/investor/home', 852.0, true, MockScenario.pendingVerification),
    ('45828', '/investor/home', 852.0, true, MockScenario.pendingVerification),
    ('54472', '/investor/home', 852.0, true, MockScenario.pendingVerification),
    ('61367', '/investor/home', 852.0, true, MockScenario.success),
    ('61807', '/investor/home', 852.0, true, MockScenario.success),
    ('62247', '/investor/home', 852.0, true, MockScenario.success),
    ('71909', '/investor/home', 852.0, true, MockScenario.success),
    ('72937', '/investor/home', 1040.0, true, MockScenario.success),
    ('62765', '/investor/wallet/add-money', 852.0, true, MockScenario.success),
    ('62835', '/investor/wallet/add-money', 852.0, true, MockScenario.success),
    (
      '63547',
      '/investor/profile/payment-methods/card?select=true',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '63594',
      '/investor/profile/payment-methods/card?select=true',
      852.0,
      true,
      MockScenario.success,
    ),
    ('63889', '/investor/profile', 1357.0, true, MockScenario.success),
    ('64098', '/investor/profile', 1357.0, true, MockScenario.success),
    ('64307', '/investor/profile', 1357.0, true, MockScenario.success),
    ('64516', '/investor/profile', 1357.0, true, MockScenario.success),
    ('64725', '/investor/profile', 1357.0, true, MockScenario.success),
    ('64934', '/investor/profile', 1357.0, true, MockScenario.success),
    ('65143', '/investor/profile', 1357.0, true, MockScenario.success),
    ('65352', '/investor/profile', 1357.0, true, MockScenario.success),
    ('65561', '/investor/profile', 852.0, true, MockScenario.success),
    ('65874', '/investor/profile', 852.0, true, MockScenario.success),
    ('66098', '/investor/profile', 852.0, true, MockScenario.success),
    ('66307', '/investor/profile', 852.0, true, MockScenario.success),
    ('66516', '/investor/profile', 852.0, true, MockScenario.success),
    ('66725', '/investor/profile', 852.0, true, MockScenario.success),
    ('38249', '/investor/onboarding', 852.0, false, MockScenario.success),
    ('38290', '/investor/onboarding', 852.0, false, MockScenario.success),
    ('38331', '/investor/onboarding-terms', 852.0, false, MockScenario.success),
    ('38385', '/investor/onboarding-terms', 852.0, false, MockScenario.success),
    (
      '38469',
      '/investor/welcome?entry=onboarding',
      852.0,
      false,
      MockScenario.success,
    ),
    (
      '38560',
      '/investor/welcome?entry=onboarding',
      852.0,
      false,
      MockScenario.success,
    ),
    ('38176', '/investor/splash', 852.0, false, MockScenario.success),
    ('40110', '/investor/forgot-password', 852.0, false, MockScenario.success),
    ('40274', '/investor/forgot-password', 852.0, false, MockScenario.success),
    ('40312', '/investor/forgot-password', 852.0, false, MockScenario.success),
    ('40350', '/investor/forgot-password', 852.0, false, MockScenario.success),
    ('40398', '/investor/forgot-password', 852.0, false, MockScenario.success),
    ('40446', '/investor/forgot-password', 852.0, false, MockScenario.success),
    ('40494', '/investor/forgot-password', 852.0, false, MockScenario.success),
    ('40558', '/investor/forgot-password', 852.0, false, MockScenario.success),
    ('40606', '/investor/forgot-password', 852.0, false, MockScenario.success),
    ('40679', '/investor/welcome-back', 852.0, false, MockScenario.success),
    ('40719', '/investor/welcome-back', 852.0, false, MockScenario.success),
    ('41056', '/investor/sign-in', 852.0, false, MockScenario.success),
    ('41099', '/investor/sign-in', 852.0, false, MockScenario.success),
    ('40794', '/investor/welcome', 852.0, false, MockScenario.success),
    ('38651', '/investor/create-account', 852.0, false, MockScenario.success),
    ('38704', '/investor/create-account', 964.0, false, MockScenario.success),
    (
      '38758',
      '/investor/create-account?entity=company',
      1095.0,
      false,
      MockScenario.success,
    ),
    (
      '38833',
      '/investor/create-account?entity=company',
      1304.0,
      false,
      MockScenario.success,
    ),
    (
      '38958',
      '/investor/create-account?entity=company',
      1304.0,
      false,
      MockScenario.success,
    ),
    ('39083', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39135', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39187', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39225', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39260', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39295', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39330', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39368', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39422', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39469', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39507', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39546', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39597', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39643', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39693', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39731', '/investor/create-account', 852.0, false, MockScenario.success),
    ('39785', '/investor/create-account', 852.0, false, MockScenario.success),
    ('65770', '/investor/profile/language', 852.0, true, MockScenario.success),
    ('66934', '/investor/profile/edit', 852.0, true, MockScenario.success),
    ('67563', '/investor/profile/edit', 852.0, true, MockScenario.success),
    (
      '67811',
      '/investor/profile/notifications',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '67914',
      '/investor/profile/notifications',
      852.0,
      true,
      MockScenario.success,
    ),
    ('68025', '/investor/profile/security', 852.0, true, MockScenario.success),
    ('68120', '/investor/profile/security', 852.0, true, MockScenario.success),
    ('68215', '/investor/profile/security', 852.0, true, MockScenario.success),
    ('68310', '/investor/profile/security', 852.0, true, MockScenario.success),
    ('68405', '/investor/profile/security', 852.0, true, MockScenario.success),
    ('68499', '/investor/profile/security', 852.0, true, MockScenario.success),
    ('68593', '/investor/profile/security', 852.0, true, MockScenario.success),
    ('68687', '/investor/profile/security', 852.0, true, MockScenario.success),
    ('68781', '/investor/profile/help', 852.0, true, MockScenario.success),
    ('68897', '/investor/profile/about', 852.0, true, MockScenario.success),
    ('68956', '/investor/privacy', 1059.0, true, MockScenario.success),
    ('69013', '/investor/terms', 852.0, true, MockScenario.success),
    (
      '69050',
      '/investor/profile/security/password',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69134',
      '/investor/profile/security/password',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69092',
      '/investor/profile/security/pin',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69194',
      '/investor/profile/security/pin',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69236',
      '/investor/profile/security/pin',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69281',
      '/investor/profile/security/pin',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69326',
      '/investor/profile/security/pin',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69389',
      '/investor/profile/security/2fa/app',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69429',
      '/investor/profile/security/2fa',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69482',
      '/investor/profile/security/2fa',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69535',
      '/investor/profile/security/2fa/sms',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69578',
      '/investor/profile/security/2fa/app',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69621',
      '/investor/profile/security/2fa/sms',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69659',
      '/investor/profile/security/2fa/sms',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69697',
      '/investor/profile/security/2fa/sms',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69740',
      '/investor/profile/security/2fa/app',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69783',
      '/investor/profile/security/2fa/sms',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69839',
      '/investor/profile/security/2fa/app',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69895',
      '/investor/profile/security/2fa/sms',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69938',
      '/investor/profile/security/2fa/app',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '69981',
      '/investor/profile/security/biometrics',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '70137',
      '/investor/profile/security/biometrics',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '70046',
      '/investor/profile/security/devices',
      852.0,
      true,
      MockScenario.success,
    ),
    ('72351', '/investor/wallet/withdraw', 852.0, true, MockScenario.success),
    ('72433', '/investor/wallet/withdraw', 852.0, true, MockScenario.success),
    ('72515', '/investor/wallet/withdraw', 852.0, true, MockScenario.success),
    ('72574', '/investor/wallet/withdraw', 852.0, true, MockScenario.success),
    ('72684', '/investor/wallet/withdraw', 852.0, true, MockScenario.success),
    ('72779', '/investor/wallet/withdraw', 852.0, true, MockScenario.success),
    ('72849', '/investor/wallet/withdraw', 852.0, true, MockScenario.success),
    ('62905', '/investor/wallet/add-money', 852.0, true, MockScenario.success),
    (
      '62965',
      '/investor/wallet/add-money',
      852.0,
      true,
      MockScenario.paymentMethodUnavailable,
    ),
    ('62999', '/investor/wallet/add-money', 852.0, true, MockScenario.success),
    ('63074', '/investor/wallet/add-money', 852.0, true, MockScenario.success),
    ('63149', '/investor/wallet/add-money', 852.0, true, MockScenario.success),
    ('63210', '/investor/wallet/add-money', 852.0, true, MockScenario.success),
    ('63307', '/investor/wallet/add-money', 852.0, true, MockScenario.success),
    ('63419', '/investor/wallet/add-money', 852.0, true, MockScenario.success),
    (
      '75234',
      '/investor/projects/marula-heights/invest',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '75302',
      '/investor/projects/marula-heights/invest',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '75370',
      '/investor/projects/marula-heights/invest',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '75437',
      '/investor/projects/marula-heights/invest',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '75504',
      '/investor/projects/marula-heights/invest',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '75607',
      '/investor/projects/marula-heights/invest',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '75725',
      '/investor/projects/marula-heights/invest',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '75802',
      '/investor/projects/marula-heights/invest',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '75888',
      '/investor/projects/marula-heights/invest',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '59009',
      '/investor/kyc/trust/review',
      2449.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '59280',
      '/investor/kyc/trust/review',
      2449.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '59559',
      '/investor/kyc/trust/review',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '56619',
      '/investor/kyc/trust/resolution',
      1839.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '56805',
      '/investor/kyc/trust/resolution',
      1839.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '56991',
      '/investor/kyc/trust/resolution',
      1839.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '80931',
      '/investor/kyc/company/resolution',
      1339.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '81662',
      '/investor/kyc/company/resolution',
      1339.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '81740',
      '/investor/kyc/company/resolution',
      1566.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '81875',
      '/investor/kyc/company/resolution',
      1580.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '83906',
      '/investor/kyc/stokvel/resolution',
      963.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '57190',
      '/investor/kyc/trust/trustees',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '58093',
      '/investor/kyc/trust/beneficiaries',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '58158',
      '/investor/kyc/trust/beneficiaries',
      999.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '58262',
      '/investor/kyc/trust/member/beneficiary/details',
      1195.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '58358',
      '/investor/kyc/trust/member/beneficiary/details',
      1507.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '58473',
      '/investor/kyc/trust/member/beneficiary/details',
      1356.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '58607',
      '/investor/kyc/trust/member/beneficiary/allocation?id=reference-a',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '57279',
      '/investor/kyc/trust/member/trustee/invite',
      1758.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '57456',
      '/investor/kyc/trust/member/trustee/invite',
      1758.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '57633',
      '/investor/kyc/trust/member/trustee/preview',
      975.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '80353',
      '/investor/kyc/company/shareholders',
      1118.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '81009',
      '/investor/kyc/company/directors',
      1118.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '81168',
      '/investor/kyc/company/member/shareholder/details',
      1348.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '81364',
      '/investor/kyc/company/member/shareholder/details',
      1183.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '81480',
      '/investor/kyc/company/member/shareholder/allocation?id=reference-a',
      951.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '83727',
      '/investor/kyc/stokvel/officers',
      963.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '52052',
      '/investor/kyc/individual/tax/residency',
      1728.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '52214',
      '/investor/kyc/individual/tax/pep',
      1345.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '52331',
      '/investor/kyc/individual/tax/wealth',
      1417.0,
      true,
      MockScenario.incompleteKyc,
    ),
    ('38208', '/investor/onboarding', 852.0, false, MockScenario.success),
    (
      '38439',
      '/investor/welcome?entry=onboarding',
      852.0,
      false,
      MockScenario.success,
    ),
    ('40762', '/investor/splash', 852.0, false, MockScenario.success),
    ('40647', '/investor/splash', 852.0, false, MockScenario.success),
    ('40073', '/investor/forgot-password', 852.0, false, MockScenario.success),
    ('41145', '/investor/home', 1467.0, true, MockScenario.pendingVerification),
    ('43648', '/investor/home', 852.0, true, MockScenario.success),
    ('73377', '/investor/explore', 1183.0, true, MockScenario.success),
    (
      '74132',
      '/investor/explore/filters?max=200',
      1362.0,
      true,
      MockScenario.success,
    ),
    (
      '76088',
      '/investor/explore/filters?max=200',
      1361.0,
      true,
      MockScenario.success,
    ),
    (
      '74616',
      '/investor/projects/saffron-towers',
      1552.0,
      true,
      MockScenario.success,
    ),
    (
      '74780',
      '/investor/projects/saffron-towers/developer',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '74922',
      '/investor/projects/saffron-towers/details',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '75121',
      '/investor/projects/saffron-towers/updates',
      1077.0,
      true,
      MockScenario.success,
    ),
    (
      '75169',
      '/investor/projects/saffron-towers/updates/planning',
      852.0,
      true,
      MockScenario.success,
    ),
    ('77149', '/investor/wallet', 1027.0, true, MockScenario.success),
    ('62693', '/investor/wallet/add-money', 852.0, true, MockScenario.success),
    (
      '63500',
      '/investor/profile/payment-methods/card?select=true',
      852.0,
      true,
      MockScenario.success,
    ),
    ('76259', '/investor/transactions', 852.0, true, MockScenario.success),
    (
      '76403',
      '/investor/transactions/individual-investment-payment',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '76467',
      '/investor/transactions/individual-withdrawal',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '76534',
      '/investor/transactions/individual-topup-0',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '76589',
      '/investor/transactions/individual-distribution-saffron',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '76653',
      '/investor/transactions/individual-topup-1',
      852.0,
      true,
      MockScenario.success,
    ),
    ('77448', '/investor/portfolio', 947.0, true, MockScenario.success),
    (
      '78278',
      '/investor/investments/individual-saffron-2',
      1250.0,
      true,
      MockScenario.success,
    ),
    (
      '78415',
      '/investor/investments/individual-saffron-2',
      1250.0,
      true,
      MockScenario.success,
    ),
    (
      '78521',
      '/investor/investments/individual-saffron-2',
      1250.0,
      true,
      MockScenario.success,
    ),
    ('77606', '/investor/portfolio', 947.0, true, MockScenario.success),
    ('77741', '/investor/portfolio', 947.0, true, MockScenario.success),
    (
      '78097',
      '/investor/portfolio/analytics',
      1030.0,
      true,
      MockScenario.success,
    ),
    (
      '76717',
      '/investor/notifications',
      852.0,
      true,
      MockScenario.noNotifications,
    ),
    ('76762', '/investor/notifications', 852.0, true, MockScenario.success),
    (
      '76841',
      '/investor/notifications/individual-target-reached',
      912.0,
      true,
      MockScenario.success,
    ),
    (
      '76936',
      '/investor/investments/individual-saffron-1/timeline',
      1041.0,
      true,
      MockScenario.success,
    ),
    (
      '77041',
      '/investor/investments/individual-saffron-0/timeline',
      1000.0,
      true,
      MockScenario.success,
    ),
    (
      '77838',
      '/investor/portfolio/list/active',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '77952',
      '/investor/portfolio/list/completed',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '78042',
      '/investor/portfolio/list/underfunded',
      852.0,
      true,
      MockScenario.success,
    ),
    ('63680', '/investor/profile', 1439.0, true, MockScenario.success),
    (
      '67001',
      '/investor/profile/bank-details',
      852.0,
      true,
      MockScenario.paymentMethodUnavailable,
    ),
    (
      '67035',
      '/investor/profile/payment-methods',
      852.0,
      true,
      MockScenario.paymentMethodUnavailable,
    ),
    (
      '67069',
      '/investor/profile/bank-details',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '67498',
      '/investor/profile/bank-details',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '67134',
      '/investor/profile/payment-methods',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '67205',
      '/investor/profile/payment-methods/cards',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '67274',
      '/investor/profile/payment-methods/cards',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '67386',
      '/investor/profile/payment-methods/cards',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '67624',
      '/investor/profile/payment-methods?kind=card&select=true',
      852.0,
      true,
      MockScenario.paymentMethodUnavailable,
    ),
    (
      '67658',
      '/investor/profile/payment-methods/card',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '67705',
      '/investor/profile/payment-methods/card',
      852.0,
      true,
      MockScenario.success,
    ),
    (
      '67752',
      '/investor/profile/payment-methods/card',
      852.0,
      true,
      MockScenario.success,
    ),

    (
      '51866',
      '/investor/kyc/individual/tax',
      885.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '52831',
      '/investor/kyc/individual/funds',
      1303.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '55075',
      '/investor/kyc/trust/overview',
      1118.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '56002',
      '/investor/kyc/trust/deed',
      948.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '55789',
      '/investor/kyc/trust/authority',
      1053.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '58691',
      '/investor/kyc/trust/funds',
      1195.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '78683',
      '/investor/kyc/company/overview',
      1118.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '80090',
      '/investor/kyc/company/registration',
      1171.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '80278',
      '/investor/kyc/company/moi',
      972.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '82022',
      '/investor/kyc/company/funds',
      1454.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '82344',
      '/investor/kyc/stokvel/overview',
      1118.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '83570',
      '/investor/kyc/stokvel/constitution',
      1118.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '83650',
      '/investor/kyc/stokvel/resolution',
      963.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '83989',
      '/investor/kyc/stokvel/bank',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '84071',
      '/investor/kyc/stokvel/funds',
      1152.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '50308',
      '/investor/kyc/individual/overview',
      1147.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '46609',
      '/investor/kyc/individual/identity',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '46538',
      '/investor/kyc/individual/identity',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '46665',
      '/investor/kyc/individual/address',
      852.0,
      true,
      MockScenario.incompleteKyc,
    ),
    (
      '46795',
      '/investor/kyc/individual/bank',
      1249.0,
      true,
      MockScenario.incompleteKyc,
    ),
  ];
  for (final (node, path, height, authenticated, scenario) in cases) {
    testWidgets('Investor authored composition $node $path', (tester) async {
      tester.view.physicalSize = Size(node == '45427' ? 394 : 393, height);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final trustReview = const {'59009', '59280', '59559'}.contains(node);
      var mockNow = node == '57726'
          ? DateTime(2026, 7, 10, 14, 32)
          : trustReview
          ? DateTime(2026, 7, 18)
          : null;
      final dependencies = await AppDependencies.create(
        mockClock: mockNow == null ? null : () => mockNow!,
        environment: AppEnvironment(
          mockDelay:
              const {
                '75725',
                '72779',
                '46883',
                '47442',
                '47514',
                '47906',
              }.contains(node)
              ? const Duration(seconds: 2)
              : Duration.zero,
          mockScenario: scenario,
        ),
      );
      if (authenticated) {
        dependencies.session.signIn(
          AppUser(
            hasProfilePhoto: node != '67563',
            id: 'visual-investor',
            address: investorNaturalReviewFrames.contains(node)
                ? 'Cape Town, South Africa'
                : '14 Protea Ave, Randburg, Gauteng, 2184',
            name: 'Babatunde Yusuf',
            email: investorProfileRootFrames.contains(node)
                ? 'bafreka@gmail.com'
                : 'yusufbabatunde48@gmail.com',
          ),
          experience: Experience.investor,
        );
      } else if (path != '/investor/onboarding') {
        dependencies.session.completeOnboarding();
      }
      await tester.runAsync(
        () => seedInvestorChecklistFrame(
          dependencies.container<KycRepository>(),
          node,
        ),
      );
      await tester.runAsync(
        () => seedInvestorMemberFrame(
          dependencies.container<KycRepository>(),
          node == '57726' ? '57633' : node,
        ),
      );
      if (trustReview) {
        mockNow = DateTime(2026, 7, 22);
        await tester.runAsync(() async {
          final repository = dependencies.container<KycRepository>();
          final loaded = await repository.load(EntityType.trust);
          expect(loaded, isA<Success<KycDraft>>());
          final saved = repository.save((loaded as Success<KycDraft>).value);
          expect(saved, isA<Success<KycDraft>>());
        });
      }
      await tester.runAsync(
        () => prepareInvestorProfileFrame(dependencies, node),
      );
      await tester.runAsync(
        () => seedInvestorNaturalReviewFrame(
          dependencies.container<KycRepository>(),
          node == '52549' ? '53372' : node,
        ),
      );
      await tester.runAsync(
        () => seedInvestorIdentityFrame(
          dependencies.container<KycRepository>(),
          node,
        ),
      );
      await tester.runAsync(
        () => seedInvestorEntityDocumentFrame(
          dependencies.container<KycRepository>(),
          node,
        ),
      );
      await tester.runAsync(() => prepareInvestorHomeFrame(dependencies, node));
      await tester.runAsync(
        () => prepareInvestorExploreFrame(dependencies, node),
      );
      if (node == '67069' || node == '67274') {
        await tester.runAsync(
          () => dependencies
              .container<InvestorAccountRepository>()
              .setDefaultPaymentMethod(
                node == '67069' ? 'individual-bank' : 'individual-visa',
                false,
              ),
        );
      }
      final router = createAppRouter(dependencies, initialLocation: path);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: DevelopifyApp(dependencies: dependencies, router: router),
        ),
      );
      await tester.pumpAndSettle();
      await showInvestorProfileFrame(tester, node);
      await showInvestorSignupFrame(tester, node);
      await showInvestorAuthFrame(tester, node);
      await showInvestorHomeFrame(tester, node);
      await showInvestorExploreFrame(tester, node);
      if (node == '57726') {
        tester
            .widget<KycMemberScreen>(find.byType(KycMemberScreen))
            .store
            .edit('sms', 'true');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Send email'));
        await tester.pumpAndSettle();
        expect(find.text('Invite Sent!'), findsOneWidget);
      }
      if (node == '50218' || node == '54985') {
        await tester.tap(find.text('Natural Person'));
        await tester.pumpAndSettle();
      }
      if (node == '38249' || node == '38290') {
        for (var index = 0; index < (node == '38249' ? 1 : 2); index++) {
          await tester.tap(
            find.bySemanticsLabel(
              'Onboarding page ${index + 1} of 3. Next page',
            ),
          );
          await tester.pumpAndSettle();
        }
      }
      if (node == '38385') {
        await tester.tap(find.byKey(const ValueKey('terms-declaration')));
        await tester.pumpAndSettle();
      }
      if (node == '38469' || node == '38560') {
        await tester.tap(find.widgetWithText(AppButton, 'Create account'));
        await tester.pumpAndSettle();
        if (node == '38560') {
          await tester.tap(find.text('Natural Person'));
          await tester.pumpAndSettle();
        }
      }
      if (node == '67274' || node == '67386') {
        await tester.tap(
          find.bySemanticsLabel('More options for Visa ending 2526'),
        );
        await tester.pumpAndSettle();
      }
      if (const {'63547', '63594', '67705', '67752'}.contains(node)) {
        for (final (index, value) in [
          (0, 'Babatunde Yusuf'),
          (1, '4111 1111 1111 1111'),
          (2, '12 / 29'),
          (3, '123'),
        ]) {
          await tester.enterText(find.byType(TextField).at(index), value);
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(
          find.bySemanticsLabel('Save card for future payments'),
        );
        await tester.pumpAndSettle();
        if (node == '67752' || node == '63594') {
          await tester.tap(find.widgetWithText(AppButton, 'Add Card'));
          await tester.pumpAndSettle();
          expect(find.text('Card Added'), findsOneWidget);
        }
      }
      if (node == '78415' || node == '78521') {
        final tab = find.widgetWithText(
          TextButton,
          node == '78415' ? 'Documents' : 'Updates',
        );
        await tester.ensureVisible(tab);
        await tester.pumpAndSettle();
        await tester.tap(tab);
        await tester.pumpAndSettle();
      }
      if ({
        '72433',
        '72515',
        '72574',
        '72684',
        '72779',
        '72849',
      }.contains(node)) {
        final store = tester
            .widget<TransferScreen>(find.byType(TransferScreen))
            .store;
        await tester.enterText(
          find.byKey(const ValueKey('investor-amount')),
          '500',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(
          find.bySemanticsLabel('Select Access Bank account ending 0119'),
        );
        await tester.pumpAndSettle();
        expect(store.method!.lastFour, '0119');
        if (node != '72433') {
          await tester.tap(find.widgetWithText(AppButton, 'Withdraw'));
          await tester.pumpAndSettle();
          expect(store.stage, TransferStage.review);
          if (node != '72515') {
            await tester.tap(find.text('Authorize with PIN'));
            await tester.pumpAndSettle();
            if (node != '72684') {
              await tester.tap(find.text('Use PIN Instead'));
              await tester.pumpAndSettle();
              for (final digit in (node == '72574' ? '123' : '1234').split(
                '',
              )) {
                await tester.tap(find.widgetWithText(TextButton, digit));
                await tester.pump(const Duration(milliseconds: 16));
              }
              if (node == '72779') {
                await tester.pump(const Duration(milliseconds: 100));
                expect(store.stage, TransferStage.processing);
              } else {
                await tester.pumpAndSettle();
                expect(
                  store.stage,
                  node == '72849'
                      ? TransferStage.success
                      : TransferStage.authorizing,
                );
              }
            }
          }
        }
      }
      if (node == '62905') {
        await tester.tap(find.text('Bank Transfer'));
        await tester.pumpAndSettle();
      }
      if ([
        '62965',
        '62999',
        '63074',
        '63149',
        '63210',
        '63307',
        '63419',
      ].contains(node)) {
        await tester.tap(find.text('Debit Card'));
        await tester.pumpAndSettle();
        final store = tester
            .widget<TransferScreen>(find.byType(TransferScreen))
            .store;
        if (node == '62965') {
          expect(find.text('No Cards Added Yet'), findsOneWidget);
          expect(find.byKey(const ValueKey('investor-amount')), findsNothing);
        } else if (node != '62999') {
          await tester.enterText(
            find.byKey(const ValueKey('investor-amount')),
            '500',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          if (node != '63074') {
            await tester.tap(find.text('Continue'));
            await tester.pumpAndSettle();
            expect(store.stage, TransferStage.review);
            if (node != '63149') {
              await tester.tap(find.text('Confirm Payment'));
              await tester.pumpAndSettle();
              if (node != '63210') {
                await tester.tap(find.text('Use PIN Instead'));
                await tester.pumpAndSettle();
                for (final digit in (node == '63307' ? '123' : '1234').split(
                  '',
                )) {
                  await tester.tap(find.widgetWithText(TextButton, digit));
                  await tester.pumpAndSettle();
                }
                expect(
                  store.stage,
                  node == '63307'
                      ? TransferStage.authorizing
                      : TransferStage.success,
                );
              }
            }
          }
        }
      }
      if (node == '75302') {
        await tester.tap(find.text('R1000'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<InvestmentScreen>(find.byType(InvestmentScreen))
              .store
              .amount,
          const MonetaryAmount(100000, Currency.zar),
        );
      }
      if ([
        '75370',
        '75437',
        '75504',
        '75607',
        '75725',
        '75802',
        '75888',
      ].contains(node)) {
        await tester.enterText(
          find.byKey(const ValueKey('investor-amount')),
          '1000',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Review Investment'));
        await tester.pumpAndSettle();
        final store = tester
            .widget<InvestmentScreen>(find.byType(InvestmentScreen))
            .store;
        expect(store.stage, InvestmentStage.review);
        if (node != '75370') {
          final consent = find.bySemanticsLabel('Accept investment risks');
          await tester.ensureVisible(consent);
          await tester.tap(consent);
          await tester.pumpAndSettle();
          if (node != '75437') {
            await tester.tap(find.text('Authorize with PIN'));
            await tester.pumpAndSettle();
            if (node != '75504') {
              await tester.tap(find.text('Use PIN Instead'));
              await tester.pumpAndSettle();
              if (node == '75888') {
                (dependencies.container<InvestorAccountRepository>()
                        as MockInvestorAccountRepository)
                    .behavior
                    .failNext();
              }
              final digits = node == '75607' ? '123' : '1234';
              for (final digit in digits.split('')) {
                await tester.tap(find.widgetWithText(TextButton, digit));
                await tester.pump(const Duration(milliseconds: 16));
              }
              if (node == '75725') {
                await tester.pump(const Duration(milliseconds: 100));
                expect(store.stage, InvestmentStage.processing);
              } else {
                await tester.pumpAndSettle();
                expect(store.stage, switch (node) {
                  '75802' => InvestmentStage.success,
                  '75888' => InvestmentStage.failure,
                  _ => InvestmentStage.authorizing,
                });
              }
            }
          }
        }
      }
      if (node == '59559') {
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();
        expect(find.text('Submitted for review'), findsOneWidget);
      }
      if (node == '83906') {
        expect(find.text('Minutes for investment'), findsOneWidget);
        expect(
          tester.widget<KycScreen>(find.byType(KycScreen)).store.canContinue,
          isTrue,
        );
      }
      if (node == '77606' || node == '77741') {
        await tester.tap(
          find.text(node == '77606' ? 'Completed' : 'Underfunded').last,
        );
        await tester.pumpAndSettle();
      }
      if (node == '46609') {
        tester
            .widget<KycScreen>(find.byType(KycScreen))
            .store
            .edit('idType', 'International passport');
        await tester.pumpAndSettle();
      }
      if (node == '52052') {
        final store = tester
            .widget<KycTaxScreen>(find.byType(KycTaxScreen))
            .store;
        store.edit('taxCountry', 'South Africa');
        store.edit('tin', '22-394-871-0');
        await tester.pumpAndSettle();
      }
      if (node == '76088') {
        final store = tester
            .widget<ExploreFilterScreen>(find.byType(ExploreFilterScreen))
            .store;
        store.setLocation('Pretoria');
        store.selectCategory(ProjectCategory.industrial);
        store.setSort(ProjectSort.newest);
        store.setReturn(1000);
        for (final status in ProjectFundingStatus.values) {
          store.toggleFunding(status);
        }
        await tester.pumpAndSettle();
      }
      await showInvestorDocumentFrame(tester, dependencies, node);
      if (node == '51954' || node == '52939') {
        final store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        if (node == '51954') {
          store.edit('secondaryTax', 'true');
          store.edit('pep', KycTaxPlan.pepYes);
          store.edit('sanctions', 'true');
          store.edit('declaration', 'true');
        } else {
          store.edit(
            'fundSources',
            store.step!.fields.first.options.take(2).join('|'),
          );
        }
        await tester.pumpAndSettle();
      }
      if (node == '52435' || node == '52675') {
        final store = tester
            .widget<KycTaxScreen>(find.byType(KycTaxScreen))
            .store;
        if (node == '52435') {
          store.edit('sanctions', 'true');
          store.edit('declaration', 'true');
          final uploaded = store.upload(
            'pepWealthProof',
            name: 'SARS assets declarations.pdf',
            bytes: 120 * 1024,
            mimeType: 'application/pdf',
          );
          await tester.pumpAndSettle();
          expect(await uploaded, isTrue);
        } else {
          store.edit('taxCountry', 'South Africa');
          store.edit('tin', '22-394-871-0');
          store.edit('usPerson', 'true');
          store.edit('secondaryCertification', 'true');
          await tester.pumpAndSettle();
        }
      }
      if (const {'47174', '47728', '47817', '51410', '52549'}.contains(node)) {
        if (node == '47174' || node == '47728' || node == '47817') {
          await showInvestorDocumentFrame(
            tester,
            dependencies,
            node == '47174' ? '47076' : '47586',
          );
        }
        final button = find.widgetWithText(
          AppButton,
          node == '47174' ? 'Submit for verification' : 'Continue',
        );
        if (node == '51410') {
          final store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
          expect(
            store.canContinue,
            isTrue,
            reason: '${store.selectedStep}: ${store.errors} ${store.error}',
          );
        }
        await tester.tap(button);
        await tester.pumpAndSettle();
        if (node == '51410') {
          final store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
          expect(
            store.error,
            isNull,
            reason: '${store.selectedStep}: ${store.errors}',
          );
          expect(store.selectedStep, 'overview');
        }
        expect(find.text('Verification in Progress!'), findsOneWidget);
      }
      if (const {'56091', '56289', '59858', '84283'}.contains(node)) {
        final field = find.byKey(
          ValueKey(switch (node) {
            '56289' => 'field-Trust Type',
            '84283' => 'field-Bank Type',
            _ => 'field-Master of the High Court Office',
          }),
        );
        await tester.tap(field);
        await tester.pumpAndSettle();
      }
      expect(
        router.routeInformationProvider.value.uri.path,
        Uri.parse(path).path,
      );
      expect(tester.takeException(), isNull, reason: path);
      await captureFidelity(
        tester,
        boundary,
        '4105-$node',
        target: node == '43575'
            ? find
                  .descendant(
                    of: find.byType(InvestorBalanceHeader),
                    matching: find.byType(RepaintBoundary),
                  )
                  .first
            : null,
      );
      expect(tester.takeException(), isNull, reason: path);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await tester.runAsync(dependencies.dispose);
    });
  }
}
