import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_member_store.dart';

final class KycDocumentActions {
  KycDocumentActions(KycStore store, {bool append = false, String? documentId})
    : _upload =
          ((
            String key, {
            required String name,
            required int bytes,
            required String mimeType,
          }) => store.upload(
            key,
            name: name,
            bytes: bytes,
            mimeType: mimeType,
            append: append,
            documentId: documentId,
          )),
      _delete = ((key) => store.deleteDocument(key, documentId: documentId));
  KycDocumentActions.member(KycMemberStore store)
    : _upload = store.upload,
      _delete = store.deleteDocument;
  final Future<bool> Function(
    String key, {
    required String name,
    required int bytes,
    required String mimeType,
  })
  _upload;
  final bool Function(String key) _delete;

  Future<void> choose(
    BuildContext context,
    KycDocumentDefinition document,
  ) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose a file', style: AppTextStyles.title),
              SizedBox(height: 12.w),
              Text(
                'Use a sample document for this simulation. No files are read or uploaded.',
                style: AppTextStyles.body,
              ),
              SizedBox(height: 20.w),
              for (final option in {
                'jpg': 'Take Photo',
                'png': 'Choose from Gallery',
                'pdf': 'Choose Document',
              }.entries)
                TextButton(
                  onPressed: () => Navigator.pop(context, option.key),
                  child: Text(
                    option.value,
                    style: AppTextStyles.text(16, color: AppColors.primary),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || format == null) return;
    await _upload(
      document.key,
      name: '${document.key}.$format',
      bytes: 120 * 1024,
      mimeType: switch (format) {
        'jpg' => 'image/jpeg',
        'png' => 'image/png',
        _ => 'application/pdf',
      },
    );
  }

  Future<void> remove(
    BuildContext context,
    KycDocumentDefinition document,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(
          '${document.title} will be removed from this application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (context.mounted && remove == true) _delete(document.key);
  }
}
