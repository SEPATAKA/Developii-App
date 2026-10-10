import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class InvestorAmountField extends StatefulWidget {
  const InvestorAmountField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Enter Amount',
    this.error,
    this.fontSize = 56,
    this.fontWeight = FontWeight.w700,
    this.labelGap = 10,
    this.currency = Currency.zar,
    this.hintColor = AppColors.iconMuted,
    this.centered = true,
    this.groupDigits = false,
    this.valueColor = AppColors.text,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final String? error;
  final double fontSize;
  final FontWeight fontWeight;
  final double labelGap;
  final Currency currency;
  final Color hintColor;
  final bool centered;
  final bool groupDigits;
  final Color valueColor;
  @override
  State<InvestorAmountField> createState() => _InvestorAmountFieldState();
}

class _InvestorAmountFieldState extends State<InvestorAmountField> {
  late String _editingValue = widget.value;
  late final _controller = TextEditingController(text: _displayValue);
  final _focus = FocusNode();

  String get _displayValue {
    if (_focus.hasFocus || _editingValue.isEmpty) return _editingValue;
    final amount = MonetaryAmount.tryParse(_editingValue, widget.currency);
    if (amount == null) return _editingValue;
    final whole = (amount.minorUnits ~/ 100).toString();
    final formatted = widget.groupDigits
        ? whole.replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]},',
          )
        : whole;
    return '$formatted.${(amount.minorUnits % 100).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() {
    _syncValue();
    setState(() {});
  }

  void _syncValue() {
    final value = _displayValue;
    if (_controller.text != value) {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void didUpdateWidget(InvestorAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) _editingValue = widget.value;
    _syncValue();
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: widget.centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      Text(
        widget.label,
        textAlign: widget.centered ? TextAlign.center : TextAlign.start,
        style: AppTextStyles.text(
          14,
          color: AppColors.iconMuted,
          weight: FontWeight.w500,
        ),
      ),
      SizedBox(height: widget.labelGap.w),
      Semantics(
        container: true,
        label: '${widget.label}, ${widget.currency.code}',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final style = AppTextStyles.text(
              widget.fontSize,
              weight: widget.fontWeight,
              color: widget.value.isEmpty
                  ? widget.hintColor
                  : widget.valueColor,
            );
            double measure(String text) {
              final painter = TextPainter(
                text: TextSpan(text: text, style: style),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout();
              final width = painter.width;
              painter.dispose();
              return width;
            }

            final symbol = '${widget.currency.symbol} ';
            final width =
                (measure(_controller.text.isEmpty ? '0.00' : _controller.text) +
                        4.w)
                    .clamp(44.0, constraints.maxWidth - measure(symbol));
            return Align(
              alignment: widget.centered
                  ? Alignment.center
                  : AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(child: Text(symbol, style: style)),
                  SizedBox(
                    width: width,
                    child: TextField(
                      key: const ValueKey('investor-amount'),
                      controller: _controller,
                      focusNode: _focus,
                      onChanged: (value) {
                        _editingValue = value;
                        widget.onChanged(value);
                        setState(() {});
                      },
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [LengthLimitingTextInputFormatter(15)],
                      textAlign: widget.centered
                          ? TextAlign.center
                          : TextAlign.start,
                      style: style,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: '0.00',
                        hintStyle: style,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      if (widget.error != null)
        Padding(
          padding: EdgeInsets.only(top: 8.w),
          child: Text(
            widget.error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.text(14, color: AppColors.error),
          ),
        ),
    ],
  );
}

class InvestorAmountPresets extends StatelessWidget {
  const InvestorAmountPresets({
    super.key,
    required this.values,
    required this.onSelected,
    this.currency = Currency.zar,
    this.selectedValue,
  });
  final List<int> values;
  final ValueChanged<String> onSelected;
  final Currency currency;
  final String? selectedValue;
  @override
  Widget build(BuildContext context) {
    final selected = MonetaryAmount.tryParse(
      selectedValue ?? '',
      currency,
    )?.minorUnits;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in values) _preset(value, selected == value * 100),
        ],
      ),
    );
  }

  Widget _preset(int value, bool selected) => Padding(
    padding: EdgeInsets.only(right: 12.w),
    child: TextButton(
      onPressed: () => onSelected('$value'),
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Semantics(
        selected: selected,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderStrong,
            ),
            borderRadius: BorderRadius.circular(40.r),
          ),
          child: Text(
            '${currency.symbol}$value',
            style: AppTextStyles.text(
              14,
              weight: FontWeight.w500,
              color: selected ? AppColors.white : AppColors.iconMuted,
            ),
          ),
        ),
      ),
    ),
  );
}
