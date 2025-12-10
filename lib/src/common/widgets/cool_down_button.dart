import 'package:flutter/material.dart';

/// A simple IconButton wrapper that shows a loading indicator while the async
/// operation is in progress and prevents duplicate presses.
///
/// The button will be disabled while the [onPressed] callback is executing,
/// and will show a loading indicator instead of the icon.
class CooldownWrapperIconButton extends StatefulWidget {
  /// The icon to display within the button.
  final Widget icon;

  /// The callback that is called when the button is tapped.
  /// If this is null, the button will be disabled.
  /// This function can be asynchronous.
  final Future<void> Function()? onPressed;

  /// @deprecated This parameter is no longer used. The button now stays
  /// disabled until the async operation completes.
  final Duration? cooldownDuration;

  const CooldownWrapperIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.cooldownDuration, // Kept for backward compatibility, but ignored
  });

  @override
  State<CooldownWrapperIconButton> createState() => _CooldownWrapperIconButtonState();
}

class _CooldownWrapperIconButtonState extends State<CooldownWrapperIconButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    // If already loading or no onPressed callback is provided, do nothing.
    if (_isLoading || widget.onPressed == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onPressed!();
    } catch (e) {
      debugPrint('Error during CooldownWrapperIconButton onPressed execution: $e');
    } finally {
      // Re-enable button only after operation completes
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.icon,
      onPressed: (_isLoading || widget.onPressed == null) ? null : _handlePress,
    );
  }
}
