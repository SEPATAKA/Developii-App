import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/investor_project_content.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class ProjectDocuments extends StatelessWidget {
  const ProjectDocuments({super.key, required this.documents});
  final List<InvestorProjectDocument> documents;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (documents.isEmpty)
        const InvestorEmptyState(
          title: 'No documents yet',
          message: 'Project documents will appear here when available.',
        ),
      for (final document in documents)
        Padding(
          padding: EdgeInsets.only(bottom: 14.w),
          child: Semantics(
            button: true,
            child: Material(
              color: AppColors.investorCard,
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Document preview',
                      style: AppTextStyles.section,
                    ),
                    scrollable: true,
                    content: Text(
                      '${document.name}\n\nThis is a simulated preview. The original document has not been supplied and no file is downloaded.',
                      style: AppTextStyles.body,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                child: InvestorSurface(
                  radius: 12,
                  border: AppColors.neutralSeparator,
                  padding: EdgeInsets.fromLTRB(14.w, 16.w, 16.w, 16.w),
                  child: Row(
                    children: [
                      const AppIcon(AppAssets.investorDocumentPdf, size: 40),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          document.name,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w600,
                            height: 20 / 14,
                            letterSpacing: -.084,
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
