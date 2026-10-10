import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract final class AppColors {
  static const kycSwitchTrack = Color.fromRGBO(242, 244, 247, 1);
  static const kycSwitchShadow = Color.fromRGBO(16, 24, 40, 1);
  static const filterSwitchTrack = Color.fromRGBO(233, 239, 246, 1);
  static const filterSwitchShadow = Color.fromRGBO(14, 15, 17, 1);
  static const investorSliderTrack = Color.fromRGBO(242, 242, 243, 1);
  static const investorHomeFilm = Color.fromRGBO(217, 217, 217, .01);
  static const kycProgressText = Color.fromRGBO(167, 243, 208, 1);
  static const kycWarningBorder = Color.fromRGBO(251, 223, 162, 1);
  static const investorSearchEmptyText = Color.fromRGBO(52, 52, 52, 1);
  static const investorSearchHint = Color.fromRGBO(140, 140, 140, 1);
  static const investorProfileStat = Color.fromRGBO(239, 238, 240, .1);
  static const investorProfileTier = Color.fromRGBO(1, 75, 54, .3);
  static const investorLogoutButton = Color.fromRGBO(217, 45, 32, 1);
  static const investorMailRed = Color.fromRGBO(248, 113, 113, 1);
  static const investorMailYellow = Color.fromRGBO(251, 191, 36, 1);
  static const investorMailGreen = Color.fromRGBO(52, 211, 153, 1);
  static const gray900 = Color.fromRGBO(17, 24, 39, 1);
  static const neutral100 = Color.fromRGBO(245, 245, 245, 1);
  static const neutral300 = Color.fromRGBO(212, 212, 212, 1);
  static const shadowInk = Color.fromRGBO(14, 18, 27, 1);
  static const shadowCharcoal = Color.fromRGBO(27, 28, 29, 1);
  static const successBright = Color.fromRGBO(31, 193, 107, 1);
  static const errorDark = Color.fromRGBO(181, 0, 0, 1);
  static const coolGraySurface = Color.fromRGBO(240, 242, 244, 1);
  static const gray300 = Color.fromRGBO(209, 213, 219, 1);
  static const coolGraySurfaceStrong = Color.fromRGBO(241, 243, 245, 1);
  static const errorVivid = Color.fromRGBO(255, 0, 0, 1);
  static const mutedSlate = Color.fromRGBO(82, 88, 102, 1);
  static const black = Color.fromRGBO(0, 0, 0, 1);
  static const deepInk = Color.fromRGBO(11, 18, 32, 1);
  static const growthSurface = Color.fromRGBO(240, 252, 241, 1);
  static const cyanLink = Color.fromRGBO(0, 139, 157, 1);
  static const errorOrange = Color.fromRGBO(255, 51, 17, 1);
  static const neutralBorder = Color.fromRGBO(209, 209, 209, 1);
  static const successLight = Color.fromRGBO(236, 255, 240, 1);
  static const amber50 = Color.fromRGBO(255, 251, 235, 1);
  static const amber300 = Color.fromRGBO(252, 211, 77, 1);
  static const successForest = Color.fromRGBO(34, 139, 83, 1);
  static const successForestDark = Color.fromRGBO(0, 104, 52, 1);
  static const mutedNeutral = Color.fromRGBO(120, 120, 122, 1);
  static const skyTint = Color.fromRGBO(246, 252, 255, 1);
  static const skyBorder = Color.fromRGBO(206, 230, 255, 1);
  static const warningPale = Color.fromRGBO(255, 238, 200, 1);
  static const amber900 = Color.fromRGBO(120, 53, 15, 1);
  static const slate50 = Color.fromRGBO(248, 250, 252, 1);
  static const slate100 = Color.fromRGBO(241, 245, 249, 1);
  static const slate200 = Color.fromRGBO(226, 232, 240, 1);
  static const slate500 = Color.fromRGBO(100, 116, 139, 1);
  static const errorTint = Color.fromRGBO(255, 248, 246, 1);
  static const neutralTrack = Color.fromRGBO(217, 217, 217, 1);
  static const blackAlpha168 = Color.fromRGBO(0, 0, 0, 168 / 255);
  static const identityPhotoScrim = Color.fromRGBO(0, 0, 0, .75);
  static const neutralSeparator = Color.fromRGBO(235, 235, 235, 1);
  static const coolGrayBackground = Color.fromRGBO(246, 248, 250, 1);
  static const neutral500 = Color.fromRGBO(115, 115, 115, 1);
  static const neutral600 = Color.fromRGBO(82, 82, 82, 1);
  static const rose600 = Color.fromRGBO(225, 29, 72, 1);
  static const rose100 = Color.fromRGBO(255, 228, 230, 1);
  static const green500 = Color.fromRGBO(34, 197, 94, 1);
  static const mintHighlight = Color.fromRGBO(211, 243, 234, 1);
  static const violetBright = Color.fromRGBO(147, 6, 234, 1);
  static const violetBrightAlpha13 = Color.fromRGBO(147, 6, 234, 13 / 255);
  static const diasporaBadge = Color.fromRGBO(208, 10, 197, 1);
  static const diasporaBadgeBackground = Color.fromRGBO(208, 10, 197, .06);
  static const blueStrong = Color.fromRGBO(12, 92, 210, 1);
  static const bluePale = Color.fromRGBO(233, 246, 255, 1);
  static const navy = Color.fromRGBO(3, 51, 85, 1);
  static const navyAlpha18 = Color.fromRGBO(3, 51, 85, 18 / 255);
  static const greenStrong = Color.fromRGBO(0, 154, 46, 1);
  static const emerald600 = Color.fromRGBO(5, 150, 105, 1);
  static const emerald700 = Color.fromRGBO(4, 120, 87, 1);
  static const mutedCool = Color.fromRGBO(103, 111, 116, 1);
  static const emerald100 = Color.fromRGBO(209, 250, 229, 1);
  static const emerald900 = Color.fromRGBO(6, 78, 59, 1);
  static const blackAlpha64 = Color.fromRGBO(0, 0, 0, 64 / 255);
  static const emerald500 = Color.fromRGBO(16, 185, 129, 1);
  static const amber200 = Color.fromRGBO(253, 230, 138, 1);
  static const blackAlpha38 = Color.fromRGBO(0, 0, 0, 38 / 255);
  static const blackAlpha51 = Color.fromRGBO(0, 0, 0, 51 / 255);
  static const amber800 = Color.fromRGBO(146, 64, 14, 1);
  static const amber100 = Color.fromRGBO(254, 243, 199, 1);
  static const red600 = Color.fromRGBO(220, 38, 38, 1);
  static const redMuted = Color.fromRGBO(174, 34, 34, 1);
  static const red900 = Color.fromRGBO(127, 29, 29, 1);
  static const blackAlpha77 = Color.fromRGBO(0, 0, 0, 77 / 255);
  static const amber500 = Color.fromRGBO(245, 158, 11, 1);
  static const sky700 = Color.fromRGBO(3, 105, 161, 1);
  static const violet600 = Color.fromRGBO(124, 58, 237, 1);
  static const cyan700 = Color.fromRGBO(14, 116, 144, 1);
  static const cyan600 = Color.fromRGBO(8, 145, 178, 1);
  static const blue50 = Color.fromRGBO(239, 246, 255, 1);
  static const blackAlpha20 = Color.fromRGBO(0, 0, 0, 20 / 255);
  static const emerald50 = Color.fromRGBO(236, 253, 245, 1);
  static const blue100 = Color.fromRGBO(219, 234, 254, 1);
  static const blue800 = Color.fromRGBO(30, 64, 175, 1);
  static const purple100 = Color.fromRGBO(243, 232, 255, 1);
  static const purple800 = Color.fromRGBO(107, 33, 168, 1);
  static const fuchsia50 = Color.fromRGBO(253, 244, 255, 1);
  static const blackAlpha26 = Color.fromRGBO(0, 0, 0, 26 / 255);
  static const propertyWarmShadow = Color.fromRGBO(252, 212, 159, .36);
  static const propertyReview = Color.from(
    alpha: 1,
    red: 1,
    green: .6815592646598816,
    blue: .26513671875,
  );
  static const propertyReviewText = Color.from(
    alpha: 1,
    red: .8894230723381042,
    green: .5427449941635132,
    blue: .0893966406583786,
  );
  static const cardShadow = Color.fromRGBO(16, 24, 40, .06);
  static const onboardingEmeraldSoft = Color.fromRGBO(5, 150, 105, .15);
  static const onboardingEmeraldMedium = Color.fromRGBO(5, 150, 105, .35);

  static const investorDarkSurface = Color.fromRGBO(6, 12, 12, 1);
  static const investorImageOverlay = Color.fromRGBO(0, 0, 0, .36);
  static const investorCard = Color.fromRGBO(249, 250, 251, 1);
  static const investorBankEmptyHint = Color.fromRGBO(135, 147, 166, 1);
  static const investorPaymentIcon = Color.fromRGBO(230, 242, 244, 1);
  static const investorTaxBorder = Color.fromRGBO(119, 172, 255, 1);
  static const investorPepBorder = Color.fromRGBO(251, 223, 162, 1);
  static const investorPepText = Color.fromRGBO(96, 38, 0, 1);
  static const investorPepHint = Color.fromRGBO(59, 130, 246, 1);
  static const investorLink = Color.fromRGBO(1, 128, 145, 1);
  static const investorGrowth = Color.fromRGBO(104, 228, 112, 1);
  static const investorBalanceGrowth = Color.fromRGBO(89, 191, 91, 1);
  static const investorBalanceFraction = Color.fromRGBO(179, 187, 209, 1);
  static const investorResidential = Color.fromRGBO(1, 128, 145, 1);
  static const investorHospitality = Color.fromRGBO(44, 96, 47, 1);
  static const investorCommercial = Color.fromRGBO(1, 75, 54, 1);
  static const investorCategoryText = Color.fromRGBO(104, 228, 112, 1);
  static const investorProjectTitle = Color.fromRGBO(23, 40, 30, 1);
  static const investorHospitalityText = Color.fromRGBO(154, 237, 159, 1);
  static const investorCommercialText = Color.fromRGBO(208, 247, 211, 1);
  static const investorCalculatorText = Color.fromRGBO(2, 126, 92, 1);
  static const investorCalculatorBody = Color.fromRGBO(3, 162, 117, 1);
  static const investorVerificationText = Color.fromRGBO(140, 84, 0, 1);
  static const investorVerificationBorder = Color.fromRGBO(255, 210, 126, 1);
  static const primary = Color.fromRGBO(3, 178, 129, 1);
  static const darkTeal = Color.fromRGBO(10, 58, 60, 1);
  static const meshTeal = Color.fromRGBO(1, 128, 145, 1);
  static const successSurface = Color.fromRGBO(208, 247, 214, 1);
  static const investorTransactionCredit = Color.fromRGBO(0, 154, 46, 1);
  static const investorTransactionSeparator = Color.fromRGBO(196, 203, 212, 1);
  static const investorTransactionSuccess = Color.fromRGBO(3, 109, 55, 1);
  static const investorTransactionSuccessSurface = Color.fromRGBO(
    235,
    255,
    238,
    1,
  );
  static const investorTransactionSuccessBorder = Color.fromRGBO(
    128,
    217,
    151,
    1,
  );
  static const successBadgeText = Color.fromRGBO(0, 112, 0, 1);
  static const actionRequiredSurface = Color.fromRGBO(255, 208, 199, 1);
  static const actionRequiredBorder = Color.fromRGBO(255, 180, 171, 1);
  static const pendingBadgeSurface = Color.fromRGBO(255, 249, 235, 1);
  static const pendingBadgeBorder = Color.fromRGBO(255, 211, 98, 1);
  static const mintBadgeBorder = Color.fromRGBO(139, 220, 197, 1);
  static const mint = Color.fromRGBO(230, 247, 242, 1);
  static const secondaryButton = Color.fromRGBO(3, 178, 129, .12);
  static const description = Color.fromRGBO(75, 85, 99, 1);
  static const mintBorder = Color.fromRGBO(177, 231, 216, 1);
  static const mintText = Color.fromRGBO(2, 98, 71, 1);
  static const lime = Color.fromRGBO(104, 228, 112, 1);
  static const white = Color.fromRGBO(255, 255, 255, 1);
  static const text = Color.fromRGBO(3, 7, 18, 1);
  static const body = Color.fromRGBO(23, 23, 23, 1);
  static const muted = Color.fromRGBO(107, 114, 128, 1);
  static const placeholder = Color.fromRGBO(163, 163, 163, 1);
  static const iconMuted = Color.fromRGBO(156, 163, 175, 1);
  static const surface = Color.fromRGBO(249, 250, 251, 1);
  static const disabled = Color.fromRGBO(250, 250, 250, 1);
  static const border = Color.fromRGBO(243, 244, 246, 1);
  static const borderStrong = Color.fromRGBO(229, 231, 235, 1);
  static const error = Color.fromRGBO(216, 19, 19, 1);
  static const errorSurface = Color.fromRGBO(255, 236, 231, 1);
  static const blue = Color.fromRGBO(68, 133, 255, 1);
  static const blueSurface = Color.fromRGBO(213, 227, 252, 1);
  static const review = Color.fromRGBO(255, 177, 76, 1);
  static const reviewSurface = Color.fromRGBO(255, 239, 217, 1);
  static const warning = Color.fromRGBO(134, 96, 0, 1);
  static const warningSurface = Color.fromRGBO(255, 247, 227, 1);
  static const tealCard = Color.fromRGBO(18, 63, 64, 1);
  static const overlay = Color.fromRGBO(0, 0, 0, .46);
  static const modalScrim = Color.fromRGBO(0, 0, 0, .66);
  static const glass = Color.fromRGBO(239, 238, 240, .1);
  static const transparent = Color.fromRGBO(0, 0, 0, 0);
}

abstract final class AppSpacing {
  static const page = 12.0;
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const section = 32.0;
}

abstract final class AppRadii {
  static const field = 10.0;
  static const card = 16.0;
  static const sheet = 24.0;
  static const pill = 999.0;
}

abstract final class AppDurations {
  static const page = Duration(milliseconds: 220);
  static const state = Duration(milliseconds: 180);
  static const routeForward = Duration(milliseconds: 280);
  static const routeReverse = Duration(milliseconds: 220);
  static const onboardingDwell = Duration(seconds: 5);
  static const onboardingPage = Duration(milliseconds: 420);
  static const onboardingKey = Duration(milliseconds: 2200);
  static bool reducedMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  static Duration motion(BuildContext context, Duration value) =>
      reducedMotion(context) ? Duration.zero : value;
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: AppColors.cardShadow, offset: Offset(0, 1), blurRadius: 3),
  ];
}

abstract final class AppTextStyles {
  static const fontFamily = 'TASA Orbiter Display';
  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.body,
    double height = 1.2,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size.sp,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing.w,
  );
  static TextStyle get heading =>
      text(32, weight: FontWeight.w700, color: AppColors.text);
  static TextStyle get title =>
      text(25, weight: FontWeight.w700, color: AppColors.text);
  static TextStyle get section =>
      text(16, weight: FontWeight.w700, color: AppColors.text);
  static TextStyle get body => text(16, color: AppColors.muted);
  static TextStyle get label => text(14, weight: FontWeight.w500);
  static TextStyle get caption => text(12, color: AppColors.muted);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: AppTextStyles.fontFamily,
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.darkTeal,
      surface: AppColors.white,
      error: AppColors.error,
    ),
    textTheme: TextTheme(
      bodyMedium: AppTextStyles.label,
      bodyLarge: AppTextStyles.body,
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.section,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.section,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.mintBorder,
      selectionHandleColor: AppColors.primary,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderStrong,
      thickness: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.white,
      ),
      side: const BorderSide(color: AppColors.borderStrong),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.borderStrong,
      ),
      thumbColor: const WidgetStatePropertyAll(AppColors.white),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.transparent),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet.r),
        ),
      ),
    ),
  );
}
