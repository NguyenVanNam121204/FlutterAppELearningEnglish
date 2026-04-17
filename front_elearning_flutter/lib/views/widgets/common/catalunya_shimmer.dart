import 'package:flutter/material.dart';

class CatalunyaShimmer extends StatefulWidget {
  const CatalunyaShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE9EEF6),
    this.highlightColor = const Color(0xFFF7FAFF),
    this.duration = const Duration(milliseconds: 1300),
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  @override
  State<CatalunyaShimmer> createState() => _CatalunyaShimmerState();
}

class _CatalunyaShimmerState extends State<CatalunyaShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
      builder: (context, _) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.2 + 2.4 * t, -0.15),
              end: Alignment(-0.2 + 2.4 * t, 0.15),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
