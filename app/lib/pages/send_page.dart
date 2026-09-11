import 'dart:async';

import 'package:flutter/material.dart';
import 'package:linko_app/core/navigation/router.dart';
import 'package:linko_app/gen/strings.g.dart';
import 'package:linko_app/model/state/send/send_session_state.dart';
import 'package:linko_app/pages/verify_page.dart';
import 'package:linko_app/provider/device_info_provider.dart';
import 'package:linko_app/provider/favorites_provider.dart';
import 'package:linko_app/provider/file_transfer_provider.dart';
import 'package:linko_app/provider/network/send_provider.dart';
import 'package:linko_app/util/favorites.dart';
import 'package:linko_app/util/native/taskbar_helper.dart';
import 'package:linko_app/widget/animations/initial_fade_transition.dart';
import 'package:linko_app/widget/animations/initial_slide_transition.dart';
import 'package:linko_app/widget/dialogs/error_dialog.dart';
import 'package:linko_app/widget/list_tile/device_list_tile.dart';
import 'package:linko_app/widget/responsive_list_view.dart';
import 'package:linko_isolates/model/device.dart';
import 'package:linko_isolates/model/session_status.dart';
import 'package:refena_flutter/addons.dart';
import 'package:refena_flutter/refena_flutter.dart';

class SendPage extends StatefulWidget {
  final bool showAppBar;
  final bool closeSessionOnClose;
  final String sessionId;

  const SendPage({
    required this.showAppBar,
    required this.closeSessionOnClose,
    required this.sessionId,
  });

  @override
  State<SendPage> createState() => _SendPageState();
}

double _hashProgress(SendSessionState sendState, FileTransferNotifier transferNotifier) {
  final files = sendState.files.values;
  final totalBytes = files.fold<int>(0, (prev, curr) => prev + curr.file.size);
  if (totalBytes == 0) {
    return sendState.files.isEmpty ? 0 : sendState.hashedFileCount / sendState.files.length;
  }
  final hashedBytes = files.fold<double>(
    0,
    (prev, curr) => prev + transferNotifier.getProgress(sessionId: sendState.sessionId, fileId: curr.file.id) * curr.file.size,
  );
  return (hashedBytes / totalBytes).clamp(0, 1);
}

class _SendPageState extends State<SendPage> with Refena {
  Device? _myDevice;
  Device? _targetDevice;

  @override
  void dispose() {
    super.dispose();
    unawaited(TaskbarHelper.clearProgressBar());
  }

  void _cancel() {
    // the state will be lost so we store them temporarily (only for UI)
    final myDevice = ref.read(deviceFullInfoProvider);
    final sendState = ref.read(sendProvider)[widget.sessionId];
    if (sendState == null) {
      return;
    }

    setState(() {
      _myDevice = myDevice;
      _targetDevice = sendState.target;
    });
    ref.notifier(sendProvider).cancelSession(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final sendState = ref.watch(
      sendProvider.select((state) => state[widget.sessionId]),
      listener: (prev, next) {
        final prevStatus = prev[widget.sessionId]?.status;
        final nextStatus = next[widget.sessionId]?.status;
        if (prevStatus != nextStatus) {
          // ignore: discarded_futures
          TaskbarHelper.visualizeStatus(nextStatus);
        }
      },
    );
    if (sendState == null && _myDevice == null && _targetDevice == null) {
      return Scaffold(
        body: Container(),
      );
    }
    final myDevice = ref.watch(deviceFullInfoProvider);
    final targetDevice = sendState?.target ?? _targetDevice!;
    final targetFavoriteEntry = ref.watch(favoritesProvider.select((state) => state.findDevice(targetDevice)));
    final waiting = sendState?.status == SessionStatus.waiting;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && widget.closeSessionOnClose) {
          _cancel();
        }
      },
      canPop: true,
      child: Scaffold(
        appBar: widget.showAppBar ? AppBar() : null,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: ResponsiveListView.defaultMaxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          InitialSlideTransition(
                            origin: const Offset(0, -1),
                            duration: const Duration(milliseconds: 400),
                            child: DeviceListTile(
                              device: myDevice,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const InitialFadeTransition(
                            duration: Duration(milliseconds: 300),
                            delay: Duration(milliseconds: 400),
                            child: Icon(Icons.arrow_downward),
                          ),
                          const SizedBox(height: 20),
                          Hero(
                            tag: 'device-${targetDevice.ip}',
                            child: DeviceListTile(
                              device: targetDevice,
                              nameOverride: targetFavoriteEntry?.alias,
                            ),
                          ),
                          InitialFadeTransition(
                            duration: const Duration(milliseconds: 300),
                            delay: const Duration(milliseconds: 400),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: !targetDevice.https
                                    ? null
                                    : () async => await context.push(
                                        () => VerifyPage(
                                          fingerprint: CombinedFingerprint.load(context, targetDevice.fingerprint),
                                        ),
                                      ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                                ),
                                icon: Icon(Icons.verified_user),
                                label: Text(t.verifyPage.title),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sendState != null)
                      InitialFadeTransition(
                        duration: const Duration(milliseconds: 300),
                        delay: const Duration(milliseconds: 400),
                        child: Column(
                          children: [
                            switch (sendState.status) {
                              SessionStatus.waiting => Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: sendState.hashedFileCount < sendState.files.length
                                      ? Column(
                                          children: [
                                            Text(
                                              t.sendPage.calculatingChecksum(curr: sendState.hashedFileCount, n: sendState.files.length),
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                            const SizedBox(height: 15),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: SizedBox(
                                                width: 200,
                                                height: 8,
                                                child: LinearProgressIndicator(
                                                  value: _hashProgress(sendState, ref.watch(fileTransferProvider)),
                                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            t.sendPage.waiting,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                ),
                              SessionStatus.declined => Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      t.sendPage.rejected,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              SessionStatus.tooManyAttempts => Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      t.sendPage.tooManyAttempts,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              SessionStatus.recipientBusy => Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      t.sendPage.busy,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              SessionStatus.finishedWithErrors => Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(t.general.error, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                                      if (sendState.errorMessage != null)
                                        IconButton(
                                          style: IconButton.styleFrom(
                                            foregroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                          onPressed: () async => showDialog(
                                            context: context,
                                            builder: (_) => ErrorDialog(error: sendState.errorMessage!),
                                          ),
                                          icon: const Icon(Icons.info_outline, size: 20),
                                        ),
                                    ],
                                  ),
                                ),
                              _ => const SizedBox(),
                            },
                            Center(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                ),
                                onPressed: () {
                                  _cancel();
                                  context.global.dispatch(NavigateAction.popUntilRoot());
                                },
                                icon: Icon(waiting ? Icons.close : Icons.check_circle, size: 18),
                                label: Text(waiting ? t.general.cancel : t.general.close),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
