import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';

/// A single 4-digit PIN entry prompt, used for both "verify existing PIN"
/// and (twice, back to back) "set a new PIN" flows — see
/// `settings_screen.dart`'s `_showSetPinFlow` for how the two are composed.
class PinEntryDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? errorText;

  const PinEntryDialog({super.key, required this.title, this.subtitle, this.errorText});

  /// Shows the dialog and resolves to the entered 4-digit PIN, or null if
  /// the user cancelled.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? errorText,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => PinEntryDialog(title: title, subtitle: subtitle, errorText: errorText),
    );
  }

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.length == 4) {
      Navigator.of(context).pop(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.subtitle != null) ...[
            Text(widget.subtitle!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 4,
            style: const TextStyle(fontSize: 28, letterSpacing: 12),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              errorText: widget.errorText,
              hintText: '••••',
            ),
            onChanged: (_) => setState(() {}), // refresh Confirm's enabled state
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _controller.text.length == 4 ? _submit : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
