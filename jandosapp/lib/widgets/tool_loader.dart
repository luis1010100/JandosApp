import 'dart:math' as math;
import 'package:flutter/material.dart';

class ToolLoader extends StatefulWidget {
  final double size;
  final Duration duration;

  const ToolLoader({
    super.key,
    this.size = 70,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<ToolLoader> createState() => _ToolLoaderState();
}

class _ToolLoaderState extends State<ToolLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.rotate(
        angle: _controller.value * 2 * math.pi,
        child: child,
      ),
      child: SizedBox(
        height: widget.size,
        width: widget.size,
        child: Image.asset("assets/tool.png"),
      ),
    );
  }
}
