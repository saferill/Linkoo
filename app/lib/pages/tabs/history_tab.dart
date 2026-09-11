import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linko_app/gen/strings.g.dart';
import 'package:linko_app/model/persistence/receive_history_entry.dart';
import 'package:linko_app/provider/receive_history_provider.dart';
import 'package:linko_app/provider/settings_provider.dart';
import 'package:linko_app/util/native/directories.dart';
import 'package:linko_app/util/native/open_file.dart';
import 'package:linko_app/util/native/open_folder.dart';
import 'package:linko_app/util/native/platform_check.dart';
import 'package:linko_app/widget/dialogs/file_info_dialog.dart';
import 'package:linko_app/widget/dialogs/history_clear_dialog.dart';
import 'package:linko_app/widget/file_thumbnail.dart';
import 'package:linko_app/widget/responsive_list_view.dart';
import 'package:linko_isolates/model/file_type.dart';
import 'package:linko_isolates/util/file_size_helper.dart';
import 'package:path/path.dart' as path;
import 'package:refena_flutter/refena_flutter.dart';

enum _HistoryOption {
  open,
  showInFolder,
  viewMessage,
  info,
  delete,
}

enum _HistoryFilter {
  all,
  media,
  document,
  apk,
  message,
  other,
}

class HistoryTab extends StatefulWidget {
  final bool isStandalonePage;

  const HistoryTab({
    this.isStandalonePage = false,
    super.key,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  _HistoryFilter _selectedFilter = _HistoryFilter.all;

  Future<void> _openFile(
    BuildContext context,
    ReceiveHistoryEntry entry,
    Dispatcher<ReceiveHistoryService, List<ReceiveHistoryEntry>> dispatcher,
  ) async {
    if (entry.path != null) {
      await openFile(
        context,
        entry.fileType,
        entry.path!,
        onDeleteTap: () => dispatcher.dispatchAsync(RemoveHistoryEntryAction(entry.id)),
      );
    }
  }

  Future<void> _showMessageDialog(BuildContext context, ReceiveHistoryEntry entry) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: colorScheme.surfaceContainerLow,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.senderAlias,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    entry.timestampString,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: SelectableText(
            entry.fileName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: entry.fileName));
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: const Text('Message copied to clipboard'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<ReceiveHistoryEntry> _filterEntries(List<ReceiveHistoryEntry> entries) {
    if (_selectedFilter == _HistoryFilter.all) return entries;
    return entries.where((entry) {
      switch (_selectedFilter) {
        case _HistoryFilter.media:
          return !entry.isMessage && (entry.fileType == FileType.image || entry.fileType == FileType.video);
        case _HistoryFilter.document:
          return !entry.isMessage && (entry.fileType == FileType.pdf || entry.fileType == FileType.text);
        case _HistoryFilter.apk:
          return !entry.isMessage && entry.fileType == FileType.apk;
        case _HistoryFilter.message:
          return entry.isMessage;
        case _HistoryFilter.other:
          return !entry.isMessage && entry.fileType == FileType.other;
        case _HistoryFilter.all:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = context.watch(receiveHistoryProvider);
    final dispatcher = context.redux(receiveHistoryProvider);

    final totalBytes = entries.fold<int>(0, (prev, curr) => prev + curr.fileSize);
    final filteredEntries = _filterEntries(entries);
    final hasMessages = entries.any((e) => e.isMessage);

    return ResponsiveListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ── 1. Hero Summary Bento Card ──────────────────────────────────────
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.receiveHistoryPage.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entries.isEmpty
                                ? 'No transfers yet'
                                : '${entries.length} items • ${totalBytes.asReadableFileSize}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: entries.isEmpty
                          ? null
                          : () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (_) => const HistoryClearDialog(),
                              );
                              if (context.mounted && result == true) {
                                await dispatcher.dispatchAsync(RemoveAllHistoryEntriesAction());
                              }
                            },
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      tooltip: t.receiveHistoryPage.deleteHistory,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Inner Action / Stats Pills Row
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: checkPlatform([TargetPlatform.iOS])
                            ? null
                            : () async {
                                final destination = context.read(settingsProvider).destination ?? await getDefaultDestinationDirectory();
                                await openFolder(folderPath: destination);
                              },
                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                        label: Text(
                          t.receiveHistoryPage.openFolder,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── 2. Filter Pills (when entries exist) ────────────────────────────
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All (${entries.length})',
                  filter: _HistoryFilter.all,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Media',
                  filter: _HistoryFilter.media,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Documents',
                  filter: _HistoryFilter.document,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Apps (APK)',
                  filter: _HistoryFilter.apk,
                  colorScheme: colorScheme,
                ),
                if (hasMessages) ...[
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Messages',
                    filter: _HistoryFilter.message,
                    colorScheme: colorScheme,
                  ),
                ],
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Other',
                  filter: _HistoryFilter.other,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // ── 3. Content: Empty State or Bento List ───────────────────────────
        if (entries.isEmpty)
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history_toggle_off_rounded,
                      size: 36,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    t.receiveHistoryPage.empty,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Files you receive will be cataloged here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (filteredEntries.isEmpty)
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Center(
                child: Text(
                  'No items matching this filter',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...filteredEntries.map((entry) {
            final isFile = !entry.isMessage && entry.path != null;
            final fileExists = isFile && File(entry.path!).existsSync();
            final fileMissing = isFile && !fileExists;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: InkWell(
                onTap: () async {
                  if (entry.isMessage) {
                    await _showMessageDialog(context, entry);
                  } else if (fileExists) {
                    await _openFile(context, entry, dispatcher);
                  } else if (fileMissing) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: const Text('File has been moved or deleted from storage'),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Thumbnail Container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: entry.isMessage
                              ? colorScheme.primaryContainer
                              : fileMissing
                                  ? colorScheme.errorContainer.withValues(alpha: 0.5)
                                  : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: entry.isMessage
                            ? Icon(
                                Icons.chat_bubble_rounded,
                                color: colorScheme.onPrimaryContainer,
                                size: 22,
                              )
                            : fileMissing
                                ? Icon(
                                    Icons.broken_image_rounded,
                                    color: colorScheme.error,
                                    size: 22,
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: FilePathThumbnail(
                                      path: entry.path,
                                      fileType: entry.fileType,
                                    ),
                                  ),
                      ),
                      const SizedBox(width: 14),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    entry.isMessage ? 'Message' : entry.fileSize.asReadableFileSize,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.devices_rounded,
                                        size: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        entry.senderAlias,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (fileMissing)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          size: 11,
                                          color: colorScheme.onErrorContainer,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Missing',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onErrorContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Text(
                                  entry.timestampString,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Options Menu
                      PopupMenuButton<_HistoryOption>(
                        icon: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (opt) async {
                          switch (opt) {
                            case _HistoryOption.open:
                              await _openFile(context, entry, dispatcher);
                              break;
                            case _HistoryOption.viewMessage:
                              await _showMessageDialog(context, entry);
                              break;
                            case _HistoryOption.showInFolder:
                              if (entry.path != null) {
                                await openFolder(
                                  folderPath: path.dirname(entry.path!),
                                  fileName: path.basename(entry.path!),
                                );
                              }
                              break;
                            case _HistoryOption.info:
                              await showDialog(
                                context: context,
                                builder: (_) => FileInfoDialog(entry: entry),
                              );
                              break;
                            case _HistoryOption.delete:
                              await dispatcher.dispatchAsync(RemoveHistoryEntryAction(entry.id));
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          if (entry.isMessage)
                            PopupMenuItem(
                              value: _HistoryOption.viewMessage,
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_outlined, size: 18, color: colorScheme.primary),
                                  const SizedBox(width: 10),
                                  const Text('View message'),
                                ],
                              ),
                            )
                          else if (fileExists) ...[
                            PopupMenuItem(
                              value: _HistoryOption.open,
                              child: Row(
                                children: [
                                  Icon(Icons.open_in_new_rounded, size: 18, color: colorScheme.primary),
                                  const SizedBox(width: 10),
                                  Text(t.receiveHistoryPage.entryActions.open),
                                ],
                              ),
                            ),
                            if (!checkPlatform([TargetPlatform.iOS]))
                              PopupMenuItem(
                                value: _HistoryOption.showInFolder,
                                child: Row(
                                  children: [
                                    Icon(Icons.folder_outlined, size: 18, color: colorScheme.onSurface),
                                    const SizedBox(width: 10),
                                    Text(t.receiveHistoryPage.entryActions.showInFolder),
                                  ],
                                ),
                              ),
                          ],
                          PopupMenuItem(
                            value: _HistoryOption.info,
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 18, color: colorScheme.onSurface),
                                const SizedBox(width: 10),
                                Text(t.receiveHistoryPage.entryActions.info),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: _HistoryOption.delete,
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: colorScheme.error),
                                const SizedBox(width: 10),
                                Text(
                                  t.receiveHistoryPage.entryActions.deleteFromHistory,
                                  style: TextStyle(color: colorScheme.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required _HistoryFilter filter,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
