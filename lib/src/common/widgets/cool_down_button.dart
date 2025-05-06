import 'dart:async';
import 'package:flutter/material.dart';

/// A simple IconButton wrapper that introduces a cooldown period after being pressed.
///
/// The button will be disabled for the specified [cooldownDuration] (defaulting
/// to 10 seconds) after its [onPressed] callback is invoked.
/// This widget is designed for minimal changes, taking only the essential
/// `icon` and `onPressed` callback.
class CooldownWrapperIconButton extends StatefulWidget {
  /// The icon to display within the button.
  final Widget icon;

  /// The callback that is called when the button is tapped.
  /// If this is null, the button will be disabled.
  /// This function can be asynchronous.
  final Future<void> Function()? onPressed;

  /// The duration for which the button should be disabled after a press.
  /// Defaults to 10 seconds.
  final Duration cooldownDuration;

  const CooldownWrapperIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.cooldownDuration = const Duration(seconds: 10),
  });

  @override
  State<CooldownWrapperIconButton> createState() => _CooldownWrapperIconButtonState();
}

class _CooldownWrapperIconButtonState extends State<CooldownWrapperIconButton> {
  bool _isCoolingDown = false;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _handlePress() async {
    // If already in cooldown or no onPressed callback is provided, do nothing.
    // This check is a safeguard; the button's own disabled state should also prevent this.
    if (_isCoolingDown || widget.onPressed == null) {
      return;
    }

    // Start cooldown: Set state to disable the button and start the timer.
    setState(() {
      _isCoolingDown = true;
    });

    _cooldownTimer = Timer(widget.cooldownDuration, () {
      // Ensure the widget is still mounted before updating state
      if (mounted) {
        setState(() {
          _isCoolingDown = false;
        });
      }
    });

    // Execute the provided onPressed callback
    try {
      await widget.onPressed!();
    } catch (e) {
      debugPrint('Error during CooldownWrapperIconButton onPressed execution: $e');
      // If an error occurs, the cooldown still continues as initiated.
      // You could add specific error handling here if needed, e.g., resetting cooldown.
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: widget.icon,
      // Disable the button if it's currently cooling down or if the onPressed callback is null.
      onPressed: (_isCoolingDown || widget.onPressed == null) ? null : _handlePress,
    );
  }
}
