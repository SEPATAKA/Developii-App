import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/dashed_border.dart';
import 'package:developify_mobile/core/widgets/sheets.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/submission_store.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/upload_tile.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/submission_selection.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/submission_success_sheet.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/deeds_office_selection_sheet.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/property_selection_sheet.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/submission_progress.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class SubmissionScreen extends StatefulWidget {
  const SubmissionScreen({
    super.key,
    required this.store,
    required this.step,
    this.review = false,
  });
  final SubmissionStore store;
  final int step;
  final bool review;
  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  SubmissionStore get store => widget.store;
  final _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    store.setStep(widget.step);
  }

  @override
  void didUpdateWidget(SubmissionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != store) oldWidget.store.dispose();
    store.setStep(widget.step);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    store.dispose();
    super.dispose();
  }

  void _go(int step, {bool review = false}) {
    store.save();
    context.pushReplacementNamed(
      Routes.submit,
      pathParameters: {'step': '$step'},
      queryParameters: {'draft': store.draft.id, if (review) 'review': 'true'},
    );
  }

  void _exit() {
    store.save();
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Routes.home);
    }
  }

  void _back() {
    if (widget.review) {
      _go(9);
    } else if (store.step > 1) {
      _go(store.step - 1);
    } else {
      _exit();
    }
  }

  Future<void> _next() async {
    if (!store.next()) return;
    if (store.step < 9) {
      _go(widget.review ? 9 : store.step + 1);
      return;
    }
    final id = await store.submit();
    if (!mounted || id == null) return;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    final destination = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: AppColors.modalScrim,
      builder: (sheet) => SubmissionSuccessSheet(
        propertyName: store.draft.legalDescription.isEmpty
            ? store.draft.name
            : store.draft.legalDescription,
        reference: id,
        onTrack: () => Navigator.pop(sheet, Routes.properties),
        onDashboard: () => Navigator.pop(sheet, Routes.home),
        onClose: () => Navigator.pop(sheet),
      ),
    );
    if (mounted && store.status == LoadStatus.success) {
      context.goNamed(destination ?? Routes.properties);
    }
  }

  void _attach(String key) {
    store.addDocument(key);
  }

  Future<void> _select(
    String key,
    PropertySelection selection,
    String selected,
  ) async {
    final result = await showPropertySelectionSheet(
      context,
      selection: selection,
      selected: selected,
    );
    if (mounted && result != null) store.setField(key, result);
  }

  @override
  Widget build(BuildContext context) => Observer(builder: (_) => _page());

  Widget _page() => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: AppPage(
      title: 'Step ${store.draft.step} of 9',
      headerLayout: AppHeaderLayout.backAndAction,
      onBack: _back,
      trailing: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
        ),
        onPressed: _exit,
        child: Text(
          'Save & Exit',
          style: AppTextStyles.text(
            16,
            weight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      bottom: widget.step == 9 ? null : _footer(),
      child: SingleChildScrollView(
        controller: _scrollController,
        key: ValueKey(widget.step),
        padding: EdgeInsets.only(
          top:
              (widget.step == 1
                      ? (_basicsComplete ? 21 : 17)
                      : widget.step == 2
                      ? 17
                      : 22)
                  .w,
          bottom: (widget.step == 9 ? 25 : 20).w,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SubmissionProgress(
              step: widget.step,
              height: widget.step >= 5 && widget.step <= 7 ? 12 : 10,
            ),
            SizedBox(height: (widget.step == 1 && _basicsComplete ? 24 : 31).w),
            SizedBox(
              width: 343.w,
              child: Text(
                _titles[widget.step - 1],
                style: AppTextStyles.text(
                  32,
                  weight: FontWeight.w700,
                  color: AppColors.black,
                  height: 38 / 32,
                ),
              ),
            ),
            SizedBox(height: 7.w),
            SizedBox(
              width:
                  (widget.step == 7 && store.draft.entity == EntityType.trust
                          ? 370
                          : 343)
                      .w,
              child: widget.step == 7
                  ? Text.rich(
                      TextSpan(
                        children: store.draft.entity == EntityType.trust
                            ? [
                                const TextSpan(
                                  text: 'Your account entity is a ',
                                ),
                                const TextSpan(
                                  text: 'trust',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray900,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      ' so we need certified IDs for every serving trustee resolution naming this property.',
                                ),
                              ]
                            : [
                                const TextSpan(
                                  text: 'Based on your account entity ',
                                ),
                                TextSpan(
                                  text:
                                      '(${store.draft.entity.name[0].toUpperCase()}${store.draft.entity.name.substring(1)}) ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray900,
                                  ),
                                ),
                                const TextSpan(
                                  text: '— you only need your certified ID.',
                                ),
                              ],
                      ),
                      style: AppTextStyles.text(
                        16,
                        color: AppColors.muted,
                        height: 19 / 16,
                      ),
                    )
                  : Text(
                      _descriptions[widget.step - 1],
                      style: AppTextStyles.text(
                        16,
                        color: AppColors.muted,
                        height: 19 / 16,
                      ),
                    ),
            ),
            SizedBox(
              height: switch (widget.step) {
                3 => 25.w,
                4 => 14.w,
                5 || 6 => 33.w,
                7 => (store.draft.entity == EntityType.trust ? 16 : 21).w,
                8 => 34.w,
                9 => (store.draft.accepted ? 30 : 25).w,
                _ => 31.w,
              },
            ),
            Observer(builder: (_) => _body()),
            Observer(builder: (_) => InlineError(store.error)),
            if (widget.step == 9) ...[
              SizedBox(height: (store.draft.accepted ? 40 : 35).w),
              _footer(),
            ],
          ],
        ),
      ),
    ),
  );
  bool get _basicsComplete => store.validateStep(1).isEmpty;

  Widget _footer() => Padding(
    padding: EdgeInsets.only(
      bottom: switch (widget.step) {
        1 => 1.w,
        2 => 35.w,
        3 || 4 || 5 => 26.w,
        6 => 2.w,
        7 =>
          (store.draft.entity == EntityType.trust
                  ? (store.draft.documents.containsKey('trustees') ? 29 : 20)
                  : (store.draft.documents.containsKey('identity') ? 21 : 17))
              .w,
        8 => 28.w,
        _ => 0.0,
      },
    ),
    child: Observer(
      builder: (_) {
        final optional = widget.step >= 4 && widget.step <= 6;
        final attached = widget.step == 4
            ? store.draft.documents.containsKey('title')
            : widget.step == 5
            ? store.draft.documents.containsKey('rates')
            : [
                'zoning',
                'sdp',
                'plans',
                'occupancy',
              ].any(store.draft.documents.containsKey);
        final continueButton = AppButton(
          label: widget.review ? 'Save changes' : 'Continue',
          loading: store.status == LoadStatus.loading,
          onPressed:
              (widget.step == 7 || store.validateStep(widget.step).isEmpty) &&
                  (!optional || attached)
              ? _next
              : null,
        );
        if (optional && (widget.step != 6 || !attached)) {
          return Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Skip for now',
                  style: AppButtonStyle.secondary,
                  onPressed: () => _go(widget.review ? 9 : widget.step + 1),
                ),
              ),
              SizedBox(width: 13.w),
              Expanded(child: continueButton),
            ],
          );
        }
        return continueButton;
      },
    ),
  );

  static const _titles = [
    'Property Basics',
    'Location & GPS',
    'Site photos',
    'Title Deed',
    'Municipal Rates & Taxes',
    'Zoning & Optional docs',
    'Entity documents',
    'Deal preferences',
    'Review & Submit',
  ];
  static const _descriptions = [
    'Give us the headline information about this property.',
    'Drop the exact pin. We use this for zoning checks and site visits.',
    'At least 4 wide - angle photos showing the site from different angle. Recent ( within 3 months).',
    'Original title deed showing the current owner. If the deed is registered in the entity name, upload that version.',
    'Most recent rates account (≤ 3 months). We use this to confirm the property is in good standing.',
    "These aren't required but speed up viability review dramatically.",
    '',
    "Tell us what you want out of this. We'll come back with a proposal.",
    'Tap any section to edit. Once submitted, our team reviews within 5 – 10 business days.',
  ];
  Widget _field(
    String key,
    String label,
    String value,
    String hint, {
    TextInputType? keyboard,
    int lines = 1,
  }) => AppField(
    label: label,
    value: value,
    hint: hint,
    error: store.errors[key],
    keyboardType: keyboard,
    maxLines: lines,
    fillColor: AppColors.border,
    hintColor: AppColors.iconMuted,
    onChanged: (value) => store.setField(key, value),
  );
  Widget _selectField(
    String key,
    String label,
    String value,
    String hint,
    PropertySelection selection,
  ) => AppSelect(
    key: ValueKey('$key-selection-field'),
    label: label,
    value: value,
    hint: hint,
    error: store.errors[key],
    fillColor: AppColors.border,
    onTap: () => _select(key, selection, value),
  );
  Widget _gap([double? size]) =>
      SizedBox(height: (size ?? (widget.step == 1 ? 21 : 24)).w);
  Widget _document(
    String key,
    String title, {
    String subtitle = '',
    UploadTileLayout layout = UploadTileLayout.optional,
    String? attachedTitle,
  }) => UploadTile(
    title: title,
    subtitle: subtitle,
    layout: layout,
    attachedTitle: attachedTitle,
    fileName: store.draft.documents[key]?.name,
    error: store.errors[key],
    onTap: () => _attach(key),
    onRemove: () => store.removeDocument(key),
  );
  Widget _body() {
    final d = store.draft;
    switch (widget.step) {
      case 1:
        return Column(
          children: [
            _field('name', 'Property Name', d.name, 'Enter Property Name'),
            _gap(),
            _field(
              'number',
              'Property number',
              d.propertyNumber,
              'Enter Number',
            ),
            _gap(),
            _selectField(
              'type',
              'Property Type',
              d.propertyType,
              'E.g ( Vacant land, Existing building)',
              PropertySelection.propertyType,
            ),
            _gap(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 177.w,
                  child: _field(
                    'size',
                    'Property Size',
                    d.size,
                    'Size ',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                SizedBox(width: 13.w),
                Expanded(
                  child: AppField(
                    key: ValueKey('unit-${d.unit}'),
                    label: 'Unit',
                    value: d.unit,
                    hint: 'E.g Hectares',
                    readOnly: true,
                    fillColor: AppColors.border,
                    hintColor: AppColors.iconMuted,
                    onTap: () =>
                        _select('unit', PropertySelection.unit, d.unit),
                  ),
                ),
              ],
            ),
            _gap(),
            AppSelect(
              key: const ValueKey('deeds-office-field'),
              label: 'Deeds Office',
              value: d.deedsOffice,
              hint: 'Select Deed Office',
              error: store.errors['deeds'],
              fillColor: AppColors.border,
              onTap: () async {
                final office = await showDeedsOfficeSelectionSheet(
                  context,
                  selected: d.deedsOffice,
                );
                if (mounted && office != null) store.setField('deeds', office);
              },
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: 'Pin property location',
              child: InkWell(
                onTap: () {
                  store.setField('latitude', '-26.076245');
                  store.setField('longitude', '27.958114');
                },
                child: SizedBox(
                  width: 368.w,
                  height: 231.w,
                  child: Stack(
                    children: [
                      Image.asset(
                        AppAssets.siteMap,
                        width: 368.w,
                        height: 231.w,
                        fit: BoxFit.fill,
                      ),
                      Positioned(
                        left: 193.641.w,
                        top: 104.303.w,
                        width: 17.71875.w,
                        height: 17.71875.w,
                        child: Image.asset(
                          AppAssets.onboardingPin,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _gap(31),
            _field('address', 'Street Address', d.address, 'Enter Address'),
            _gap(21),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 177.w,
                  child: _field('town', 'Town', d.town, 'Size'),
                ),
                SizedBox(width: 13.w),
                Expanded(child: _field('city', 'City', d.city, 'E.g Hectares')),
              ],
            ),
            _gap(21),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field('province', 'Province', d.province, 'Size'),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _field(
                    'postal',
                    'Postal',
                    d.postalCode,
                    'Size',
                    keyboard: TextInputType.number,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _field('country', 'Country', d.country, 'Size'),
                ),
              ],
            ),
            _gap(21),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 177.w,
                  child: _field(
                    'latitude',
                    'GPS coordinates',
                    d.latitude,
                    '0',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
                SizedBox(width: 13.w),
                Expanded(
                  child: Semantics(
                    label: 'Longitude',
                    child: _field(
                      'longitude',
                      ' ',
                      d.longitude,
                      '0',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 357.w,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 21.w,
                  crossAxisSpacing: 15.w,
                ),
                itemBuilder: (_, index) {
                  final photo = index < d.photos.length
                      ? d.photos[index]
                      : null;
                  return DashedPhotoTile(
                    key: ValueKey('site-photo-$index'),
                    label: photo?.name,
                    asset: photo == null
                        ? null
                        : switch (photo.id) {
                            'photo-0' => AppAssets.sitePhotoPool,
                            'photo-1' => AppAssets.sitePhotoResidence,
                            _ => AppAssets.sitePhotoVilla,
                          },
                    onRemove: photo == null
                        ? null
                        : () => store.removePhoto(photo.id),
                    onTap: store.addSamplePhotos,
                  );
                },
              ),
            ),
            InlineError(store.errors['photos']),
            _gap(40),
            const SubmissionTips(
              title: 'Tips for a clean scan',
              bullets: [
                'Take photos in daylight',
                'Include boundary markets if possible',
                'Capture any existing structures',
              ],
            ),
          ],
        );
      case 4 || 5:
        final document = widget.step == 4 ? 'title' : 'rates';
        final attached = d.documents.containsKey(document);
        return Column(
          children: [
            if (attached) ...[
              _document(
                document,
                'Tap to upload',
                layout: UploadTileLayout.document,
              ),
              _gap(33),
            ],
            UploadTile(onTap: () => _attach(document)),
            _gap(
              attached
                  ? 22
                  : widget.step == 4
                  ? 112
                  : 110,
            ),
            const SubmissionTips(
              title: 'Don’t have it yet?',
              bullets: [
                'You can skip and add it later from the property detail page. Skipping means we may not be able to complete the viability review.',
              ],
            ),
          ],
        );
      case 6:
        return Column(
          children: [
            for (final (index, doc) in [
              ('zoning', 'Zoning Certificate'),
              ('sdp', 'Site Development Plan'),
              ('plans', 'Approved Building Plans'),
              ('occupancy', 'Occupancy Certificate'),
            ].indexed) ...[if (index > 0) _gap(20), _document(doc.$1, doc.$2)],
          ],
        );
      case 7:
        final trust = d.entity == EntityType.trust;
        final owners = d.documents.keys
            .where((key) => key.startsWith('co-owner'))
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: 'Entity type',
              child: InkWell(
                onTap: () async {
                  final entity = await showChoiceSheet<EntityType>(
                    context,
                    title: 'Entity type',
                    choices: {
                      for (final value in EntityType.values)
                        value:
                            '${value.name[0].toUpperCase()}${value.name.substring(1)} landowner',
                    },
                    selected: d.entity,
                  );
                  if (mounted && entity != null) {
                    store.update(store.draft.copyWith(entity: entity));
                  }
                },
                borderRadius: BorderRadius.circular(999.w),
                child: Container(
                  constraints: BoxConstraints(minWidth: 134.w),
                  padding: EdgeInsets.fromLTRB(
                    15.363281.w,
                    8.272949.w,
                    10.w,
                    8.727051.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(999.w),
                  ),
                  child: Text(
                    '${d.entity.name[0].toUpperCase()}${d.entity.name.substring(1)} landowner',
                    style: AppTextStyles.text(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.primary,
                      height: 14 / 12,
                    ),
                  ),
                ),
              ),
            ),
            _gap(trust ? 35 : 21),
            Text(
              trust ? 'Required for this submission' : 'Required',
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w600,
                color: AppColors.gray900,
                height: 17 / 14,
              ),
            ),
            _gap(13),
            if (trust) ...[
              for (final (index, doc) in [
                (
                  'trustees',
                  'Certificate ID Copy - 3  Trustees',
                  'Themba Nkosi, Adaeze Okoye, Johan Meyer',
                  'Certificate ID Copy - 3 Directors',
                ),
                (
                  'trust-resolution',
                  'Trustee resolution',
                  'LR-021 · authorising this submission',
                  'Certificate ID Copy - 3 Directors',
                ),
                (
                  'trust-deed',
                  'Trust Deed',
                  'LR-02 · signed by all serving trustees',
                  'CoR 14.3 registration certificate',
                ),
                (
                  'trust-mandate',
                  'Letters of Authority',
                  'Current, matching the trustee list',
                  'Certificate ID Copy - 3 Directors',
                ),
              ].indexed) ...[
                if (index > 0) _gap(13),
                _document(
                  doc.$1,
                  doc.$2,
                  subtitle: doc.$3,
                  layout: UploadTileLayout.trustees,
                  attachedTitle: doc.$4,
                ),
              ],
            ] else ...[
              _document(
                'identity',
                'Certificate ID Copy ( witin 3 months)',
                layout: UploadTileLayout.identity,
                attachedTitle: 'Certificate ID Copy (witin 3 months)',
              ),
              _gap(19),
              Text(
                'If any co-owners',
                style: AppTextStyles.text(
                  14,
                  weight: FontWeight.w600,
                  color: AppColors.gray900,
                  height: 17 / 14,
                ),
              ),
              _gap(13),
              for (final key in owners) ...[
                _document(key, 'Zoning Certificate'),
                _gap(13),
              ],
              Material(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(12.w),
                child: InkWell(
                  onTap: () {
                    store.update(d.copyWith(coOwners: true));
                    var index = owners.length + 1;
                    var key = owners.isEmpty ? 'co-owner' : 'co-owner-$index';
                    while (d.documents.containsKey(key)) {
                      index++;
                      key = 'co-owner-$index';
                    }
                    store.addDocument(key);
                  },
                  borderRadius: BorderRadius.circular(12.w),
                  child: CustomPaint(
                    painter: DashedBorderPainter(
                      color: AppColors.primary,
                      radius: 12.w,
                      strokeWidth: 1.w,
                      dashLength: 4.w,
                      gapLength: 4.w,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(15.w, 17.w, 15.w, 19.w),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36.w,
                            child: const Center(
                              child: AppIcon(
                                AppAssets.submissionCoOwnerAdd,
                                size: 19,
                              ),
                            ),
                          ),
                          SizedBox(width: 17.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add a co - owner',
                                  style: AppTextStyles.text(
                                    14,
                                    weight: FontWeight.w500,
                                    color: AppColors.gray900,
                                    height: 17 / 14,
                                  ),
                                ),
                                _gap(4),
                                Text(
                                  'Also needs a certified ID Copy',
                                  style: AppTextStyles.text(
                                    14,
                                    color: AppColors.description,
                                    height: 17 / 14,
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
              ),
            ],
          ],
        );
      case 8:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferred Structure',
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w600,
                color: AppColors.text,
                height: 17 / 14,
              ),
            ),
            _gap(13),
            for (final (index, option) in [
              ('Sell outright', 'Clean exit. You transfer title, we develop.'),
              (
                'Long - term lease',
                'Keep title. Earn monthly / quarterly rent.',
              ),
              (
                'Revenue share',
                'Keep title. Earn a share of investor returns.',
              ),
              ('Open to any proposal', 'We negotiate  show me offers.'),
            ].indexed) ...[
              if (index > 0) _gap(12),
              SubmissionDealChoice(
                title: option.$1,
                description: option.$2,
                selected: d.deal == option.$1,
                onTap: () => store.setField(
                  'deal',
                  d.deal == option.$1 ? '' : option.$1,
                ),
              ),
            ],
            _gap(9),
            Text(
              'Expected Value',
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w500,
                color: AppColors.text,
                height: 22 / 14,
              ),
            ),
            _gap(8),
            Container(
              padding: EdgeInsets.fromLTRB(18.w, 21.w, 18.w, 27.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10.w),
              ),
              child: Column(
                children: [
                  _field(
                    'price',
                    'Ballpark market value (ZAR)',
                    d.price,
                    'Enter Value',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _gap(21),
                  _field(
                    'monthly',
                    'Issuing Office',
                    d.monthlyLease,
                    'Enter Target Value',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _gap(21),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Valuation Report  ( If yes, upload) ',
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w500,
                            color: AppColors.black,
                            height: 17 / 14,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36.w,
                        height: 20.w,
                        child: OverflowBox(
                          minWidth: 44,
                          maxWidth: 44,
                          minHeight: 44,
                          maxHeight: 44,
                          child: SubmissionValuationSwitch(
                            value: d.hasValuation,
                            onChanged: (value) {
                              store.update(d.copyWith(hasValuation: value));
                              if (value) {
                                store.addDocument('valuation');
                              } else {
                                store.removeDocument('valuation');
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _gap(14),
            Text(
              'Payouts Account',
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w500,
                color: AppColors.text,
                height: 22 / 14,
              ),
            ),
            _gap(9),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14.w),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: const BoxDecoration(
                      color: AppColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: AppIcon(AppAssets.submissionBank),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Standard Bank · 0119',
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w500,
                            color: AppColors.gray900,
                            height: 18 / 14,
                          ),
                        ),
                        _gap(4),
                        Text(
                          'Themba Nkosi',
                          style: AppTextStyles.text(
                            14,
                            color: AppColors.iconMuted,
                            height: 18 / 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 9:
        return Column(
          children: [
            _review('Property', 1, {
              'Property Name': d.name,
              'Property Type': d.propertyType,
              'Size': '${d.size} ${d.unit}',
              'Property Number': d.propertyNumber,
            }),
            _review('Location', 2, {
              'Address': d.address,
              'City': d.city,
              'GPS': '${d.latitude}, ${d.longitude}',
            }),
            _review('Documents', 4, {
              'Title Deed': d.documents['title']?.name ?? 'Not provided',
              'Municipal Rate': d.documents['rates']?.name ?? 'Not provided',
              'Zoning Cert': d.documents['zoning']?.name ?? 'Not provided',
              'Site photos': '${d.photos.length} Uploaded',
              'SDP plan': d.documents['sdp']?.name ?? 'Not provided',
            }),
            _review('Entity', 7, {
              'Owner':
                  'Themba Nkosi ( ${d.entity.name[0].toUpperCase()}${d.entity.name.substring(1)})',
              'Certified ID':
                  d.documents['identity']?.name ??
                  d.documents['trustees']?.name ??
                  'Not provided',
            }),
            _review('Deal', 8, {
              'Structure': d.deal == 'Long - term lease'
                  ? 'Long term lease'
                  : d.deal.isEmpty
                  ? 'Open to any proposal'
                  : d.deal,
              'Est. Value': d.price.isEmpty
                  ? 'Open to proposal'
                  : _currency(d.price),
              'Monthly Lease': d.monthlyLease.isEmpty
                  ? 'To be agreed'
                  : _currency(d.monthlyLease),
              'Payout Account': 'Standard Bank - 0119',
            }),
            Semantics(
              checked: d.accepted,
              label: 'Submission declaration',
              child: Material(
                color: AppColors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.w),
                  side: const BorderSide(color: AppColors.borderStrong),
                ),
                child: InkWell(
                  onTap: () => store.update(d.copyWith(accepted: !d.accepted)),
                  borderRadius: BorderRadius.circular(10.w),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 13.5.w,
                    ),
                    child: Row(
                      children: [
                        SubmissionCheckbox(selected: d.accepted),
                        SizedBox(width: 13.w),
                        Expanded(
                          child: Text(
                            'I confirm I have the legal authority to submit this property and consent to Developify performing due-diligence checks including deed-office verification.',
                            style: AppTextStyles.text(
                              14,
                              weight: FontWeight.w500,
                              color: AppColors.gray900,
                              height: 17 / 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            InlineError(store.errors['accepted']),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _currency(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = clean.split('.');
    final grouped = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'R $grouped${parts.length > 1 ? '.${parts[1]}' : ''}';
  }

  Widget _review(String title, int step, Map<String, String> values) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w500,
                height: 17 / 14,
              ),
            ),
          ),
          SizedBox(
            width: 24.w,
            height: 17.w,
            child: OverflowBox(
              minWidth: 44,
              maxWidth: 44,
              minHeight: 44,
              maxHeight: 44,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () => _go(step, review: true),
                child: Text(
                  'Edit',
                  style: AppTextStyles.text(
                    14,
                    weight: FontWeight.w500,
                    color: AppColors.primary,
                    height: 17 / 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      _gap(title == 'Deal' && !store.draft.accepted ? 22 : 12),
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10.w),
        ),
        child: Column(
          children: [
            for (final (index, entry) in values.entries.indexed) ...[
              if (index > 0) ...[
                _gap(10),
                const Divider(
                  height: 0,
                  thickness: 1,
                  color: AppColors.borderStrong,
                ),
                _gap(16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120.w,
                    child: Text(
                      entry.key,
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w500,
                        color: AppColors.muted,
                        height: 17 / 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: entry.key == 'Address' ? 128.w : null,
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w500,
                            color: AppColors.gray900,
                            height: 17 / 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      _gap(22),
    ],
  );
}
