import 'package:flutter/material.dart';

class HomeNotificationButton extends StatefulWidget {
  const HomeNotificationButton({
    super.key,
    required this.unreadCount,
    required this.isLoading,
    required this.onTap,
  });

  final int unreadCount;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<HomeNotificationButton> createState() => _HomeNotificationButtonState();
}

class _HomeNotificationButtonState extends State<HomeNotificationButton>
    with TickerProviderStateMixin {
  late final AnimationController _bellController;
  late final AnimationController _badgePulseController;
  late final Animation<double> _rotation;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _rotation = Tween<double>(
      begin: -0.065,
      end: 0.065,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_bellController);
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_badgePulseController);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant HomeNotificationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldAnimate = widget.unreadCount > 0;
    if (shouldAnimate && !_bellController.isAnimating) {
      _bellController.repeat(reverse: true);
    }
    if (shouldAnimate && !_badgePulseController.isAnimating) {
      _badgePulseController.repeat(reverse: true);
    }
    if (!shouldAnimate && _bellController.isAnimating) {
      _bellController.stop();
      _bellController.reset();
    }
    if (!shouldAnimate && _badgePulseController.isAnimating) {
      _badgePulseController.stop();
      _badgePulseController.reset();
    }
  }

  @override
  void dispose() {
    _bellController.dispose();
    _badgePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.unreadCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Thông báo',
          onPressed: widget.onTap,
          icon: widget.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : AnimatedBuilder(
                  animation: _rotation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: hasUnread ? _rotation.value : 0,
                      child: child,
                    );
                  },
                  child: Icon(
                    hasUnread
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                  ),
                ),
        ),
        if (hasUnread)
          Positioned(
            right: 7,
            top: 7,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1, end: 1),
              duration: const Duration(milliseconds: 1),
              builder: (context, _, child) {
                return AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, pulseChild) {
                    return Transform.scale(
                      scale: _pulse.value,
                      child: pulseChild,
                    );
                  },
                  child: child,
                );
              },
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
