import 'package:developify_mobile/features/investor/presentation/widgets/investor_property_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';

class InvestorIconButton extends StatelessWidget {
  const InvestorIconButton({
    super.key,
    required this.asset,
    required this.label,
    required this.onPressed,
    this.size = 24,
    this.selected,
    this.alignment = Alignment.center,
  });
  final String asset;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final bool? selected;
  final AlignmentGeometry alignment;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: label,
    selected: selected,
    enabled: onPressed != null,
    onTap: onPressed,
    excludeSemantics: true,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Align(
            alignment: alignment,
            child: AppIcon(asset, size: size),
          ),
        ),
      ),
    ),
  );
}

class InvestorSurface extends StatelessWidget {
  const InvestorSurface({
    super.key,
    required this.child,
    this.padding,
    this.color = AppColors.investorCard,
    this.radius = 14,
    this.border = AppColors.borderStrong,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color color;
  final Color border;
  final double radius;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius.r),
      border: Border.all(color: border),
    ),
    child: Padding(padding: padding ?? EdgeInsets.all(16.w), child: child),
  );
}

class InvestorFavouriteButton extends StatelessWidget {
  const InvestorFavouriteButton({
    super.key,
    required this.selected,
    required this.label,
    required this.onPressed,
    this.diameter = 32,
    this.iconSize = 14,
    this.outline = AppAssets.investorProjectHeart,
  });
  final bool selected;
  final String label;
  final VoidCallback onPressed;
  final double diameter;
  final double iconSize;
  final String outline;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkResponse(
      onTap: onPressed,
      child: SizedBox.square(
        dimension: 44,
        child: Center(
          child: Container(
            width: diameter.w,
            height: diameter.w,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(
                selected ? AppAssets.investorProjectHeartSelected : outline,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class InvestorSectionHeading extends StatelessWidget {
  const InvestorSectionHeading(
    this.title, {
    super.key,
    this.action = 'See All',
    this.onAction,
    this.titleWeight = FontWeight.w700,
    this.actionSize = 14,
    this.actionWeight = FontWeight.w400,
    this.actionColor = AppColors.investorLink,
  });
  final String title;
  final String action;
  final VoidCallback? onAction;
  final FontWeight titleWeight;
  final double actionSize;
  final FontWeight actionWeight;
  final Color actionColor;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: AppTextStyles.text(
            16,
            weight: titleWeight,
            color: AppColors.text,
          ),
        ),
      ),
      if (onAction != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: AppTextStyles.text(
              actionSize,
              weight: actionWeight,
              color: actionColor,
            ),
          ),
        ),
    ],
  );
}

class InvestorProgress extends StatelessWidget {
  const InvestorProgress(
    this.basisPoints, {
    super.key,
    this.height = 5,
    this.label = 'Funding progress',
    this.backgroundColor = AppColors.borderStrong,
  });
  final int basisPoints;
  final double height;
  final String label;
  final Color backgroundColor;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: '${basisPoints / 100} percent',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: basisPoints.clamp(0, 10000) / 10000),
        duration: AppDurations.motion(context, AppDurations.state),
        builder: (_, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: height.w,
          backgroundColor: backgroundColor,
          color: AppColors.primary,
        ),
      ),
    ),
  );
}

class InvestorChoiceChips<T> extends StatelessWidget {
  const InvestorChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool compact;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final option in options)
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: Semantics(
              selected: selected == option.$1,
              button: true,
              child: TextButton(
                onPressed: () => onSelected(option.$1),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 23.w,
                    vertical: (compact ? 3 : 9).w,
                  ),
                  decoration: BoxDecoration(
                    color: selected == option.$1
                        ? AppColors.primary
                        : AppColors.border,
                    border: Border.all(
                      color: selected == option.$1
                          ? AppColors.primary
                          : AppColors.borderStrong,
                    ),
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                  child: Text(
                    option.$2,
                    style: AppTextStyles.text(
                      14,
                      weight: compact ? FontWeight.w500 : FontWeight.w400,
                      height: compact ? 26 / 14 : 1.2,
                      letterSpacing: compact ? -.28 : 0,
                      color: selected == option.$1
                          ? AppColors.white
                          : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class InvestorDetailRow extends StatelessWidget {
  const InvestorDetailRow(
    this.label,
    this.value, {
    super.key,
    this.valueColor,
    this.strong = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 10.w),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.text(14, color: AppColors.muted),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.text(
              14,
              weight: strong ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppColors.text,
            ),
          ),
        ),
      ],
    ),
  );
}

class InvestorMenuRow extends StatelessWidget {
  const InvestorMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.iconColor = AppColors.mint,
    this.titleSize = 14,
    this.subtitleSize = 12,
    this.subtitleColor = AppColors.muted,
    this.subtitleWeight = FontWeight.w400,
    this.badge,
    this.padding,
    this.radius = 14,
    this.subtitleGap = 5,
    this.iconGap = 14,
  });
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color iconColor;
  final double titleSize;
  final double subtitleSize;
  final Color subtitleColor;
  final FontWeight subtitleWeight;
  final Widget? badge;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double subtitleGap;
  final double iconGap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(radius.r),
      onTap: onTap,
      child: InvestorSurface(
        padding: padding,
        radius: radius,
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: AppIcon(icon, size: 24)),
            ),
            SizedBox(width: iconGap.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 4.w,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.text(
                          titleSize,
                          weight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      ?badge,
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: subtitleGap.w),
                    Text(
                      subtitle,
                      style: AppTextStyles.text(
                        subtitleSize,
                        weight: subtitleWeight,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            trailing ?? const AppIcon(AppAssets.investorNext),
          ],
        ),
      ),
    ),
  );
}

class InvestorBalanceHeader extends StatelessWidget {
  const InvestorBalanceHeader({
    super.key,
    required this.title,
    required this.amount,
    required this.visible,
    required this.onToggle,
    required this.child,
    this.height = 413,
    this.asset = AppAssets.investorHomeMesh,
    this.trailing,
    this.change,
    this.logoTextSize = 27.2793,
    this.logoSymbolSize = 28,
    this.logoRowOffset = 0,
    this.logoSymbolGap,
    this.backgroundFilm,
    this.fractionColor = AppColors.primary,
    this.showTrendIcon = false,
  });
  final String title;
  final MonetaryAmount amount;
  final bool visible;
  final VoidCallback onToggle;
  final Widget child;
  final double height;
  final String asset;
  final Widget? trailing;
  final String? change;
  final double logoTextSize;
  final double logoSymbolSize;
  final double logoRowOffset;
  final double? logoSymbolGap;
  final Color? backgroundFilm;
  final Color fractionColor;
  final bool showTrendIcon;
  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final amountString = Money.amount(amount);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: RepaintBoundary(
        child: Container(
          constraints: BoxConstraints(minHeight: (height - 56).w + safeTop),
          decoration: BoxDecoration(
            color: AppColors.investorDarkSurface,
            image: DecorationImage(
              image: AssetImage(asset),
              fit: BoxFit.fill,
              colorFilter: backgroundFilm == null
                  ? null
                  : ColorFilter.mode(backgroundFilm!, BlendMode.srcOver),
            ),
          ),
          padding: EdgeInsets.fromLTRB(14.w, safeTop + 8.w, 14.w, 46.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: Offset(0, logoRowOffset.w),
                child: SizedBox(
                  height: 44.w,
                  child: Row(
                    children: [
                      BrandLogo(
                        light: true,
                        textSize: logoTextSize,
                        symbolSize: logoSymbolSize,
                        symbolGap: logoSymbolGap,
                      ),
                      const Spacer(),
                      ?trailing,
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40.w),
              Row(
                children: [
                  Text(
                    title,
                    style: AppTextStyles.text(
                      14,
                      color: AppColors.white,
                      height: 1.4,
                      letterSpacing: -.56,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  SizedBox(
                    height: 20.w,
                    width: 32.w,
                    child: OverflowBox(
                      minWidth: 44,
                      minHeight: 44,
                      maxWidth: 44,
                      maxHeight: 44,
                      child: InvestorIconButton(
                        asset: AppAssets.investorBalanceEye,
                        label: visible ? 'Hide balance' : 'Show balance',
                        onPressed: onToggle,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.w),
              // Mask accessible values as well as paint; child text must not
              // expose a hidden balance through a second semantics node.
              Semantics(
                label: title,
                value: visible ? amountString : 'Hidden',
                child: ExcludeSemantics(
                  child: _BalanceAmount(
                    amount: amountString,
                    visible: visible,
                    fractionColor: fractionColor,
                  ),
                ),
              ),
              if (change != null) ...[
                SizedBox(height: 4.w),
                Row(
                  children: [
                    if (showTrendIcon) ...[
                      const AppIcon(AppAssets.investorTrending, size: 16),
                      SizedBox(width: 4.w),
                    ],
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final style = AppTextStyles.text(
                            14,
                            weight: FontWeight.w600,
                            color: AppColors.investorBalanceGrowth,
                            height: 1.4,
                            letterSpacing: -.56,
                          );
                          var height = 0.0;
                          for (final text in [
                            change!,
                            'Projected returns hidden',
                          ]) {
                            final painter = TextPainter(
                              text: TextSpan(text: text, style: style),
                              textDirection: Directionality.of(context),
                              textScaler: MediaQuery.textScalerOf(context),
                            )..layout(maxWidth: constraints.maxWidth);
                            if (painter.height > height) {
                              height = painter.height;
                            }
                            painter.dispose();
                          }
                          return SizedBox(
                            height: height,
                            child: Text(
                              visible ? change! : 'Projected returns hidden',
                              style: style,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: change == null ? 26.w : 27.4.w),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceAmount extends StatelessWidget {
  const _BalanceAmount({
    required this.amount,
    required this.visible,
    required this.fractionColor,
  });
  final String amount;
  final bool visible;
  final Color fractionColor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = AppTextStyles.text(
        40,
        weight: FontWeight.w600,
        color: AppColors.white,
        letterSpacing: -1.6,
      );
      final strut = StrutStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 40.sp,
        height: 1.2,
        forceStrutHeight: true,
      );
      TextSpan span(String text) {
        final parts = text.split('.');
        return TextSpan(
          style: style,
          children: [
            TextSpan(text: parts.first),
            if (parts.length == 2)
              TextSpan(
                text: '.${parts[1]}',
                style: style.copyWith(color: fractionColor),
              ),
          ],
        );
      }

      Size measure(String text) {
        final painter = TextPainter(
          text: span(text),
          strutStyle: strut,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final size = painter.size;
        painter.dispose();
        return size;
      }

      final fullSize = measure(amount);
      final groups = fullSize.width <= constraints.maxWidth
          ? [amount]
          : RegExp(
              r'[^,]+,?',
            ).allMatches(amount).map((m) => m.group(0)!).toList();
      var lines = 1;
      var lineWidth = 0.0;
      for (final group in groups) {
        final width = measure(group).width;
        if (lineWidth > 0 && lineWidth + width > constraints.maxWidth) {
          lines++;
          lineWidth = 0;
        }
        lineWidth += width;
      }
      // Reserve the visible geometry without mounting private text behind a mask.
      return SizedBox(
        height: fullSize.height * lines,
        child: visible
            ? Wrap(
                children: [
                  for (final group in groups)
                    Text.rich(span(group), strutStyle: strut, softWrap: false),
                ],
              )
            : Text(
                '****',
                style: style.copyWith(letterSpacing: 1),
                strutStyle: strut,
              ),
      );
    },
  );
}

class InvestorProjectCard extends StatelessWidget {
  const InvestorProjectCard({
    super.key,
    required this.project,
    required this.onOpen,
    this.featured = false,
    this.favourite = false,
    this.onFavourite,
  });
  final InvestorProject project;
  final VoidCallback onOpen;
  final bool featured;
  final bool favourite;
  final VoidCallback? onFavourite;
  @override
  Widget build(BuildContext context) {
    final category =
        '${project.category.name[0].toUpperCase()}${project.category.name.substring(1)}';
    return Material(
      color: featured ? AppColors.investorCard : AppColors.white,
      borderRadius: BorderRadius.circular((featured ? 16 : 20).r),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular((featured ? 16 : 20).r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular((featured ? 16 : 20).r),
            border: featured ? null : Border.all(color: AppColors.border),
          ),
          padding: featured
              ? EdgeInsets.fromLTRB(11.w, 11.w, 20.w, 16.w)
              : EdgeInsets.fromLTRB(3.w, 3.w, 3.w, 11.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  children: [
                    InvestorPropertyImage(
                      project.imageAsset,
                      height: (featured ? 163 : 149).w,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                    Positioned(
                      left: 8.w,
                      top: (featured ? 12 : 10.38867).w,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: switch (project.category) {
                            ProjectCategory.residential =>
                              AppColors.investorResidential,
                            ProjectCategory.hospitality =>
                              AppColors.investorHospitality,
                            ProjectCategory.commercial =>
                              AppColors.investorCommercial,
                            ProjectCategory.industrial ||
                            ProjectCategory.retail => AppColors.muted,
                          },
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: (featured ? 11 : 14.02985).w,
                            vertical: (featured ? 7 : 5.61194).w,
                          ),
                          child: Text(
                            project.fullyFunded ? 'Fully funded' : category,
                            style: AppTextStyles.text(
                              featured ? 14 : 14.02985,
                              weight: FontWeight.w600,
                              height: featured ? 1.2 : 16 / 14.02985,
                              color: featured
                                  ? AppColors.investorCategoryText
                                  : switch (project.category) {
                                      ProjectCategory.hospitality =>
                                        AppColors.investorHospitalityText,
                                      ProjectCategory.commercial =>
                                        AppColors.investorCommercialText,
                                      _ => AppColors.investorCategoryText,
                                    },
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (onFavourite != null)
                      Positioned(
                        right: 6.w,
                        top: 2.w,
                        child: InvestorFavouriteButton(
                          label: favourite
                              ? 'Remove ${project.name} from favourites'
                              : 'Save ${project.name}',
                          onPressed: onFavourite!,
                          selected: favourite,
                          diameter: 32,
                          iconSize: 18,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: featured
                    ? EdgeInsets.zero
                    : EdgeInsets.only(left: 7.w, right: 8.w),
                child: Column(
                  children: [
                    SizedBox(height: 12.w),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: AppTextStyles.text(
                              featured ? 17.0687 : 16,
                              weight: featured
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: featured
                                  ? AppColors.text
                                  : AppColors.investorProjectTitle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: featured ? 0 : 5.w),
                          child: Text(
                            'Target',
                            style: AppTextStyles.text(
                              featured ? 17.0687 : 14.85714,
                              weight: featured
                                  ? FontWeight.w400
                                  : FontWeight.w500,
                              color: featured
                                  ? AppColors.muted
                                  : AppColors.description,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: (featured ? 7 : 3).w),
                    Row(
                      children: [
                        AppIcon(
                          featured
                              ? AppAssets.investorLocation
                              : AppAssets.investorCatalogLocation,
                          size: 16,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            featured
                                ? '${project.city}  • ${project.area}'
                                : '${project.city}, ${project.country}',
                            style: AppTextStyles.text(
                              14,
                              weight: featured
                                  ? FontWeight.w400
                                  : FontWeight.w500,
                              color: featured
                                  ? AppColors.iconMuted
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Padding(
                          padding: EdgeInsets.only(right: featured ? 0 : 5.w),
                          child: Text(
                            featured
                                ? Money.compact(project.target)
                                : Money.amount(project.target, decimals: false),
                            style: AppTextStyles.text(
                              featured ? 17.0687 : 14,
                              weight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: (featured ? 13 : 11).w),
                    InvestorProgress(
                      project.fundedBasisPoints,
                      backgroundColor: featured
                          ? AppColors.borderStrong
                          : AppColors.border,
                    ),
                    SizedBox(height: 11.w),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: featured ? 0 : 3.w,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${project.fundedBasisPoints ~/ 100}% ${featured ? 'funded' : 'Funded'}',
                              style: AppTextStyles.text(
                                featured ? 14 : 12.235294,
                                weight: featured
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: featured
                                    ? AppColors.text
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      'ROI ${(project.annualReturnBasisPoints / 100).toStringAsFixed(1)}%',
                                  style: AppTextStyles.text(
                                    14,
                                    weight: featured
                                        ? FontWeight.w400
                                        : FontWeight.w500,
                                    color: featured
                                        ? AppColors.primary
                                        : AppColors.description,
                                  ),
                                ),
                                TextSpan(
                                  text: '  •  ',
                                  style: AppTextStyles.text(
                                    featured ? 14 : 9,
                                    weight: featured
                                        ? FontWeight.w400
                                        : FontWeight.w700,
                                    color: featured
                                        ? AppColors.primary
                                        : AppColors.placeholder,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${project.durationMonths} ${featured ? 'months' : 'Months'}',
                                  style: AppTextStyles.text(
                                    featured ? 14 : 12,
                                    weight: featured
                                        ? FontWeight.w400
                                        : FontWeight.w700,
                                    color: AppColors.primary,
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
          ),
        ),
      ),
    );
  }
}

class InvestorProjectRow extends StatelessWidget {
  const InvestorProjectRow({
    super.key,
    required this.project,
    required this.onTap,
    this.subtitle,
    this.value,
    this.valueLabel = 'ROI',
  });
  final InvestorProject project;
  final VoidCallback onTap;
  final String? subtitle;
  final String? value;
  final String valueLabel;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.investorCard,
    borderRadius: BorderRadius.circular(14.r),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: InvestorSurface(
        radius: 14,
        border: AppColors.border,
        padding: EdgeInsets.all(7.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                switch (project.thumbnailAsset) {
                  AppAssets.projectSaffronResidenceThumbnail =>
                    8.387096405029297.r,
                  AppAssets.projectSaffronResortThumbnail => 12.r,
                  _ => 10.r,
                },
              ),
              child: InvestorPropertyImage(
                project.thumbnailAsset ?? project.imageAsset,
                width: 78.w,
                height: 76.w,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            SizedBox(width: 13.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 10.5.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 9.w),
                    Text(
                      subtitle ?? '${project.city} • ${project.area}',
                      style: AppTextStyles.text(12, color: AppColors.iconMuted),
                    ),
                    SizedBox(height: 10.w),
                    InvestorProgress(project.fundedBasisPoints),
                  ],
                ),
              ),
            ),
            SizedBox(width: 18.w),
            Padding(
              padding: EdgeInsets.only(top: 10.w),
              child: SizedBox(
                width: 50.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      valueLabel,
                      style: AppTextStyles.text(
                        14.857142,
                        weight: FontWeight.w500,
                        height: 18 / 14.857142,
                        color: AppColors.body,
                      ),
                    ),
                    SizedBox(height: 4.6426.w),
                    Text(
                      value ??
                          '${(project.annualReturnBasisPoints / 100).toStringAsFixed(1)}%',
                      style: AppTextStyles.text(
                        14.857142,
                        weight: FontWeight.w700,
                        height: 18 / 14.857142,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 4.w),
          ],
        ),
      ),
    ),
  );
}

class InvestorEmptyState extends StatelessWidget {
  const InvestorEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
    this.asset,
  });
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  final String? asset;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 44.w),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (asset != null) AppIcon(asset!, size: 120),
        SizedBox(height: 20.w),
        Text(title, textAlign: TextAlign.center, style: AppTextStyles.title),
        SizedBox(height: 12.w),
        Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
        if (action != null) ...[
          SizedBox(height: 24.w),
          AppButton(label: action!, onPressed: onAction),
        ],
      ],
    ),
  );
}

class InvestorPage extends StatelessWidget {
  const InvestorPage({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
    this.trailing,
    this.onBack,
    this.showBack = true,
    this.headerLeadingInset,
    this.headerTopInset,
    this.footerBottomInset = 0,
    this.bodyPadding,
    this.titleCenterOffset = 0,
    this.titleTopOffset = 0,
    this.titleOverflow = TextOverflow.visible,
  });
  final String title;
  final Widget child;
  final Widget? bottom;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;
  final double? headerLeadingInset;
  final double? headerTopInset;
  final double footerBottomInset;
  final EdgeInsetsGeometry? bodyPadding;
  final double titleCenterOffset;
  final double titleTopOffset;
  final TextOverflow titleOverflow;
  @override
  Widget build(BuildContext context) => AppPage(
    title: title,
    trailing: trailing,
    bottom: bottom == null || footerBottomInset == 0
        ? bottom
        : Padding(
            padding: EdgeInsets.only(bottom: footerBottomInset.w),
            child: bottom,
          ),
    showBack: showBack,
    headerLeadingInset: headerLeadingInset,
    headerTopInset: headerTopInset,
    titleCenterOffset: titleCenterOffset,
    titleTopOffset: titleTopOffset,
    titleOverflow: titleOverflow,
    onBack:
        onBack ??
        () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/investor/home');
          }
        },
    padding: bodyPadding == null,
    child: bodyPadding == null
        ? child
        : Padding(padding: bodyPadding!, child: child),
  );
}

class FeatureScope<T> extends StatefulWidget {
  const FeatureScope({
    super.key,
    required this.create,
    required this.dispose,
    required this.builder,
    this.initialize,
  });
  final T Function() create;
  final void Function(T) dispose;
  final void Function(T)? initialize;
  final Widget Function(BuildContext, T) builder;
  @override
  State<FeatureScope<T>> createState() => _FeatureScopeState<T>();
}

class _FeatureScopeState<T> extends State<FeatureScope<T>> {
  late final T value;
  @override
  void initState() {
    super.initState();
    value = widget.create();
    widget.initialize?.call(value);
  }

  @override
  void dispose() {
    widget.dispose(value);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, value);
}
