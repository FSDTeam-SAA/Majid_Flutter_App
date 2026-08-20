import 'package:flutter/material.dart';

import 'app_motion.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.97,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.quick,
      reverseDuration: AppMotion.quick,
    );
    _scale = Tween<double>(
      begin: 1,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.easeInOut));
  }

  @override
  void didUpdateWidget(covariant PressableScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _controller.value != 0) {
      _controller.reverse();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _controller.forward();
  }

  void _handlePointerEnd(PointerEvent event) {
    if (!_controller.isAnimating && _controller.value == 0) return;
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
      ),
    );
  }
}
