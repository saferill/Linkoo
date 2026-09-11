import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linko_app/core/navigation/router.dart';
import 'package:linko_app/gen/strings.g.dart';
import 'package:linko_app/model/cross_file.dart';
import 'package:linko_app/model/state/server/web_share_state.dart';
import 'package:linko_app/provider/local_ip_provider.dart';
import 'package:linko_app/provider/network/server/server_provider.dart';
import 'package:linko_app/provider/settings_provider.dart';
import 'package:linko_app/util/native/platform_check.dart';
import 'package:linko_app/util/ui/snackbar.dart';
import 'package:linko_app/widget/dialogs/pin_dialog.dart';
import 'package:linko_app/widget/dialogs/qr_dialog.dart';
import 'package:linko_app/widget/dialogs/zoom_dialog.dart';
import 'package:linko_app/widget/responsive_list_view.dart';
import 'package:linko_isolates/util/sleep.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';

final _logger = Logger('WebSharePage');

enum _ServerState { initializing, running, error, stopping }

/// Shares a link with web browsers, in one of two modes:
/// - send: offers [WebSharePage.files] for download.
/// - receive: serves the upload page so browsers can upload files to this device.
///   Incoming requests are not listed here because they open the receive page
///   like any other incoming request.
class WebSharePage extends StatefulWidget {
  /// The files offered for download (share via link).
  /// `null` serves the upload page instead (receive via link).
  final List<CrossFile>? files;

  const WebSharePage({this.files});

  @override
  State<WebSharePage> createState() => _WebSharePageState();
}

class _WebSharePageState extends State<WebSharePage> with Refena {
  _ServerState _stateEnum = _ServerState.initializing;
  bool _encrypted = false;
  String? _initializedError;

  bool get _sendMode => widget.files != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init(encrypted: false);
    });
  }

  void _init({required bool encrypted}) async {
    final settings = ref.read(settingsProvider);
    setState(() {
      _stateEnum = _ServerState.initializing;
      _encrypted = encrypted;
      _initializedError = null;
    });
    await sleepAsync(500);
    try {
      final files = widget.files;

      // The pin of a previous web share session is kept;
      // receive mode initially uses the receive pin from settings.
      final previousWeb = ref.read(serverProvider)?.web;
      final webPin = previousWeb != null ? previousWeb.pin : (files == null ? settings.receivePin : null);

      if (files != null) {
        // The auto accept setting of a previous web download state is kept.
        await ref
            .notifier(serverProvider)
            .restartServerWithWebDownload(
              alias: settings.alias,
              port: settings.port,
              https: _encrypted,
              files: files,
              pin: webPin,
            );
      } else {
        await ref
            .notifier(serverProvider)
            .restartServer(
              alias: settings.alias,
              port: settings.port,
              https: _encrypted,
              web: WebShareUpload(pin: webPin),
            );
      }
      setState(() {
        _stateEnum = _ServerState.running;
      });
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _stateEnum = _ServerState.error;
          _initializedError = e.toString();
        });
      }
    }
  }

  /// Web share uses unencrypted http by default, so we need to revert to the previous state.
  Future<void> _revertServerState() async {
    await ref.notifier(serverProvider).restartServerFromSettings();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) async {
        if (_stateEnum == _ServerState.initializing || _stateEnum == _ServerState.stopping) {
          return;
        }

        setState(() {
          _stateEnum = _ServerState.stopping;
        });
        await sleepAsync(250);
        try {
          // Also needed in the error state: the failed restart already stopped the old server.
          await _revertServerState();
        } catch (e) {
          _logger.warning('Failed to restore the server', e);
        }
        await sleepAsync(250);

        if (context.mounted) {
          context.pop();
        }
      },
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_sendMode ? t.webSharePage.title : t.webReceivePage.title),
        ),
        body: Builder(
          builder: (context) {
            if (_stateEnum != _ServerState.running) {
              return Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_stateEnum == _ServerState.initializing || _stateEnum == _ServerState.stopping) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        _stateEnum == _ServerState.initializing ? t.webSharePage.loading : t.webSharePage.stopping,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ] else if (_initializedError != null) ...[
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(t.webSharePage.error, style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SelectableText(_initializedError!, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ],
              );
            }

            final serverState = context.watch(serverProvider);
            final webDownloadState = serverState?.webDownloadState;
            if (serverState == null || (_sendMode && webDownloadState == null)) {
              // the server is restarting (e.g. because the pin changed)
              return const Center(child: CircularProgressIndicator());
            }
            final networkState = context.watch(localIpProvider);
            final settings = context.watch(settingsProvider);
            final pin = serverState.web?.pin;

            return ResponsiveListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                Text(t.webSharePage.openLink(n: networkState.localIps.length), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...networkState.localIps.map((ip) {
                        final url = '${_encrypted ? 'https' : 'http'}://$ip:${serverState.port}';
                        final urlWithPin = switch (pin) {
                          String() => '$url/?pin=${Uri.encodeQueryComponent(pin)}',
                          null => url,
                        };
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  url,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: t.general.copy,
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: url));
                                  if (context.mounted && checkPlatformIsDesktop()) {
                                    context.showSnackBar(t.general.copiedToClipboard);
                                  }
                                },
                                icon: const Icon(Icons.content_copy),
                              ),
                              IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: 'QR Code',
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => QrDialog(
                                      data: urlWithPin,
                                      label: url,
                                      listenIncomingWebDownloadRequests: _sendMode,
                                      pin: pin,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.qr_code),
                              ),
                              IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: 'Zoom',
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (_) => ZoomDialog(
                                      label: url,
                                      listenIncomingWebDownloadRequests: _sendMode,
                                      pin: pin,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.tv),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (webDownloadState != null) ...[
                  Text(t.webSharePage.requests, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (webDownloadState.sessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        t.webSharePage.noRequests,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ...webDownloadState.sessions.entries.map((entry) {
                    final session = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.deviceInfo,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: session.pending ? Theme.of(context).colorScheme.primary : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  session.ip,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (session.pending) ...[
                            IconButton(
                              onPressed: () {
                                ref.notifier(serverProvider).declineWebDownloadRequest(session.sessionId);
                              },
                              style: IconButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                              ),
                              icon: const Icon(Icons.close),
                            ),
                            IconButton(
                              onPressed: () {
                                ref.notifier(serverProvider).acceptWebDownloadRequest(session.sessionId);
                              },
                              style: IconButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.primary,
                              ),
                              icon: const Icon(Icons.check_circle),
                            ),
                          ] else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.general.accepted,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
                // Settings Section Bento Card
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        title: Text(t.webSharePage.encryption, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: _encrypted
                            ? Text(
                                t.webSharePage.encryptionHint,
                                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                              )
                            : null,
                        value: _encrypted,
                        onChanged: (value) => _init(encrypted: value),
                      ),
                      Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      SwitchListTile(
                        title: Text(t.webSharePage.autoAccept, style: const TextStyle(fontWeight: FontWeight.w600)),
                        value: webDownloadState != null ? webDownloadState.autoAccept : settings.receiveViaLinkAutoAccept,
                        onChanged: (value) async {
                          if (webDownloadState != null) {
                            ref.notifier(serverProvider).setWebDownloadAutoAccept(value);
                          } else {
                            await ref.notifier(settingsProvider).setReceiveViaLinkAutoAccept(value);
                          }
                        },
                      ),
                      Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      SwitchListTile(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        ),
                        title: Text(t.webSharePage.requirePin, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: pin != null
                            ? Text(
                                t.webSharePage.pinHint(pin: pin),
                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12),
                              )
                            : null,
                        value: pin != null,
                        onChanged: (value) async {
                          if (pin != null) {
                            await ref.notifier(serverProvider).setWebPin(null);
                          } else {
                            final String? newPin = await showDialog<String>(
                              context: context,
                              builder: (_) => const PinDialog(
                                obscureText: false,
                                generateRandom: true,
                              ),
                            );

                            if (newPin != null && newPin.isNotEmpty) {
                              await ref.notifier(serverProvider).setWebPin(newPin);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }
}
