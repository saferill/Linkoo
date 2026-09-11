import 'package:flutter/material.dart';
import 'package:linko_app/core/navigation/router.dart';
import 'package:linko_app/gen/strings.g.dart';
import 'package:linko_app/pages/selected_files_page.dart';
import 'package:linko_app/pages/tabs/send_tab_vm.dart';
import 'package:linko_app/pages/troubleshoot_page.dart';
import 'package:linko_app/pages/web_share_page.dart';
import 'package:linko_app/provider/animation_provider.dart';
import 'package:linko_app/provider/favorites_provider.dart';
import 'package:linko_app/provider/local_ip_provider.dart';
import 'package:linko_app/provider/network/nearby_devices_provider.dart';
import 'package:linko_app/provider/network/scan_facade.dart';
import 'package:linko_app/provider/network/send_provider.dart';
import 'package:linko_app/provider/network/server/server_provider.dart';
import 'package:linko_app/provider/selection/selected_sending_files_provider.dart';
import 'package:linko_app/provider/settings_provider.dart';
import 'package:linko_app/util/native/file_picker.dart';
import 'package:linko_app/widget/device_avatar.dart';
import 'package:linko_app/widget/dialogs/address_input_dialog.dart';
import 'package:linko_app/widget/file_thumbnail.dart';
import 'package:linko_app/widget/pulse_widget.dart';
import 'package:linko_app/widget/responsive_list_view.dart';
import 'package:linko_app/widget/rotating_widget.dart';
import 'package:linko_isolates/model/device.dart';
import 'package:linko_isolates/util/file_size_helper.dart';
import 'package:refena_flutter/addons.dart';
import 'package:refena_flutter/refena_flutter.dart';

class DevicesTab extends StatefulWidget {
  const DevicesTab({super.key});

  @override
  State<DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends State<DevicesTab> with Refena {
  @override
  void initState() {
    super.initState();
    ensureRef((ref) async {
      await ref.global.dispatchAsync(SendTabInitAction(context));
    });
  }

  Future<void> _handleSendToDevice(BuildContext context, Device device) async {
    final currentSelection = ref.read(selectedSendingFilesProvider);
    if (currentSelection.isNotEmpty) {
      await ref.notifier(sendProvider).startSession(
            target: device,
            files: currentSelection,
            background: false,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terkirim ke ${device.alias}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    await _showSendSheet(context, device);
  }

  Future<void> _showSendSheet(BuildContext context, Device device) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final options = FilePickerOption.getOptionsForPlatform();

    final selectedOption = await showModalBottomSheet<FilePickerOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    DeviceAvatar(
                      fingerprint: device.fingerprint,
                      size: 44,
                      borderRadius: 14,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.alias,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            device.deviceModel ?? device.ip ?? 'Online',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Select content to send',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: options.map((opt) {
                    return InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(opt),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(opt.icon, size: 28, color: colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              opt.label,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedOption == null || !context.mounted) return;

    // Clear previous selection
    ref.redux(selectedSendingFilesProvider).dispatch(ClearSelectionAction());

    // Pick files based on selected option
    await ref.global.dispatchAsync(
      PickFileAction(
        option: selectedOption,
        context: context,
      ),
    );

    if (!context.mounted) return;

    final pickedFiles = ref.read(selectedSendingFilesProvider);
    if (pickedFiles.isNotEmpty) {
      await ref.notifier(sendProvider).startSession(
            target: device,
            files: pickedFiles,
            background: false,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terkirim ke ${device.alias}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final serverState = context.watch(serverProvider);
    final alias = context.watch(settingsProvider.select((s) => s.alias));
    final localIps = context.watch(localIpProvider.select((s) => s.localIps));
    final nearbyDevicesState = context.watch(nearbyDevicesProvider);
    final nearbyDevices = nearbyDevicesState.allDevices.values.toList();
    final favoriteDevices = context.watch(favoritesProvider);
    final animations = context.watch(animationProvider);
    final selectedFiles = context.watch(selectedSendingFilesProvider);

    // Merge favorites that might be offline
    final onlineFingerprints = nearbyDevices.map((d) => d.fingerprint).toSet();
    final offlineFavorites = favoriteDevices
        .where((f) => !onlineFingerprints.contains(f.fingerprint))
        .toList();

    return ResponsiveListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // 1. My Device Hero Card
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    PulseWidget(
                      active: serverState != null && animations,
                      duration: const Duration(milliseconds: 2400),
                      child: DeviceAvatar(
                        fingerprint: serverState?.alias ?? alias,
                        size: 56,
                        borderRadius: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serverState?.alias ?? alias,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: serverState != null
                                      ? Colors.green
                                      : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                serverState != null
                                    ? 'Online • Ready to Share'
                                    : t.general.offline,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (localIps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.wifi_rounded, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'IP: ${localIps.join(', ')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () async {
                            await context.global.dispatchAsync(
                              NavigateAction.push(const WebSharePage()),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.language_rounded, size: 14, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Web Share',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        if (selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Selection Preview Banner (Shared Intent / Pending Files)
          Card(
            elevation: 0,
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: InkWell(
              onTap: () => context.push(() => const SelectedFilesPage()),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: SmartFileThumbnail.fromCrossFile(selectedFiles.first),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'READY TO SEND',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedFiles.length == 1
                                      ? selectedFiles.first.name
                                      : '${selectedFiles.length} files selected',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedFiles.length == 1
                                ? selectedFiles.first.size.asReadableFileSize
                                : '${selectedFiles.first.name}${selectedFiles.length > 1 ? ', ...' : ''} • ${selectedFiles.fold<int>(0, (prev, curr) => prev + curr.size).asReadableFileSize}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      onPressed: () {
                        ref.redux(selectedSendingFilesProvider).dispatch(ClearSelectionAction());
                      },
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // 2. Available Devices Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.sendTab.nearbyDevices,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () async {
                    final device = await showDialog<Device?>(
                      context: context,
                      builder: (_) => const AddressInputDialog(),
                    );
                    if (device != null && context.mounted) {
                      await _handleSendToDevice(context, device);
                    }
                  },
                  icon: const Icon(Icons.add_link_rounded, size: 20),
                  tooltip: t.sendTab.manualSending,
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () async {
                    await ref.global.dispatchAsync(StartSmartScan());
                  },
                  icon: RotatingWidget(
                    duration: const Duration(seconds: 2),
                    spinning: nearbyDevicesState.runningFavoriteScan || nearbyDevicesState.runningIps.isNotEmpty,
                    child: const Icon(Icons.refresh_rounded, size: 20),
                  ),
                  tooltip: t.sendTab.scan,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 3. Online Devices List
        if (nearbyDevices.isEmpty && offlineFavorites.isEmpty)
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.radar_rounded,
                    size: 48,
                    color: colorScheme.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${t.sendTab.scan}...',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.sendTab.help,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => context.push(() => const TroubleshootPage()),
                    icon: const Icon(Icons.help_outline_rounded, size: 16),
                    label: Text(t.troubleshootPage.title),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Online Discovered Devices
          ...nearbyDevices.map((device) {
            final isFavorite = favoriteDevices.any((f) => f.fingerprint == device.fingerprint);
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: DeviceAvatar(
                  fingerprint: device.fingerprint,
                  size: 48,
                  borderRadius: 14,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        device.alias,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    if (isFavorite)
                      Icon(Icons.star_rounded, size: 18, color: colorScheme.primary),
                  ],
                ),
                subtitle: Text(
                  '${device.deviceModel ?? device.deviceType.name} • ${device.ip ?? 'Online'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => _handleSendToDevice(context, device),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Send'),
                ),
                onTap: () => _handleSendToDevice(context, device),
              ),
            );
          }),

          // Offline Favorite Devices
          ...offlineFavorites.map((fav) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Opacity(
                  opacity: 0.5,
                  child: DeviceAvatar(
                    fingerprint: fav.fingerprint,
                    size: 48,
                    borderRadius: 14,
                  ),
                ),
                title: Opacity(
                  opacity: 0.5,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          fav.alias,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                      Icon(Icons.star_outline_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
                subtitle: Opacity(
                  opacity: 0.4,
                  child: Text(
                    '${fav.ip}:${fav.port} • Offline',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  ),
                ),
                trailing: Text(
                  'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.outline,
                  ),
                ),
                onTap: null, // Disabled when offline
              ),
            );
          }),
        ],
      ],
    );
  }
}
