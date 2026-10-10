import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_store.dart';
import 'package:developify_mobile/features/onboarding/presentation/widgets/onboarding_chrome.dart';
import 'package:developify_mobile/features/onboarding/presentation/widgets/onboarding_illustrations.dart';
import 'package:developify_mobile/features/onboarding/presentation/widgets/welcome_content.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onReady,
    this.landownerPortal = false,
  });
  final VoidCallback onReady;
  final bool landownerPortal;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 700), () {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        widget.onReady();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: AppColors.darkTeal,
      body: Center(child: SplashBrand(landownerPortal: widget.landownerPortal)),
    ),
  );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.store});
  final OnboardingStore store;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  static const _initialPhysicalPage = 40000;
  late int _physicalPage = _initialPhysicalPage + widget.store.page;
  late final PageController _controller = PageController(
    initialPage: _physicalPage,
    keepPage: false,
  );
  Timer? _dwell;
  final Set<int> _pointers = {};
  bool _scrolling = false;
  bool _navigating = false;
  bool _visible = false;
  bool _reducedMotion = false;
  bool _precached = false;
  bool _tickerVisible = false;
  ModalRoute<dynamic>? _route;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  bool get _illustrationsActive =>
      _visible && _lifecycle == AppLifecycleState.resumed && !_navigating;
  bool get _canAdvance =>
      mounted && _illustrationsActive && !_scrolling && _pointers.isEmpty;

  @override
  void initState() {
    super.initState();
    _lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route) {
      _observeRoute(false);
      _route = route;
      _observeRoute(true);
    }
    _tickerVisible = TickerMode.valuesOf(context).enabled;
    _visible = _routeVisible;
    _reducedMotion = AppDurations.reducedMotion(context);
    if (!_precached) {
      _precached = true;
      for (final image in <ImageProvider>[
        const ResizeImage(
          AssetImage(AppAssets.onboardingPin),
          width: 71,
          height: 71,
        ),
        const ResizeImage(AssetImage(AppAssets.onboardingKey), width: 120),
        for (final asset in [
          AppAssets.onboardingIndividual,
          AppAssets.onboardingCompany,
          AppAssets.onboardingTrust,
          AppAssets.onboardingStokvel,
        ])
          ResizeImage(AssetImage(asset), width: 157),
      ]) {
        unawaited(precacheImage(image, context));
      }
    }
    _restartDwell();
  }

  bool get _routeVisible =>
      _tickerVisible &&
      (_route?.isCurrent ?? true) &&
      (_route?.animation?.isCompleted ?? true) &&
      (_route?.secondaryAnimation?.isDismissed ?? true);

  void _observeRoute(bool subscribe) {
    for (final animation in [_route?.animation, _route?.secondaryAnimation]) {
      if (subscribe) {
        animation?.addStatusListener(_routeAnimationChanged);
      } else {
        animation?.removeStatusListener(_routeAnimationChanged);
      }
    }
  }

  void _routeAnimationChanged(AnimationStatus status) {
    if (!mounted) return;
    setState(() => _visible = _routeVisible);
    _restartDwell();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() => _lifecycle = state);
    _restartDwell();
  }

  void _cancelDwell() {
    _dwell?.cancel();
    _dwell = null;
  }

  void _restartDwell() {
    _cancelDwell();
    if (_canAdvance && !_reducedMotion) {
      _dwell = Timer(AppDurations.onboardingDwell, () => _move(1));
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.horizontal) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _cancelDwell();
      setState(() => _scrolling = true);
    } else if (notification is ScrollEndNotification) {
      setState(() => _scrolling = false);
      _restartDwell();
    }
    return false;
  }

  void _pointerDown(PointerDownEvent event) {
    _pointers.add(event.pointer);
    _cancelDwell();
  }

  void _pointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    _restartDwell();
  }

  Future<void> _move(int direction) async {
    _cancelDwell();
    if (!_canAdvance || !_controller.hasClients) return;
    final next = _physicalPage + direction;
    if (_reducedMotion) {
      _controller.jumpToPage(next);
    } else {
      await _controller.animateToPage(
        next,
        duration: AppDurations.onboardingPage,
        curve: Curves.easeInOutCubic,
      );
    }
    if (mounted) _restartDwell();
  }

  static const _pages = [
    (
      title: 'Pin your land in seconds',
      description:
          'We use GPS to confirm exactly what you are submitting  matched against the Deeds Office, zoning records, and satellite imagery.',
      imageTop: 129.0,
      imageLeft: 13.0,
      imageHeight: 357.0,
      titleTop: 523.0,
      titleLeft: 12.0,
    ),
    (
      title: 'Keep title. Earn income.',
      description:
          'You stay the legal owner of your land. We build; you collect quarterly returns. No capital risk, no chasing tenants.',
      imageTop: 139.0,
      imageLeft: 12.0,
      imageHeight: 344.0,
      titleTop: 519.0,
      titleLeft: 14.0,
    ),
    (
      title: '38,000+ investors,\nready to fund.',
      description:
          'Once approved, your land is listed to our verified investor community. Most sites hit their funding target within 30 days.',
      imageTop: 136.0,
      imageLeft: 12.0,
      imageHeight: 343.0,
      titleTop: 512.0,
      titleLeft: 17.0,
    ),
    (
      title: 'Whoever holds\nthe title.',
      description:
          'Individual, company, trust, or stokvel we onboard every entity type. One flow, one compliance team.',
      imageTop: 136.0,
      imageLeft: 12.0,
      imageHeight: 336.0,
      titleTop: 512.0,
      titleLeft: 17.0,
    ),
  ];

  @override
  void dispose() {
    _cancelDwell();
    _observeRoute(false);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    _cancelDwell();
    setState(() => _navigating = true);
    widget.store.finish();
    context.goNamed(Routes.welcome);
  }

  void _next() {
    _cancelDwell();
    if (widget.store.isLast) {
      _finish();
      return;
    }
    unawaited(_move(1));
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Listener(
      onPointerDown: _pointerDown,
      onPointerUp: _pointerUp,
      onPointerCancel: _pointerUp,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Observer(
                builder: (_) => OnboardingHeader(page: widget.store.page),
              ),
              Expanded(
                child: Observer(
                  builder: (_) => Semantics(
                    container: true,
                    label:
                        '${_pages[widget.store.page].title}. ${_pages[widget.store.page].description}',
                    onScrollLeft: () => _move(1),
                    onScrollRight: () => _move(-1),
                    child: ExcludeSemantics(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onScroll,
                        child: PageView.builder(
                          key: const ValueKey('onboarding-pages'),
                          controller: _controller,
                          onPageChanged: (physicalPage) {
                            _physicalPage = physicalPage;
                            widget.store.setPage(physicalPage % _pages.length);
                          },
                          itemBuilder: (context, physicalPage) {
                            final index = physicalPage % _pages.length;
                            final page = _pages[index];
                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: (page.imageTop - 102.505).w),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: page.imageLeft.w,
                                    ),
                                    child: Semantics(
                                      image: true,
                                      label: page.title,
                                      excludeSemantics: true,
                                      child: Observer(
                                        builder: (_) {
                                          final logicalPage = widget.store.page;
                                          return TickerMode(
                                            enabled:
                                                _illustrationsActive &&
                                                !_scrolling &&
                                                physicalPage == _physicalPage &&
                                                logicalPage == index,
                                            child: RepaintBoundary(
                                              child: switch (index) {
                                                0 =>
                                                  const LocationIllustration(),
                                                1 =>
                                                  const TitleDeedIllustration(),
                                                2 =>
                                                  const InvestorsIllustration(),
                                                _ =>
                                                  const EntitiesIllustration(),
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        (page.titleTop -
                                                page.imageTop -
                                                page.imageHeight)
                                            .w,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: page.titleLeft.w,
                                      right: 24.w,
                                    ),
                                    child: SizedBox(
                                      width: 343.w,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            page.title,
                                            style: AppTextStyles.heading
                                                .copyWith(
                                                  color: AppColors.black,
                                                ),
                                          ),
                                          SizedBox(height: 17.w),
                                          Text(
                                            page.description,
                                            style: AppTextStyles.text(
                                              16,
                                              color: AppColors.description,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.w),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Observer(
                builder: (_) => OnboardingActionArea(
                  left: widget.store.page == 1 ? 14 : 12,
                  onNext: _next,
                  onSkip: _finish,
                  isLast: widget.store.isLast,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      body: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [WelcomeHero(), WelcomeFeatures()],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(12.w, 12.w, 12.w, 0),
        child: Padding(
          padding: EdgeInsets.only(bottom: 2.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: 'List my land',
                onPressed: () => context.pushNamed(Routes.signUp),
              ),
              SizedBox(height: 15.w),
              AppButton(
                label: 'I already have an account',
                style: AppButtonStyle.secondary,
                onPressed: () => context.pushNamed(Routes.signIn),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
