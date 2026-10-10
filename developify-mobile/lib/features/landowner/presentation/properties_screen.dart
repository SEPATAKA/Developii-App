import 'dart:async';

import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/properties_store.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/properties_submit_another_property_card.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/property_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobx/mobx.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key, required this.store});
  final PropertiesStore store;
  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.store.load());
  }

  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  Future<void> _open(Property property) async {
    if (property.status == PropertyStatus.draft) {
      await context.pushNamed(
        Routes.submit,
        pathParameters: {'step': '${property.draftStep}'},
        queryParameters: {'draft': property.id},
      );
      if (mounted) await widget.store.load();
    } else {
      await context.pushNamed(
        Routes.property,
        pathParameters: {'id': property.id},
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageAppBar(
      title: 'My Properties',
      titleCenterOffset: -1.5,
      onBack: () => context.goNamed(Routes.home),
      //trailing: AppBackButton(onPressed: () => context.goNamed(Routes.home)),
    ),
    body: Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        children: [
          Observer(
            builder: (_) {
              final laterFilter =
                  widget.store.filter == PropertyStatus.offerReady ||
                  widget.store.filter == PropertyStatus.live ||
                  widget.store.filter == PropertyStatus.paused;
              return Padding(
                padding: EdgeInsets.only(
                  top: (laterFilter ? 18 : 14).w,
                  bottom: (laterFilter ? 18 : 22).w,
                ),
                child: PropertyFilters(store: widget.store),
              );
            },
          ),
          PropertySearchField(onChanged: widget.store.search),
          SizedBox(height: 19.w),
          Expanded(
            child: Observer(
              builder: (_) {
                if (widget.store.status == LoadStatus.loading ||
                    widget.store.status == LoadStatus.initial) {
                  return const LoadingView();
                }
                if (widget.store.status == LoadStatus.error) {
                  return ErrorView(
                    message: widget.store.error!,
                    onRetry: widget.store.load,
                  );
                }
                final items = widget.store.visibleItems;
                return RefreshIndicator(
                  onRefresh: widget.store.load,
                  child: ListView(
                    key: const PageStorageKey('properties-scroll'),
                    padding: EdgeInsets.zero,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Text(
                        items.length == 1
                            ? '1  properties'
                            : '${items.length} properties',
                        style: AppTextStyles.section,
                      ),
                      SizedBox(height: 13.w),
                      if (items.isEmpty)
                        const EmptyView(
                          title: 'No Properties Yet',
                          message:
                              'No properties match this view. Try another filter or submit a new property.',
                        ),
                      for (final (index, property) in items.indexed) ...[
                        if (index > 0)
                          SizedBox(
                            height: (widget.store.filter == null ? 15 : 13).w,
                          ),
                        PropertyCard(
                          property: property,
                          onTap: () => _open(property),
                        ),
                      ],
                      SizedBox(
                        height:
                            (widget.store.filter == PropertyStatus.draft
                                    ? 19
                                    : 13)
                                .w,
                      ),
                      PropertiesSubmitAnotherPropertyCard(
                        onTap: () => context.pushNamed(
                          Routes.submit,
                          pathParameters: {'step': '1'},
                        ),
                      ),
                      SizedBox(height: 24.w),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class PropertyFilters extends StatefulWidget {
  const PropertyFilters({super.key, required this.store});
  final PropertiesStore store;

  @override
  State<PropertyFilters> createState() => _PropertyFiltersState();
}

class _PropertyFiltersState extends State<PropertyFilters> {
  final _keys = {
    for (final filter in [null, ...PropertyStatus.values]) filter: GlobalKey(),
  };
  late final ReactionDisposer _selectionChanged;
  PropertiesStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _selectionChanged = reaction<PropertyStatus?>(
      (_) => store.filter,
      (_) => _revealSelection(),
    );
  }

  void _revealSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _keys[store.filter]?.currentContext;
      if (context != null) {
        unawaited(
          Scrollable.ensureVisible(
            context,
            alignment: 1,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _selectionChanged();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44.w,
    child: Observer(
      builder: (_) {
        final showDraftCount =
            store.filter == null || store.filter == PropertyStatus.draft;
        final drafts = store.items
            .where((item) => item.status == PropertyStatus.draft)
            .length;
        final reviews = store.items
            .where((item) => item.status == PropertyStatus.underReview)
            .length;
        final offers = store.items
            .where((item) => item.status == PropertyStatus.offerReady)
            .length;
        return ListView(
          key: const PageStorageKey('property-filters'),
          scrollDirection: Axis.horizontal,
          children: [
            for (final (filter, label) in [
              (null, 'All'),
              (
                PropertyStatus.draft,
                showDraftCount ? 'Draft $drafts' : 'Draft',
              ),
              (PropertyStatus.underReview, 'Under review $reviews'),
              (PropertyStatus.offerReady, 'Approved $offers'),
              (PropertyStatus.live, 'Live '),
              (PropertyStatus.paused, 'Paused'),
            ])
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Semantics(
                  key: _keys[filter],
                  button: true,
                  selected: store.filter == filter,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => store.setFilter(filter),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 23.w,
                          vertical: 3.w,
                        ),
                        decoration: BoxDecoration(
                          color: store.filter == filter
                              ? AppColors.primary
                              : AppColors.border,
                          border: Border.all(
                            color: store.filter == filter
                                ? AppColors.primary
                                : AppColors.borderStrong,
                          ),
                          borderRadius: BorderRadius.circular(32.w),
                        ),
                        child: Text(
                          label,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w500,
                            height: 26 / 14,
                            color: store.filter == filter
                                ? AppColors.white
                                : AppColors.muted,
                          ).copyWith(letterSpacing: -.28.sp),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class PropertySearchField extends StatelessWidget {
  const PropertySearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      gapPadding: 0,
      borderRadius: BorderRadius.circular(13.w),
      borderSide: const BorderSide(color: AppColors.borderStrong),
    );
    return TextField(
      key: const ValueKey('property-search'),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.text(14, weight: FontWeight.w500, height: 16 / 14),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search by name, erf or town…',
        hintStyle: AppTextStyles.text(
          14,
          weight: FontWeight.w500,
          color: AppColors.iconMuted,
          height: 16 / 14,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(vertical: 14.w),
        prefixIconConstraints: BoxConstraints(minWidth: 60.w, minHeight: 44.w),
        prefixIcon: SizedBox(
          width: 60.w,
          child: Padding(
            padding: EdgeInsets.only(left: 15.w),
            child: const Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              heightFactor: 1,
              child: AppIcon(AppAssets.propertySearch),
            ),
          ),
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
