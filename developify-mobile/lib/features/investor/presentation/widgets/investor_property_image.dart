import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class InvestorPropertyImage extends StatelessWidget {
  const InvestorPropertyImage(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.excludeFromSemantics = true,
  });
  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    if (asset == AppAssets.projectMarulaHeights) {
      return SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          fit: fit,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: 313,
            height: 163,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.755724906921387),
              child: Stack(
                children: [
                  Positioned(
                    left: -313 * 0.028788885101675987 / 0.9429965615272522,
                    top: -163 * 0.002392120659351349 / 0.7857300639152527,
                    width: 313 / 0.9429965615272522,
                    height: 163 / 0.7857300639152527,
                    child: Image.asset(
                      asset,
                      fit: BoxFit.fill,
                      excludeFromSemantics: excludeFromSemantics,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final detailPhoto = const {
      AppAssets.investorProjectHero,
      AppAssets.investorUpdatePlanning,
      AppAssets.investorUpdateReview,
      AppAssets.investorUpdateSiteVisit,
    }.contains(asset);
    final displayWidth = width != null && width!.isFinite
        ? width!
        : MediaQuery.sizeOf(context).width;
    final image = Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      excludeFromSemantics: excludeFromSemantics,
      filterQuality: detailPhoto ? FilterQuality.high : FilterQuality.medium,
      cacheWidth: detailPhoto
          ? math.max(
              1024,
              (displayWidth * MediaQuery.devicePixelRatioOf(context)).ceil(),
            )
          : null,
    );
    final shade = switch (asset) {
      AppAssets.projectSaffronTowers => AppColors.investorImageOverlay,
      AppAssets.projectCoastlineVillas ||
      AppAssets.investorProjectHero ||
      AppAssets.investorUpdatePlanning ||
      AppAssets.investorUpdateReview ||
      AppAssets.investorUpdateSiteVisit => AppColors.blackAlpha51,
      _ => AppColors.transparent,
    };
    return shade == AppColors.transparent
        ? image
        : ColorFiltered(
            colorFilter: ColorFilter.mode(shade, BlendMode.srcATop),
            child: image,
          );
  }
}
