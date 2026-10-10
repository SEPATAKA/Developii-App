
import 'package:flutter/material.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class AdaptiveNavigationRow extends StatelessWidget {
  const AdaptiveNavigationRow({
    super.key,
    required this.labels,
    required this.children,
  }) : assert(labels.length == children.length);

  final List<String> labels;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Avoid layout errors during route transitions when the
        // parent temporarily has almost no available width.
        if (children.isEmpty ||
            !constraints.hasBoundedWidth ||
            constraints.maxWidth < 1) {
          return const SizedBox.shrink();
        }

        var requiredWidth = 48.0;

        for (final label in labels) {
          final painter = TextPainter(
            text: TextSpan(
              text: label,
              style: AppTextStyles.text(
                12,
                weight: FontWeight.w500,
              ),
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();

          requiredWidth = requiredWidth > painter.width + 16
              ? requiredWidth
              : painter.width + 16;

          painter.dispose();
        }

        final availableWidth = constraints.maxWidth;

        // Never force navigation children into near-zero widths.
        if (availableWidth < requiredWidth) {
          return const SizedBox.shrink();
        }

        if (requiredWidth * children.length <= availableWidth) {
          return Row(
            children: [
              for (final child in children)
                Expanded(child: child),
            ],
          );
        }

        final columns = (availableWidth / requiredWidth)
            .floor()
            .clamp(1, 3);

        final itemWidth = availableWidth / columns;

        return Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}
