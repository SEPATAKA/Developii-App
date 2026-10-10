import 'package:flutter/material.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class AppTransitionPage extends Page<void> {
  const AppTransitionPage({
    required super.key,
    required super.name,
    required this.child,
    required this.reducedMotion,
    this.upward = false,
  });

  final Widget child;
  final bool reducedMotion;
  final bool upward;

  @override
  Route<void> createRoute(BuildContext context) => _AppPageRoute(this);
}

class _AppPageRoute extends PageRoute<void> {
  _AppPageRoute(AppTransitionPage page) : super(settings: page);
  AppTransitionPage get _page => settings as AppTransitionPage;

  @override
  bool get maintainState => true;
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  Duration get transitionDuration =>
      _page.reducedMotion ? Duration.zero : AppDurations.routeForward;
  @override
  Duration get reverseTransitionDuration =>
      _page.reducedMotion ? Duration.zero : AppDurations.routeReverse;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: _page.child,
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduced = AppDurations.reducedMotion(context);
    final direction = Directionality.of(context) == TextDirection.ltr
        ? 1.0
        : -1.0;
    final content = AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final curve = animation.status == AnimationStatus.reverse
            ? Curves.easeInCubic
            : Curves.easeOutCubic;
        final t = reduced
            ? 1.0
            : popGestureInProgress
            ? animation.value
            : curve.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: _page.upward
                ? Offset(0, 14 * (1 - t))
                : Offset(14 * direction * (1 - t), 0),
            child: child,
          ),
        );
      },
    );
    if (Theme.of(context).platform != TargetPlatform.iOS) return content;
    return _BackSwipe(route: this, controller: controller!, child: content);
  }
}

class _BackSwipe extends StatefulWidget {
  const _BackSwipe({
    required this.route,
    required this.controller,
    required this.child,
  });
  final PageRoute<void> route;
  final AnimationController controller;
  final Widget child;
  @override
  State<_BackSwipe> createState() => _BackSwipeState();
}

class _BackSwipeState extends State<_BackSwipe> {
  NavigatorState? _navigator;
  double get _direction =>
      Directionality.of(context) == TextDirection.ltr ? 1 : -1;

  void _start(DragStartDetails details) {
    if (!widget.route.popGestureEnabled) return;
    _navigator = widget.route.navigator;
    _navigator?.didStartUserGesture();
  }

  void _update(DragUpdateDetails details) {
    if (_navigator == null) return;
    widget.controller.value -=
        _direction * details.delta.dx / MediaQuery.sizeOf(context).width;
  }

  void _stopGesture() {
    final navigator = _navigator;
    _navigator = null;
    if (navigator?.mounted ?? false) navigator!.didStopUserGesture();
  }

  Future<void> _end(double velocity, {bool cancelled = false}) async {
    if (_navigator == null) return;
    final pop =
        !cancelled &&
        (velocity.abs() > 300
            ? velocity * _direction > 0
            : widget.controller.value < .5);
    if (pop) {
      _navigator!.pop();
    }
    try {
      if (pop) {
        await widget.controller
            .animateBack(0, duration: widget.route.reverseTransitionDuration)
            .orCancel;
      } else {
        await widget.controller
            .animateTo(
              1,
              duration: widget.route.transitionDuration,
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      }
    } on TickerCanceled {
      // Removing the route during an interactive pop also cancels its ticker.
    } finally {
      _stopGesture();
    }
  }

  @override
  void dispose() {
    _stopGesture();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      widget.child,
      PositionedDirectional(
        start: 0,
        top: 0,
        bottom: 0,
        width: 24,
        child: IgnorePointer(
          ignoring: !widget.route.popGestureEnabled && _navigator == null,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _start,
            onHorizontalDragUpdate: _update,
            onHorizontalDragEnd: (details) =>
                _end(details.velocity.pixelsPerSecond.dx),
            onHorizontalDragCancel: () => _end(0, cancelled: true),
          ),
        ),
      ),
    ],
  );
}
