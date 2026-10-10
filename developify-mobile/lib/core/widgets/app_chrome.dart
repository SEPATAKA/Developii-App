import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

enum AppHeaderLayout { centeredTitle, backAndAction }

enum AppHeaderAppearance { light, dark }

class AppPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPageAppBar({
    super.key,
    this.title,
    this.onBack,
    this.trailing,
    this.showBack = true,
    this.layout = AppHeaderLayout.centeredTitle,
    this.appearance = AppHeaderAppearance.light,
    this.titleCenterOffset = 0,
    this.titleTopOffset = 0,
    this.titleOverflow = TextOverflow.visible,
    this.leadingInset,
    this.topInset,
    this.backAsset,
    this.backAssetSize = 24.75,
  });
  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBack;
  final AppHeaderLayout layout;
  final AppHeaderAppearance appearance;
  final double titleCenterOffset;
  final double titleTopOffset;
  final TextOverflow titleOverflow;
  final double? leadingInset;
  final double? topInset;
  final String? backAsset;
  final double backAssetSize;
  @override
  Size get preferredSize => Size.fromHeight(64.w);
  @override
  Widget build(BuildContext context) {
    final hitSize = 44.0;
    final dark = appearance == AppHeaderAppearance.dark;
    final top = topInset?.w ?? (dark ? 7.w : 17.w);
    final visualSize = 33.w;
    final hitInset = (hitSize - visualSize) / 2;
    final backInset =
        leadingInset?.w ??
        (dark
            ? 16.w
            : layout == AppHeaderLayout.backAndAction
            ? 22.w
            : 13.w);
    return Material(
      color: dark ? AppColors.transparent : AppColors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Stack(
            children: [
              if (showBack)
                Positioned(
                  left: backInset - hitInset,
                  top: top - hitInset,
                  child: AppBackButton(
                    onPressed: onBack,
                    appearance: appearance,
                    asset: backAsset,
                    assetSize: backAssetSize,
                  ),
                ),
              if (title != null)
                Positioned(
                  left: layout == AppHeaderLayout.backAndAction
                      ? 141.w
                      : (60 + titleCenterOffset).w,
                  right: layout == AppHeaderLayout.backAndAction
                      ? 180.w
                      : (60 - titleCenterOffset).w,
                  top: top + titleTopOffset.w,
                  height: visualSize,
                  child: Center(
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      softWrap: false,
                      overflow: titleOverflow,
                      style: AppTextStyles.text(
                        16,
                        weight: FontWeight.w700,
                        color: dark ? AppColors.white : AppColors.black,
                      ),
                    ),
                  ),
                ),
              if (trailing != null)
                Positioned(
                  right: layout == AppHeaderLayout.backAndAction ? 12.w : 13.w,
                  top: top - hitInset,
                  height: hitSize,
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.appearance = AppHeaderAppearance.light,
    this.asset,
    this.assetSize = 24.75,
  });
  final VoidCallback? onPressed;
  final AppHeaderAppearance appearance;
  final String? asset;
  final double assetSize;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Back',
    child: InkResponse(
      onTap:
          onPressed ??
          () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(Routes.home);
            }
          },
      radius: 24.r,
      child: SizedBox.square(
        dimension: 44,
        child: Center(
          child: Container(
            width: 33.r,
            height: 33.r,
            decoration: BoxDecoration(
              color: appearance == AppHeaderAppearance.dark
                  ? AppColors.transparent
                  : AppColors.neutral100,
              shape: BoxShape.circle,
              border: appearance == AppHeaderAppearance.dark
                  ? null
                  : Border.all(color: AppColors.borderStrong, width: 1.375.w),
            ),
            child: AppIcon(
              asset ??
                  (appearance == AppHeaderAppearance.dark
                      ? AppAssets.backDark
                      : AppAssets.back),
              size: assetSize,
            ),
          ),
        ),
      ),
    ),
  );
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    this.title,
    required this.child,
    this.bottom,
    this.trailing,
    this.onBack,
    this.padding = true,
    this.showBack = true,
    this.headerLayout = AppHeaderLayout.centeredTitle,
    this.headerLeadingInset,
    this.headerTopInset,
    this.titleCenterOffset = 0,
    this.titleTopOffset = 0,
    this.titleOverflow = TextOverflow.visible,
  });
  final String? title;
  final Widget child;
  final Widget? bottom;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool padding;
  final bool showBack;
  final AppHeaderLayout headerLayout;
  final double? headerLeadingInset;
  final double? headerTopInset;
  final double titleCenterOffset;
  final double titleTopOffset;
  final TextOverflow titleOverflow;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      appBar: AppPageAppBar(
        title: title,
        onBack: onBack,
        trailing: trailing,
        showBack: showBack,
        layout: headerLayout,
        leadingInset: headerLeadingInset,
        topInset: headerTopInset,
        titleCenterOffset: titleCenterOffset,
        titleTopOffset: titleTopOffset,
        titleOverflow: titleOverflow,
      ),
      body: SafeArea(
        top: false,
        bottom: bottom == null,
        child: padding
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.page.w),
                child: child,
              )
            : child,
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              minimum: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: bottom!,
              ),
            ),
    ),
  );
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.large = false,
    this.light = false,
    this.textSize,
    this.symbolSize,
    this.symbolGap,
  });
  final bool large;
  final bool light;
  final double? textSize;
  final double? symbolSize;
  final double? symbolGap;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppIcon(AppAssets.brandSymbol, size: symbolSize ?? (large ? 49 : 23)),
      SizedBox(width: (symbolGap ?? (large ? 13 : 6)).w),
      Text(
        'developify',
        style: AppTextStyles.text(
          textSize ?? (large ? 49 : 23),
          weight: FontWeight.w700,
          color: light ? AppColors.white : AppColors.darkTeal,
        ),
      ),
    ],
  );
}

class MeshBackground extends StatelessWidget {
  const MeshBackground({
    super.key,
    required this.child,
    this.asset = AppAssets.homeMesh,
  });
  final Widget child;
  final String asset;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.darkTeal,
        image: DecorationImage(
          image: AssetImage(asset),
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
        ),
      ),
      child: child,
    ),
  );
}
