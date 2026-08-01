import 'package:flutter/material.dart';
import 'package:linko_app/gen/strings.g.dart';
import 'package:linko_app/core/navigation/router.dart';

class ErrorDialog extends StatelessWidget {
  final String error;

  const ErrorDialog({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.dialogs.errorDialog.title),
      content: SelectableText(error),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(t.general.close),
        ),
      ],
    );
  }
}
