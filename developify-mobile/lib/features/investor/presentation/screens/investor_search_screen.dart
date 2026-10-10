import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/explore_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class InvestorSearchScreen extends StatefulWidget {
  const InvestorSearchScreen({
    super.key,
    required this.store,
    this.wishlist = false,
  });
  final ExploreStore store;
  final bool wishlist;

  @override
  State<InvestorSearchScreen> createState() => _InvestorSearchScreenState();
}

class _InvestorSearchScreenState extends State<InvestorSearchScreen> {
  late final _query = TextEditingController(text: widget.store.query);
  final _focus = FocusNode();

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    widget.store.submitSearch();
    _focus.unfocus();
  }

  void _search(String value) {
    _query.text = value;
    widget.store.search(value);
    _submit();
  }

  void _back() {
    if (context.canPop()) {
      context.pop(widget.wishlist ? null : widget.store.query);
    } else {
      context.goNamed(InvestorRoutes.explore);
    }
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) => InvestorPage(
      title: widget.wishlist
          ? 'Wishlist'
          : widget.store.query.trim().isEmpty || widget.store.results.isEmpty
          ? 'Search'
          : 'Results for “${widget.store.query.trim()}”',
      headerLeadingInset: widget.wishlist ? 17.5 : 14,
      headerTopInset: widget.wishlist ? 17 : 18,
      titleCenterOffset: widget.wishlist ? 7 : 0,
      titleTopOffset: widget.wishlist ? 0 : -4,
      titleOverflow: TextOverflow.ellipsis,
      onBack: _back,
      child: ListView(
        key: PageStorageKey(
          widget.wishlist
              ? 'investor-wishlist-scroll'
              : 'investor-search-scroll',
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          top: (widget.wishlist ? 19 : 14).w,
          bottom: 24.w,
        ),
        children: [
          Padding(
            padding: EdgeInsets.only(right: widget.wishlist ? 11.w : 0),
            child: AppField(
              key: const ValueKey('investor-project-search'),
              label: '',
              hint: 'Search',
              hintColor: AppColors.muted,
              controller: _query,
              focusNode: _focus,
              onChanged: widget.store.search,
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              textSize: 16,
              textHeight: 26 / 16,
              borderRadius: 16,
              fillColor: AppColors.investorCard,
              contentPadding: EdgeInsets.symmetric(
                vertical: 13.w,
                horizontal: 12.w,
              ),
              prefixWidth: 50,
              prefix: Padding(
                padding: EdgeInsets.only(left: 20.w, right: 10.w),
                child: const AppIcon(AppAssets.investorSearchInput, size: 20),
              ),
              suffix: widget.store.query.isEmpty
                  ? null
                  : InvestorIconButton(
                      asset: AppAssets.investorModalClose,
                      size: 22,
                      label: 'Clear search',
                      onPressed: () => _search(''),
                    ),
            ),
          ),
          SizedBox(height: (widget.wishlist ? 35 : 22).w),
          ..._results(),
        ],
      ),
    ),
  );

  Widget _recentSearchChip(String query) => Semantics(
    button: true,
    label: 'Search $query',
    excludeSemantics: true,
    onTap: () => _search(query),
    child: InkWell(
      onTap: () => _search(query),
      borderRadius: BorderRadius.circular(32.r),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 44,
          minWidth: (switch (query) {
            'Cape Town' => 96.0,
            'Durban' => 77.0,
            'Hospitality' => 98.0,
            r'UnderR1k' => 97.0,
            'Residential' => 107.0,
            _ => 44.0,
          }).w,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 5.w),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(32.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.w),
              child: Text(
                query,
                textAlign: TextAlign.center,
                style: AppTextStyles.text(
                  14,
                  weight: FontWeight.w500,
                  color: AppColors.muted,
                  height: 26 / 14,
                  letterSpacing: -.28,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _results() {
    final store = widget.store;
    if (store.status == LoadStatus.initial ||
        store.status == LoadStatus.loading) {
      return const [LoadingView()];
    }
    if (store.status == LoadStatus.error) {
      return [
        ErrorView(
          message: store.error ?? 'Unable to load projects.',
          onRetry: store.load,
        ),
      ];
    }
    final results = !widget.wishlist && store.query.trim().isEmpty
        ? store.suggestedResults
        : store.results;
    return [
      if (store.error != null) InlineError(store.error),
      if (!widget.wishlist &&
          store.query.trim().isEmpty &&
          store.recentSearches.isNotEmpty) ...[
        Text('Recent Searches', style: AppTextStyles.section),
        SizedBox(height: 8.w),
        for (final (row, queries) in [
          store.recentSearches.take(3),
          store.recentSearches.skip(3),
        ].where((queries) => queries.isNotEmpty).indexed) ...[
          if (row > 0) SizedBox(height: 4.w),
          Wrap(
            spacing: (row == 0 ? 12 : 17).w,
            runSpacing: 4.w,
            children: [for (final query in queries) _recentSearchChip(query)],
          ),
        ],
        SizedBox(height: 28.w),
      ],
      if (results.isEmpty) ...[
        Text(
          widget.wishlist ? 'Wishlist (0)' : 'Result (0)',
          style: AppTextStyles.text(
            20,
            weight: FontWeight.w600,
            color: AppColors.investorSearchEmptyText,
          ),
        ),
        SizedBox(height: 69.w),
        const Center(child: AppIcon(AppAssets.investorSearchEmpty, size: 62)),
        SizedBox(height: 20.w),
        Text(
          widget.wishlist
              ? 'No favourite projects yet'
              : 'The place doesn’t exist',
          textAlign: TextAlign.center,
          style: AppTextStyles.text(
            16,
            weight: FontWeight.w600,
            color: AppColors.investorSearchEmptyText,
            height: 20 / 16,
          ),
        ),
        SizedBox(height: 12.w),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            widget.wishlist
                ? 'Save projects while you explore to find them here.'
                : 'Try another name, location or category to find a project.',
            textAlign: TextAlign.center,
            style: AppTextStyles.text(
              14,
              color: AppColors.investorSearchHint,
              height: 24 / 14,
            ),
          ),
        ),
      ] else ...[
        if (!widget.wishlist) ...[
          Text('Top Results', style: AppTextStyles.section),
          SizedBox(height: 13.w),
        ],
        for (final project in results) ...[
          if (widget.wishlist)
            InvestorProjectCard(
              project: project,
              favourite: store.favourites.contains(project.id),
              onFavourite: () => store.toggleFavourite(project.id),
              onOpen: () => _open(project.id),
            )
          else
            InvestorProjectRow(
              project: project,
              onTap: () => _open(project.id),
            ),
          SizedBox(height: (widget.wishlist ? 24 : 13).w),
        ],
      ],
    ];
  }

  void _open(String id) {
    _submit();
    context.pushNamed(InvestorRoutes.project, pathParameters: {'id': id});
  }
}
