import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/app_switch.dart';
import 'package:developify_mobile/core/widgets/dashed_border.dart';
import 'package:developify_mobile/core/widgets/selection_sheet.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_selection_card.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_document_upload_tile.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_choice_sheet.dart';

class KycField extends StatefulWidget {
  const KycField({
    super.key,
    required this.definition,
    required this.value,
    required this.onChanged,
    this.error,
    this.enabled = true,
    this.grouped = false,
    this.multilineLines = 3,
    this.showChoiceIndicator = true,
    this.multilineHeight,
    this.labelSpacing = 4,
    this.outline = false,
    this.contentPadding,
    this.toggleHeight,
    this.toggleSubtitle,
    this.onLabelTap,
  });
  final KycFieldDefinition definition;
  final String value;
  final ValueChanged<String> onChanged;
  final String? error;
  final bool enabled;
  final bool grouped;
  final int multilineLines;
  final bool showChoiceIndicator;
  final double? multilineHeight;
  final double labelSpacing;
  final bool outline;
  final EdgeInsetsGeometry? contentPadding;
  final double? toggleHeight;
  final String? toggleSubtitle;
  final VoidCallback? onLabelTap;
  @override
  State<KycField> createState() => _KycFieldState();
}

class _KycFieldState extends State<KycField> {
  late final TextEditingController _controller;
  late String _editingValue = widget.value;
  final _focus = FocusNode();
  String get _displayValue {
    if (widget.definition.key == 'founded') {
      final date = DateTime.tryParse(_editingValue);
      if (date != null) return AppDateFormat.monthYear(date);
    }
    if (widget.definition.kind == KycFieldKind.amount && !_focus.hasFocus) {
      final amount = MonetaryAmount.tryParse(_editingValue, Currency.zar);
      if (amount != null) {
        return Money.amount(
          amount,
          decimals: amount.minorUnits % 100 != 0,
          spaceAfterSymbol: true,
        );
      }
    }
    return widget.definition.kind == KycFieldKind.date && widget.grouped
        ? AppDateFormat.slashDate(DateTime.tryParse(_editingValue))
        : KycChoiceSheet.displayLabel(widget.definition, _editingValue);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayValue);
    _focus.addListener(_syncValue);
  }

  @override
  void didUpdateWidget(covariant KycField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _editingValue = widget.value;
    _syncValue();
  }

  void _changeValue(String value) {
    _editingValue = value;
    widget.onChanged(value);
  }

  void _syncValue() {
    if (_controller.text != _displayValue) {
      _controller.value = TextEditingValue(
        text: _displayValue,
        selection: TextSelection.collapsed(offset: _displayValue.length),
      );
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_syncValue);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.definition;
    if (field.kind == KycFieldKind.toggle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            toggled: widget.value == 'true',
            label: field.label,
            child: InkWell(
              onTap: widget.enabled
                  ? () => widget.onChanged(
                      widget.value == 'true' ? 'false' : 'true',
                    )
                  : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      widget.toggleHeight?.w ?? (widget.grouped ? 44 : 48),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: widget.toggleSubtitle != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field.label,
                                  style: AppTextStyles.text(
                                    14,
                                    weight: FontWeight.w500,
                                    height: 17 / 14,
                                  ),
                                ),
                                SizedBox(height: 6.w),
                                Text(
                                  widget.toggleSubtitle!,
                                  style: AppTextStyles.text(
                                    12,
                                    weight: FontWeight.w500,
                                    height: 17 / 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            )
                          : widget.onLabelTap == null
                          ? Text(field.label, style: AppTextStyles.text(14))
                          : InkWell(
                              onTap: widget.enabled ? widget.onLabelTap : null,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    field.label,
                                    style: AppTextStyles.text(14),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    SizedBox(width: 12.w),
                    widget.grouped
                        ? AppSwitch.solid(value: widget.value == 'true')
                        : AppSwitch(value: widget.value == 'true'),
                  ],
                ),
              ),
            ),
          ),
          if (widget.error != null)
            Text(
              widget.error!,
              style: AppTextStyles.text(12, color: AppColors.error),
            ),
        ],
      );
    }
    if (field.kind == KycFieldKind.multipleChoice) {
      final selected = widget.value
          .split('|')
          .where((item) => item.isNotEmpty)
          .toSet();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.label.isNotEmpty) ...[
            Text(field.label, style: AppTextStyles.label),
            SizedBox(height: 14.w),
          ],
          for (final (index, option) in field.options.indexed) ...[
            if (index > 0) SizedBox(height: 12.w),
            KycSelectionCard(
              label: option,
              selected: selected.contains(option),
              onTap: widget.enabled
                  ? () {
                      if (!selected.add(option)) selected.remove(option);
                      widget.onChanged(selected.join('|'));
                    }
                  : null,
            ),
          ],
          if (widget.error != null)
            Text(
              widget.error!,
              style: AppTextStyles.text(12, color: AppColors.error),
            ),
        ],
      );
    }
    return AppField(
      key: ValueKey(field.key),
      label: field.label,
      hint:
          field.kind == KycFieldKind.date &&
              widget.grouped &&
              field.hint == 'YYYY-MM-DD'
          ? 'DD / MM / YYYY'
          : field.hint.isEmpty
          ? 'Select ${field.label}'
          : field.hint,
      controller: _controller,
      focusNode: _focus,
      prefix: field.key == 'masterOffice' && widget.value.isNotEmpty
          ? const AppIcon(AppAssets.investorCourtFlag, size: 24)
          : null,
      prefixWidth: field.key == 'masterOffice' && widget.value.isNotEmpty
          ? 48.w
          : null,
      labelSpacing: widget.labelSpacing,
      borderColor: widget.outline ? AppColors.borderStrong : AppColors.border,
      fieldHeight: widget.multilineHeight == null
          ? null
          : widget.multilineHeight!.w *
                (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
                  1,
                  double.infinity,
                ),
      fillColor: widget.grouped ? AppColors.border : AppColors.surface,
      hintColor: widget.grouped ? AppColors.muted : AppColors.placeholder,
      hintWeight: FontWeight.w500,
      contentPadding:
          widget.contentPadding ??
          (widget.grouped
              ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.5.w)
              : null),
      error: widget.error,
      readOnly:
          !widget.enabled ||
          field.kind == KycFieldKind.choice ||
          field.kind == KycFieldKind.date,
      suffix: field.kind == KycFieldKind.choice && widget.showChoiceIndicator
          ? AppIcon(
              AppAssets.chevronDown,
              size:
                  field.key == 'masterOffice' ||
                      field.key == 'trustType' ||
                      field.key == 'stokvelType' ||
                      field.key == 'signatory' ||
                      field.key == 'frequency' ||
                      field.label == 'Bank Type'
                  ? 24
                  : 16,
            )
          : null,
      keyboardType: switch (field.kind) {
        KycFieldKind.email => TextInputType.emailAddress,
        KycFieldKind.phone => TextInputType.phone,
        KycFieldKind.number => TextInputType.number,
        KycFieldKind.amount => const TextInputType.numberWithOptions(
          decimal: true,
        ),
        KycFieldKind.multiline => TextInputType.multiline,
        _ => TextInputType.text,
      },
      maxLines: field.kind == KycFieldKind.multiline
          ? widget.multilineLines
          : 1,
      textInputAction: field.kind == KycFieldKind.multiline
          ? TextInputAction.newline
          : TextInputAction.next,
      onChanged: widget.enabled ? _changeValue : null,
      onTap: !widget.enabled
          ? null
          : () async {
              if (field.kind == KycFieldKind.choice) {
                if (KycChoiceSheet.hasAuthoredSheet(field)) {
                  final selected = await KycChoiceSheet.show(
                    context,
                    field,
                    widget.value,
                  );
                  if (context.mounted && selected != null) {
                    _changeValue(selected);
                  }
                  return;
                }
                final selected = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => SelectionSheetFrame(
                    height: (110 + field.options.length * 72).toDouble().clamp(
                      240,
                      640,
                    ),
                    title: field.label,
                    titleLeft: 60,
                    titleWidth: 273,
                    closeLeft: 13,
                    children: [
                      for (final option in field.options)
                        SelectionSheetRow(
                          label: option,
                          selected: widget.value == option,
                          divider: true,
                          onTap: () => Navigator.pop(context, option),
                        ),
                    ],
                  ),
                );
                if (context.mounted && selected != null) {
                  _changeValue(selected);
                }
              } else if (field.kind == KycFieldKind.date) {
                final now = DateTime.now();
                final selected = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(widget.value) ?? now,
                  firstDate: DateTime(1900),
                  lastDate: now,
                );
                if (context.mounted && selected != null) {
                  _changeValue(
                    '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}',
                  );
                }
              }
            },
    );
  }
}

class InvestorDocumentTile extends StatelessWidget {
  const InvestorDocumentTile({
    super.key,
    required this.title,
    required this.document,
    required this.onChoose,
    required this.onDelete,
    this.loading = false,
    this.error,
    this.enabled = true,
    this.centered = false,
    this.minimumHeight = 167,
    this.helperText,
    this.chooseLabel = 'Choose a file',
    this.showTitle = true,
    this.titleSpacing,
    this.titleLineHeight,
    this.showFileExtension = false,
    this.uploadAttempt,
    this.onRetry,
    this.onCancel,
  });
  final String title;
  final KycDocument? document;
  final VoidCallback onChoose;
  final VoidCallback onDelete;
  final bool loading;
  final bool enabled;
  final bool centered;
  final double minimumHeight;
  final String? helperText;
  final String chooseLabel;
  final bool showTitle;
  final double? titleSpacing;
  final double? titleLineHeight;
  final bool showFileExtension;
  final String? error;
  final KycUploadAttempt? uploadAttempt;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showTitle)
        Text(
          title,
          style: AppTextStyles.text(
            centered ? 14 : 18,
            weight: centered ? FontWeight.w500 : FontWeight.w700,
            height: titleLineHeight ?? (centered ? 22 / 14 : 1.2),
          ),
        ),
      if (showTitle) SizedBox(height: (titleSpacing ?? (centered ? 10 : 18)).w),
      if (uploadAttempt case final attempt?)
        KycDocumentUploadTile(
          title: title,
          attempt: attempt,
          onRetry: onRetry,
          onCancel: onCancel,
        )
      else if (document == null)
        Semantics(
          button: true,
          label: 'Choose a file for $title',
          child: InkWell(
            onTap: enabled && !loading ? onChoose : null,
            child: Container(
              decoration: BoxDecoration(
                color: centered ? AppColors.surface : AppColors.white,
                borderRadius: BorderRadius.circular(centered ? 12.r : 14.r),
              ),
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: error == null
                      ? AppColors.borderStrong
                      : AppColors.error,
                  radius: centered ? 12.r : 14.r,
                  strokeWidth: 1,
                  dashLength: 5,
                  gapLength: 4,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: centered ? minimumHeight.w : 0,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: (centered ? 12 : 36).w,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: centered
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        if (loading)
                          const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const AppIcon(AppAssets.investorUpload, size: 24),
                        SizedBox(
                          height:
                              (centered
                                      ? minimumHeight < 167
                                            ? minimumHeight <= 115
                                                  ? 9
                                                  : 14
                                            : 20
                                      : 16)
                                  .w,
                        ),
                        Text(
                          loading ? 'Uploading...' : chooseLabel,
                          style: AppTextStyles.text(
                            centered ? 14 : 18,
                            weight: centered
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: centered
                                ? AppColors.gray900
                                : AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 8.w),
                        Text(
                          helperText ??
                              (centered
                                  ? 'Ensure your ID is in PNG, JPG with a maximum\nfile size of 5MB.'
                                  : 'Ensure your file is in PNG, JPG or PDF with a maximum file size of 5MB.'),
                          textAlign: centered
                              ? TextAlign.center
                              : TextAlign.start,
                          style: AppTextStyles.text(
                            centered ? 12 : 14,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      else
        Semantics(
          button: enabled,
          label: 'Replace $title',
          child: InkWell(
            onTap: enabled && !loading ? onChoose : null,
            borderRadius: BorderRadius.circular(12.r),
            child: InvestorSurface(
              color: AppColors.white,
              radius: 12,
              padding: centered
                  ? EdgeInsets.fromLTRB(14.w, 16.w, 6.w, 13.w)
                  : EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
              child: Row(
                crossAxisAlignment: centered
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  AppIcon(
                    document!.mimeType == 'application/pdf'
                        ? AppAssets.investorDocumentPdf
                        : AppAssets.investorUpload,
                    size: 40,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          showFileExtension
                              ? document!.name
                              : document!.name.replaceFirst(
                                  RegExp(
                                    r'\.(pdf|png|jpe?g)$',
                                    caseSensitive: false,
                                  ),
                                  '',
                                ),
                          semanticsLabel: document!.name,
                          style: AppTextStyles.text(
                            centered ? 14 : 16,
                            weight: centered
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 7.w),
                        Wrap(
                          spacing: 4.w,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${(document!.bytes / 1024).ceil()} Kb ·',
                              style: AppTextStyles.text(
                                14,
                                color: AppColors.muted,
                              ),
                            ),
                            if (document!.rejection == null)
                              const AppIcon(
                                AppAssets.investorDocumentComplete,
                                size: 16,
                              ),
                            Text(
                              document!.rejection == null
                                  ? 'Completed'
                                  : 'Correction required',
                              style: AppTextStyles.text(
                                12,
                                color: document!.rejection == null
                                    ? AppColors.body
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (enabled)
                    InvestorIconButton(
                      asset: AppAssets.investorDocumentDelete,
                      size: centered ? 20 : 24,
                      alignment: centered
                          ? Alignment.topCenter
                          : Alignment.center,
                      label: 'Delete $title',
                      onPressed: loading ? null : onDelete,
                    ),
                ],
              ),
            ),
          ),
        ),
      if (error != null)
        Padding(
          padding: EdgeInsets.only(top: 8.w),
          child: Text(
            error!,
            style: AppTextStyles.text(12, color: AppColors.error),
          ),
        ),
    ],
  );
}
