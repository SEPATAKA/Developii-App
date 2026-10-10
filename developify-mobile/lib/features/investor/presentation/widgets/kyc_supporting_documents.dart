import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_document_actions.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_fields.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class KycSupportingDocuments extends StatelessWidget {
  const KycSupportingDocuments({
    super.key,
    required this.store,
    required this.definition,
  });
  final KycStore store;
  final KycDocumentDefinition definition;

  @override
  Widget build(BuildContext context) {
    final files = store.draft!.documentsFor(definition.key);
    final pickerFirst = store.entity == EntityType.company;
    final attempt = store.documentUploads[definition.key];
    final adding = attempt?.documentId == null;
    final picker = InvestorDocumentTile(
      title: files.isEmpty
          ? definition.title
          : 'Upload more supporting documents',
      document: null,
      centered: true,
      chooseLabel: 'Upload supporting documents',
      helperText: 'Statements, sale agreements, donations deed, etc',
      uploadAttempt: adding ? attempt : null,
      enabled: !store.busy && attempt == null,
      error: store.errors[definition.key],
      onRetry: () => store.retryUpload(definition.key),
      onCancel: () => store.cancelUpload(definition.key),
      onChoose: () =>
          KycDocumentActions(store, append: true).choose(context, definition),
      onDelete: () {},
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pickerFirst) ...[
          picker,
          if (files.isNotEmpty) SizedBox(height: 20.w),
        ],
        for (final (index, file) in files.indexed) ...[
          if (index > 0) SizedBox(height: 12.w),
          InvestorDocumentTile(
            key: ValueKey(file.id),
            title: definition.title,
            showTitle: index == 0,
            document: file,
            centered: true,
            uploadAttempt: attempt?.documentId == file.id ? attempt : null,
            enabled: !store.busy && attempt == null,
            onRetry: () => store.retryUpload(definition.key),
            onCancel: () => store.cancelUpload(definition.key),
            onChoose: () => KycDocumentActions(
              store,
              documentId: file.id,
            ).choose(context, definition),
            onDelete: () => KycDocumentActions(
              store,
              documentId: file.id,
            ).remove(context, definition),
          ),
        ],
        if (!pickerFirst) ...[
          if (files.isNotEmpty) SizedBox(height: 20.w),
          picker,
        ],
      ],
    );
  }
}
