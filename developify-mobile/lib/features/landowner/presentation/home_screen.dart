import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/home_store.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/property_card.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/home_submit_property_card.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/home_header.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/home_empty_properties.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/market_insight_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store, required this.displayName});
  final HomeStore store;
  final String displayName;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      body: RefreshIndicator(
        onRefresh: widget.store.load,
        child: SingleChildScrollView(
          key: const PageStorageKey('home-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(
                store: widget.store,
                displayName: widget.displayName,
                onProfile: () => context.goNamed(Routes.profile),
                onMessages: () => context.pushNamed(Routes.chat),
                onNotifications: () => context.pushNamed(Routes.notifications),
                onExperience: () => context.pushNamed(Routes.experience),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 15.w, 12.w, 3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeSubmitPropertyCard(
                      onTap: () => context.pushNamed(
                        Routes.submit,
                        pathParameters: {'step': '1'},
                      ),
                    ),
                    SizedBox(height: 29.w),
                    SectionHeading(
                      'Your properties',
                      action: 'See All',
                      onAction: () => context.goNamed(Routes.properties),
                    ),
                    SizedBox(height: 13.w),
                    Observer(
                      builder: (_) {
                        if (widget.store.status == LoadStatus.loading ||
                            widget.store.status == LoadStatus.initial) {
                          return SizedBox(
                            height: 103.h,
                            child: const LoadingView(),
                          );
                        }
                        if (widget.store.status == LoadStatus.error) {
                          return ErrorView(
                            message: widget.store.error!,
                            onRetry: widget.store.load,
                          );
                        }
                        final properties = widget.store.data?.properties ?? [];
                        if (properties.isEmpty) {
                          return const HomeEmptyProperties();
                        }
                        return Column(
                          children: properties.indexed
                              .map(
                                (entry) => Padding(
                                  padding: EdgeInsets.only(
                                    top: entry.$1 == 0 ? 0 : 15.w,
                                  ),
                                  child: PropertyCard(
                                    property: entry.$2,
                                    dashboard:
                                        properties.length == 1 || entry.$1 > 0,
                                    onTap: () => context.pushNamed(
                                      Routes.property,
                                      pathParameters: {'id': entry.$2.id},
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    Observer(
                      builder: (_) => Padding(
                        padding: EdgeInsets.only(
                          top: widget.store.status == LoadStatus.empty
                              ? 29.w
                              : 24.w,
                          left: widget.store.status == LoadStatus.empty
                              ? 1.w
                              : 0,
                          bottom: widget.store.status == LoadStatus.empty
                              ? 31.w
                              : 0,
                        ),
                        child: const MarketInsightCard(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
