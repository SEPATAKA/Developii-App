import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/explore_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.store});
  final ExploreStore store;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(23.w, 3.5.w, 13.w, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Explore',
                  style: AppTextStyles.text(
                    24,
                    weight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              InvestorIconButton(
                asset: AppAssets.investorSearch,
                label: 'Search projects',
                onPressed: _search,
              ),
              Observer(
                builder: (_) => InvestorIconButton(
                  asset: AppAssets.investorFavourites,
                  label: 'Favourite projects',
                  selected: widget.store.favouritesOnly,
                  onPressed: () => context.pushNamed(InvestorRoutes.wishlist),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32.5.w),
        Padding(
          padding: EdgeInsets.only(left: 23.w),
          child: Observer(
            builder: (_) => InvestorChoiceChips<ProjectCategory?>(
              compact: true,
              options: const [
                (null, 'All'),
                (ProjectCategory.residential, 'Residential'),
                (ProjectCategory.commercial, 'Commercial'),
                (ProjectCategory.hospitality, 'Hospitality'),
              ],
              selected: widget.store.category,
              onSelected: widget.store.selectCategory,
            ),
          ),
        ),
        SizedBox(height: 12.5.w),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Observer(
            builder: (_) => Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.store.results.length} Project',
                    style: AppTextStyles.text(
                      16,
                      weight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _filters,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Sort : ${widget.store.sort.label}',
                    style: AppTextStyles.text(
                      14,
                      weight: FontWeight.w500,
                      color: AppColors.investorLink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Observer(
            builder: (_) {
              final store = widget.store;
              if (store.status == LoadStatus.loading ||
                  store.status == LoadStatus.initial) {
                return const LoadingView();
              }
              if (store.status == LoadStatus.error) {
                return ErrorView(
                  message: store.error ?? 'Unable to load projects.',
                  onRetry: store.load,
                );
              }
              final projects = store.results;
              if (projects.isEmpty) {
                return SingleChildScrollView(
                  child: InvestorEmptyState(
                    title: 'The place doesn’t exist',
                    message: 'No projects match your search.',
                    action: 'Reset filters',
                    onAction: () {
                      store.resetFilters();
                      store.search('');
                    },
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: store.load,
                child: ListView.separated(
                  key: const PageStorageKey('investor-explore-scroll'),
                  padding: EdgeInsets.fromLTRB(12.w, 6.5.w, 12.w, 16.w),
                  itemCount: projects.length,
                  separatorBuilder: (_, _) => SizedBox(height: 24.w),
                  itemBuilder: (_, index) => Observer(
                    builder: (_) => InvestorProjectCard(
                      project: projects[index],
                      favourite: store.favourites.contains(projects[index].id),
                      onFavourite: () =>
                          store.toggleFavourite(projects[index].id),
                      onOpen: () => context.pushNamed(
                        InvestorRoutes.project,
                        pathParameters: {'id': projects[index].id},
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Future<void> _search() async {
    final result = await context.pushNamed<String>(
      InvestorRoutes.search,
      queryParameters: widget.store.query.isEmpty
          ? const {}
          : {'q': widget.store.query},
    );
    if (mounted && result != null) widget.store.search(result);
  }

  Future<void> _filters() async {
    final result = await context.pushNamed<String>(
      InvestorRoutes.filters,
      queryParameters: widget.store.filter.parameters,
    );
    if (!mounted || result == null) return;
    final filter = ProjectFilter.tryParse(Uri.splitQueryString(result));
    if (filter != null) widget.store.applyFilter(filter);
  }
}
