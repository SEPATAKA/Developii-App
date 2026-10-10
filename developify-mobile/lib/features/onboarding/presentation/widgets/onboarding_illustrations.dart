import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';

class LocationIllustration extends StatelessWidget {
  const LocationIllustration({super.key});

  @override
  Widget build(BuildContext context) => _Artboard(
    width: 368,
    height: 357,
    color: AppColors.emerald100,
    children: [
      const Positioned.fill(child: CustomPaint(painter: _MapPainter())),
      _at(162, 75.938, 81, 81, const LocationPulse()),
      _at(
        182.25,
        96.188,
        40.5,
        40.5,
        DecoratedBox(
          key: const ValueKey('location-marker'),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.emerald600,
            border: Border.all(color: AppColors.white, width: 5.063.w),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackAlpha64,
                offset: Offset(0, 5.063.w),
                blurRadius: 15.188.w,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 11.391.w,
                top: 8.115.w,
                width: 17.71875.w,
                height: 17.71875.w,
                child: Image.asset(
                  AppAssets.onboardingPin,
                  key: const ValueKey('onboarding-pin-artwork'),
                  width: 17.71875.w,
                  height: 17.71875.w,
                  cacheWidth: 71,
                  cacheHeight: 71,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ),
      ),
      _at(
        190,
        19,
        149.344,
        30.375,
        _pill([
          _at(
            12.656,
            10.125,
            10.125,
            10.125,
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.emerald500,
                shape: BoxShape.circle,
              ),
            ),
          ),
          _artText(
            '-26.076, 27.958',
            30.375,
            7.594,
            108,
            13.922,
            weight: FontWeight.w600,
          ),
        ]),
      ),
      _at(
        17.719,
        280.969,
        124.031,
        27.844,
        _pill([
          _artText(
            '± 2 m accuracy',
            15.188,
            7.594,
            102,
            12.656,
            weight: FontWeight.w600,
          ),
        ]),
      ),
    ],
  );
}

class LocationPulse extends StatefulWidget {
  const LocationPulse({super.key});
  @override
  State<LocationPulse> createState() => _LocationPulseState();
}

class _LocationPulseState extends State<LocationPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = AppDurations.reducedMotion(context);
    if (TickerMode.valuesOf(context).enabled && !_reducedMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      if (_reducedMotion) _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 2; i++)
            Transform.scale(
              key: ValueKey('location-pulse-$i'),
              scale: _reducedMotion
                  ? 1
                  : .75 + ((_controller.value + i * .5) % 1) * .5,
              child: Container(
                width: (i == 0 ? 81 : 55.688).w,
                height: (i == 0 ? 81 : 55.688).w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald500.withValues(
                    alpha: _reducedMotion
                        ? (i == 0 ? .2 : .3)
                        : (i == 0 ? .3 : .4) *
                              math.sin(
                                math.pi * ((_controller.value + i * .5) % 1),
                              ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 368, size.height / 357);
    final grid = Paint()..color = AppColors.onboardingEmeraldSoft;
    for (var i = 0; i < 7; i++) {
      canvas.drawRect(Rect.fromLTWH(i * 58.668, -10, 1.477, 378.159), grid);
    }
    for (var i = 0; i < 6; i++) {
      canvas.drawRect(Rect.fromLTWH(0, 42 + i * 59.266, 368, 1.266), grid);
    }
    final road = Paint()..color = AppColors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(25.313, 215.156, 354.375, 10.125),
        const Radius.circular(5.063),
      ),
      road,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(164.531, 0, 7.594, 324),
        const Radius.circular(3.797),
      ),
      road,
    );
    const plot = Rect.fromLTWH(183.516, 101.25, 101.25, 82.266);
    canvas.drawRect(plot, Paint()..color = AppColors.onboardingEmeraldMedium);
    final outline = Paint()
      ..color = AppColors.emerald600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.531;
    final path = Path()..addRect(plot.deflate(1.2655));
    for (final metric in path.computeMetrics()) {
      for (var offset = 0.0; offset < metric.length; offset += 8.859) {
        canvas.drawPath(metric.extractPath(offset, offset + 5.063), outline);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => false;
}

class TitleDeedIllustration extends StatelessWidget {
  const TitleDeedIllustration({super.key});

  @override
  Widget build(BuildContext context) => _Artboard(
    width: 369,
    height: 344,
    color: AppColors.amber50,
    children: [
      _at(
        72,
        17,
        225.558,
        279.052,
        Center(
          child: Transform.rotate(
            angle: -4 * math.pi / 180,
            child: SizedBox(
              width: 207.563.w,
              height: 265.219.w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18.45.w),
                  border: Border.all(color: AppColors.amber200, width: 2.306.w),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blackAlpha38,
                      offset: Offset(0, 9.225.w),
                      blurRadius: 23.063.w,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.144.w),
                  child: Stack(
                    children: [
                      _artText(
                        'DEEDS OFFICE · RSA',
                        13.836,
                        16.146,
                        185,
                        9.225,
                        weight: FontWeight.w700,
                        color: AppColors.amber800,
                        tracking: 2.306,
                      ),
                      _artText(
                        'TITLE DEED',
                        13.836,
                        32.286,
                        185,
                        16.144,
                        weight: FontWeight.w700,
                      ),
                      _line(13.836, 59.966, 172.969, 2.306, AppColors.amber100),
                      for (final line in [
                        (76.106, 149.906),
                        (87.636, 126.844),
                        (99.166, 103.781),
                      ])
                        _line(
                          13.836,
                          line.$1,
                          line.$2,
                          5.766,
                          AppColors.borderStrong,
                          radius: 2.306,
                        ),
                      _artText(
                        'OWNER',
                        13.836,
                        126.846,
                        180,
                        9.225,
                        weight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                      _artText(
                        'Themba Nkosi',
                        13.836,
                        142.986,
                        180,
                        12.684,
                        weight: FontWeight.w700,
                      ),
                      _artText(
                        'ERF NUMBER',
                        13.836,
                        172.966,
                        180,
                        9.225,
                        weight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                      _artText(
                        '4412 · Randburg',
                        13.836,
                        189.116,
                        180,
                        12.684,
                        weight: FontWeight.w700,
                      ),
                      _line(
                        13.836,
                        219.096,
                        172.969,
                        3.459,
                        AppColors.border,
                        radius: 2.306,
                      ),
                      _line(
                        13.836,
                        228.316,
                        138.375,
                        3.459,
                        AppColors.border,
                        radius: 2.306,
                      ),
                      _at(
                        118.286,
                        224.856,
                        67.79,
                        67.79,
                        Center(
                          child: Transform.rotate(
                            angle: 15 * math.pi / 180,
                            child: Container(
                              width: 55.35.w,
                              height: 55.35.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.red600,
                                    AppColors.redMuted,
                                    AppColors.red900,
                                  ],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  _artText(
                                    'SEAL',
                                    0,
                                    19.6,
                                    55.35,
                                    10.378,
                                    weight: FontWeight.w700,
                                    color: AppColors.white,
                                    align: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
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
      ),
      _at(
        221,
        17.3,
        146.657,
        87.772,
        Center(
          child: Transform.rotate(
            angle: 8 * math.pi / 180,
            child: Container(
              width: 138.375.w,
              height: 69.188.w,
              decoration: BoxDecoration(
                color: AppColors.emerald600,
                borderRadius: BorderRadius.circular(13.838.w),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackAlpha77,
                    offset: Offset(0, 6.919.w),
                    blurRadius: 18.45.w,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  _artText(
                    'STAYS WITH',
                    0,
                    13.838,
                    138.375,
                    10.378,
                    weight: FontWeight.w600,
                    color: AppColors.white,
                    tracking: 1.153,
                    align: TextAlign.center,
                  ),
                  _artText(
                    'YOU',
                    0,
                    29.981,
                    138.375,
                    25.369,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      _at(
        23.063,
        230.625,
        64.575,
        64.575,
        FloatingTitleKey(
          child: DecoratedBox(
            key: const ValueKey('title-key'),
            decoration: BoxDecoration(
              color: AppColors.amber200,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.amber500, width: 3.459.w),
            ),
            child: Stack(
              children: [
                _at(
                  17.297,
                  15.108,
                  29.981,
                  29.981,
                  Image.asset(
                    AppAssets.onboardingKey,
                    key: const ValueKey('title-key-artwork'),
                    cacheWidth: 120,
                    excludeFromSemantics: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class FloatingTitleKey extends StatefulWidget {
  const FloatingTitleKey({super.key, required this.child});
  final Widget child;
  @override
  State<FloatingTitleKey> createState() => _FloatingTitleKeyState();
}

class _FloatingTitleKeyState extends State<FloatingTitleKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.onboardingKey,
  );
  static final _lift = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 15),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -7.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 23,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -7.0,
        end: 2.5,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 22,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 2.5,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 15,
    ),
    TweenSequenceItem(tween: ConstantTween(0), weight: 25),
  ]);
  static final _rotation = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 15),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -.04,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 23,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -.04,
        end: .06,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 22,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: .06,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 15,
    ),
    TweenSequenceItem(tween: ConstantTween(0), weight: 25),
  ]);
  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1), weight: 15),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.05,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 23,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.05,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 37,
    ),
    TweenSequenceItem(tween: ConstantTween(1), weight: 25),
  ]);
  bool _active = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active =
        TickerMode.valuesOf(context).enabled &&
        !AppDurations.reducedMotion(context);
    if (active && !_active) {
      _controller.repeat(min: 0, max: 1);
    } else {
      if (!active) {
        _controller.stop();
        _controller.value = 0;
      }
    }
    _active = active;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Transform.translate(
          key: const ValueKey('title-key-float'),
          offset: Offset(0, _lift.evaluate(_controller).w),
          child: Transform.rotate(
            key: const ValueKey('title-key-rotation'),
            angle: _rotation.evaluate(_controller),
            child: Transform.scale(
              key: const ValueKey('title-key-scale'),
              scale: _scale.evaluate(_controller),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

class InvestorsIllustration extends StatefulWidget {
  const InvestorsIllustration({super.key});
  @override
  State<InvestorsIllustration> createState() => _InvestorsIllustrationState();
}

class _InvestorsIllustrationState extends State<InvestorsIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  bool _active = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (AppDurations.reducedMotion(context)) {
      _controller.value = 1;
    } else if (active && !_active) {
      _controller.forward(from: 0);
    } else if (!active) {
      _controller.stop();
    }
    _active = active;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _initials = [
    ('A', 30.0, 49.0, 51.443, 51.443, AppColors.emerald600),
    ('T', 65.614, 49.0, 51.443, 51.443, AppColors.sky700),
    ('S', 101.229, 49.0, 51.443, 51.443, AppColors.violet600),
    ('M', 136.843, 49.0, 51.443, 51.443, AppColors.red600),
    ('K', 172.457, 49.0, 51.443, 51.443, AppColors.amber500),
    ('J', 208.071, 49.0, 51.443, 51.443, AppColors.cyan700),
    ('P', 236.0, 50.0, 52.0, 52.0, AppColors.cyan600),
    ('+38k', 243.686, 49.0, 63.314, 51.443, AppColors.deepInk),
  ];

  @override
  Widget build(BuildContext context) => _Artboard(
    width: 369,
    height: 343,
    color: AppColors.blue50,
    children: [
      for (var i = 0; i < _initials.length; i++)
        _at(
          _initials[i].$2,
          _initials[i].$3,
          _initials[i].$4,
          _initials[i].$5,
          AnimatedBuilder(
            animation: _controller,
            child: Container(
              decoration: BoxDecoration(
                color: _initials[i].$6,
                borderRadius: BorderRadius.circular(25.721.w),
                border: Border.all(
                  color: AppColors.white,
                  width: (i == 6 ? 4 : 3.957).w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: i == 7
                        ? AppColors.blackAlpha51
                        : AppColors.blackAlpha38,
                    offset: Offset(0, 3.957.w),
                    blurRadius: 7.914.w,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _initials[i].$1,
                  style: AppTextStyles.text(
                    i == 7 ? 11.871 : 17.807,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            builder: (context, child) {
              final t = Interval(
                i * .065,
                .42 + i * .065,
                curve: Curves.easeOut,
              ).transform(_controller.value);
              return Opacity(
                key: ValueKey('investor-initial-$i'),
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 6.w * (1 - t)),
                  child: child,
                ),
              );
            },
          ),
        ),
      _at(
        30,
        132.808,
        294,
        124.385,
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.354.w),
            border: Border.all(color: AppColors.borderStrong, width: 1.131.w),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackAlpha20,
                offset: Offset(0, 4.523.w),
                blurRadius: 13.569.w,
              ),
            ],
          ),
          child: Stack(
            children: [
              _artText(
                'Funding progress',
                15.831,
                15.831,
                130,
                12.438,
                weight: FontWeight.w600,
              ),
              _artText(
                '65%',
                15.831,
                15.831,
                260.077,
                13.569,
                weight: FontWeight.w700,
                color: AppColors.emerald700,
                align: TextAlign.right,
              ),
              _line(
                15.831,
                49.754,
                262.338,
                9.046,
                AppColors.borderStrong,
                radius: 4.523,
              ),
              _at(
                15.831,
                49.754,
                262.338,
                9.046,
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      key: const ValueKey('funding-progress-fill'),
                      width:
                          169.615.w *
                          Curves.easeOutCubic.transform(_controller.value),
                      height: 9.046.w,
                      decoration: BoxDecoration(
                        color: AppColors.emerald500,
                        borderRadius: BorderRadius.circular(4.523.w),
                      ),
                    ),
                  ),
                ),
              ),
              _artText(
                'R 1.56M raised',
                15.831,
                70.108,
                130,
                11.308,
                weight: FontWeight.w500,
                color: AppColors.muted,
              ),
              _artText(
                '24 investors · 5 days',
                15.831,
                70.108,
                262.338,
                11.308,
                weight: FontWeight.w500,
                color: AppColors.muted,
                align: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class EntitiesIllustration extends StatelessWidget {
  const EntitiesIllustration({super.key});
  static const _cards = [
    ('Individual', AppColors.emerald50, AppColors.emerald700),
    ('Company', AppColors.blue100, AppColors.blue800),
    ('Trust', AppColors.amber100, AppColors.amber800),
    ('Stokvel', AppColors.purple100, AppColors.purple800),
  ];
  static const _artwork = [
    AppAssets.onboardingIndividual,
    AppAssets.onboardingCompany,
    AppAssets.onboardingTrust,
    AppAssets.onboardingStokvel,
  ];
  @override
  Widget build(BuildContext context) => _Artboard(
    width: 369,
    height: 336,
    color: AppColors.fuchsia50,
    children: [
      for (var i = 0; i < 4; i++)
        _at(
          20 + (i % 2) * 171.111,
          29 + (i ~/ 2) * 136.889,
          158.889,
          122.222,
          DecoratedBox(
            key: ValueKey('entity-card-$i'),
            decoration: BoxDecoration(
              color: _cards[i].$2,
              borderRadius: BorderRadius.circular(22.w),
              border: Border.all(color: AppColors.white, width: 2.444.w),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackAlpha26,
                  offset: Offset(0, 7.333.w),
                  blurRadius: 14.667.w,
                ),
              ],
            ),
            child: Stack(
              children: [
                _at(
                  59.889,
                  16.738,
                  39.111,
                  39.111,
                  Image.asset(
                    _artwork[i],
                    key: ValueKey('entity-artwork-$i'),
                    cacheWidth: 157,
                    excludeFromSemantics: true,
                  ),
                ),
                _artText(
                  _cards[i].$1,
                  0,
                  70.889,
                  158.889,
                  14.667,
                  weight: FontWeight.w700,
                  color: _cards[i].$3,
                  align: TextAlign.center,
                ),
                _at(
                  69.666,
                  92.889,
                  20,
                  20,
                  SvgPicture.asset(AppAssets.entityVerifiedBadge),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _Artboard extends StatelessWidget {
  const _Artboard({
    required this.width,
    required this.height,
    required this.color,
    required this.children,
  });
  final double width, height;
  final Color color;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: MediaQuery.withNoTextScaling(
      child: Container(
        width: width.w,
        height: height.w,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: Stack(children: children),
      ),
    ),
  );
}

Widget _at(double x, double y, double width, double height, Widget child) =>
    Positioned(
      left: x.w,
      top: y.w,
      width: width.w,
      height: height.w,
      child: child,
    );

Widget _artText(
  String text,
  double x,
  double y,
  double width,
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.deepInk,
  double tracking = 0,
  TextAlign align = TextAlign.left,
}) => Positioned(
  left: x.w,
  top: y.w,
  width: width.w,
  child: Text(
    text,
    textAlign: align,
    maxLines: 1,
    style: AppTextStyles.text(
      size,
      weight: weight,
      color: color,
      height: 1.2,
    ).copyWith(letterSpacing: tracking.w),
  ),
);

Widget _line(
  double x,
  double y,
  double width,
  double height,
  Color color, {
  double radius = 0,
}) => _at(
  x,
  y,
  width,
  height,
  DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius.w),
    ),
  ),
);

Widget _pill(List<Widget> children) => DecoratedBox(
  decoration: BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(999),
  ),
  child: Stack(children: children),
);
