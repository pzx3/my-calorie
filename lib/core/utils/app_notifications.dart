import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class AppNotifications {
  static void showTop(BuildContext context, String message, {bool isError = true}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        message: message,
        isError: isError,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _TopNotificationWidget extends StatefulWidget {
  const _TopNotificationWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget> with SingleTickerProviderStateMixin {
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _handleDismiss();
    });
  }

  void _handleDismiss() {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);
    // Wait for the exit animation to finish before removing from overlay
    Future.delayed(const Duration(milliseconds: 400), () {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _handleDismiss,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isError ? AppColors.coral : AppColors.teal,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
          .animate(target: _isDismissing ? 0 : 1)
          .slideY(begin: -1.5, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
          .fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}
