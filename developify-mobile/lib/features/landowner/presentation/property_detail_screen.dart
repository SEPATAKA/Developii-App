import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/menu_row.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/property_detail_store.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/property_card.dart';
import 'package:developify_mobile/features/notifications/presentation/notifications_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({
    super.key,
    required this.store,
    required this.id,
  });
  final PropertyDetailStore store;
  final String id;
  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.store.load(widget.id));
  }

  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Property',
    child: Observer(
      builder: (_) {
        final store = widget.store;
        if (store.status == LoadStatus.loading ||
            store.status == LoadStatus.initial) {
          return const LoadingView();
        }
        if (store.status == LoadStatus.error) {
          return ErrorView(
            message: store.error!,
            onRetry: () => store.load(widget.id),
          );
        }
        final property = store.property!;
        return ListView(
          padding: EdgeInsets.only(top: 24.h, bottom: 24.h),
          children: [
            Text(property.name, style: AppTextStyles.title),
            SizedBox(height: 16.h),
            PropertyCard(property: property, onTap: () {}),
            SizedBox(height: 24.h),
            Text(property.address, style: AppTextStyles.body),
            SizedBox(height: 24.h),
            if (property.status == PropertyStatus.live)
              const FundingPanel()
            else
              InfoPanel(
                child: Text(
                  property.status == PropertyStatus.underReview
                      ? 'Our team reviews submissions within 5–10 business days. We’ll message you here with questions or a decision.'
                      : 'Your property is ${property.status.label.toLowerCase()}. The property team can help with the next step.',
                  style: AppTextStyles.body,
                ),
              ),
            SizedBox(height: 30.h),
            Text('Next Step', style: AppTextStyles.section),
            SizedBox(height: 14.h),
            MenuRow(
              title: 'Message the property team',
              subtitle: 'Avg reply 12min',
              icon: AppAssets.headerNotification,
              onTap: () => context.pushNamed(Routes.chat),
            ),
          ],
        );
      },
    ),
  );
}
