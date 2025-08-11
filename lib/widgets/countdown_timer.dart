import 'package:flutter/material.dart';
import 'dart:async';

class CountdownTimer extends StatefulWidget {
  final DateTime targetTime;
  final bool isLive;
  final TextStyle? textStyle;
  final Color? color;

  const CountdownTimer({
    super.key,
    required this.targetTime,
    required this.isLive,
    this.textStyle,
    this.color,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> with TickerProviderStateMixin {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isExpired = false;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _calculateRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    _remaining = widget.targetTime.difference(now);
    _isExpired = _remaining.isNegative;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateRemaining();
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return 'Expired';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m ${seconds}s';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.isLive ? '' : 'Starting in: ';
    final timeText = _isExpired ? 'Expired' : _formatDuration(_remaining);
    
    // Determine color and urgency based on time remaining
    Color textColor;
    Color backgroundColor;
    bool isUrgent = false;
    bool isVeryUrgent = false;
    
    if (_isExpired) {
      textColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
    } else if (widget.isLive) {
      // For live auctions
      if (_remaining.inMinutes < 5) {
        textColor = Colors.red;
        backgroundColor = Colors.red.withOpacity(0.15);
        isVeryUrgent = true;
        isUrgent = true;
      } else if (_remaining.inHours < 1) {
        textColor = Colors.red;
        backgroundColor = Colors.red.withOpacity(0.1);
        isUrgent = true;
      } else if (_remaining.inHours < 6) {
        textColor = Colors.orange;
        backgroundColor = Colors.orange.withOpacity(0.1);
      } else {
        textColor = widget.color ?? Theme.of(context).primaryColor;
        backgroundColor = (widget.color ?? Theme.of(context).primaryColor).withOpacity(0.1);
      }
    } else {
      // For upcoming auctions
      if (_remaining.inMinutes < 30) {
        textColor = Colors.blue;
        backgroundColor = Colors.blue.withOpacity(0.15);
        isUrgent = true;
      } else if (_remaining.inHours < 1) {
        textColor = Colors.blue;
        backgroundColor = Colors.blue.withOpacity(0.1);
        isUrgent = true;
      } else {
        textColor = widget.color ?? Theme.of(context).primaryColor;
        backgroundColor = (widget.color ?? Theme.of(context).primaryColor).withOpacity(0.1);
      }
    }
    
    // Start animations for urgent countdowns
    if (isVeryUrgent && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    } else if (isUrgent && !isVeryUrgent && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isUrgent && _pulseController.isAnimating) {
      _pulseController.stop();
      _glowController.stop();
    }
    
    Widget timerWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: isUrgent ? 2 : 1,
        ),
        boxShadow: isUrgent ? [
          BoxShadow(
            color: textColor.withOpacity(0.2),
            blurRadius: isVeryUrgent ? 12 : 8,
            spreadRadius: isVeryUrgent ? 2 : 1,
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Urgency indicator dot
          if (isUrgent) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: textColor.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Timer text
          Flexible(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: prefix,
                    style: (widget.textStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ))?.copyWith(
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                  TextSpan(
                    text: timeText,
                    style: (widget.textStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ))?.copyWith(
                      color: textColor,
                      fontSize: isUrgent ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    
    // Apply animations if urgent
    if (isVeryUrgent) {
      return AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: textColor.withOpacity(_glowAnimation.value * 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: timerWidget,
            ),
          );
        },
      );
    } else if (isUrgent) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: timerWidget,
          );
        },
      );
    }
    
    return timerWidget;
  }
} 