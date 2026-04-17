import 'package:flutter/material.dart';

class CatalunyaPillButton extends StatefulWidget {
  const CatalunyaPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.enabled = true,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry padding;

  @override
  State<CatalunyaPillButton> createState() => _CatalunyaPillButtonState();
}

class _CatalunyaPillButtonState extends State<CatalunyaPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && widget.onTap != null;
    final bg = widget.backgroundColor ?? const Color(0xFF41D6E3);
    final fg = widget.foregroundColor ?? Colors.white;

    return GestureDetector(
      onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: canTap ? () => setState(() => _pressed = false) : null,
      onTapUp: canTap
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.96 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: canTap ? bg : const Color(0xFFD6E0EA),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: canTap
                  ? bg.withValues(alpha: 0.85)
                  : const Color(0xFFC2CFDB),
            ),
            boxShadow: canTap
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.35),
                      blurRadius: _pressed ? 6 : 14,
                      offset: Offset(0, _pressed ? 2 : 6),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: fg),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
