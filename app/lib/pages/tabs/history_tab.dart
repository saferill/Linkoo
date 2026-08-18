import 'dart:io';

import 'package:flutter/material.dart';
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
import 'package:linko_isolates/util/file_size_helper.dart';
import 'package:path/path.dart' as path;
import 'package:refena_flutter/refena_flutter.dart';

enum _HistoryOption {
  open,
  showInFolder,
  info,
  delete,
}

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = context.watch(receiveHistoryProvider);
    final dispatcher = context.redux(receiveHistoryProvider);

    return ResponsiveListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Top Action Bar
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
                icon: const Icon(Icons.folder_open_rounded, size: 20),
                label: const Text('Open Folder'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
              tooltip: 'Clear History',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (entries.isEmpty)
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
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 48,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transfer history yet',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Files sent and received will appear here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...entries.map((entry) {
            final fileExists = entry.path != null && File(entry.path!).existsSync();
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FilePathThumbnail(
                    path: entry.path,
                    fileType: entry.fileType,
                  ),
                ),
                title: Text(
                  entry.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        entry.fileSize.asReadableFileSize,
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                      Text('•', style: TextStyle(fontSize: 12, color: colorScheme.outlineVariant)),
                      Text(
                        entry.senderAlias,
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                      Text('•', style: TextStyle(fontSize: 12, color: colorScheme.outlineVariant)),
                      Text(
                        entry.timestampString,
                        style: TextStyle(fontSize: 12, color: colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                trailing: PopupMenuButton<_HistoryOption>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (opt) async {
                    switch (opt) {
                      case _HistoryOption.open:
                        await _openFile(context, entry, dispatcher);
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
                    if (fileExists) ...[
                      const PopupMenuItem(
                        value: _HistoryOption.open,
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Open'),
                          ],
                        ),
                      ),
                      if (!checkPlatform([TargetPlatform.iOS]))
                        const PopupMenuItem(
                          value: _HistoryOption.showInFolder,
                          child: Row(
                            children: [
                              Icon(Icons.folder_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Show in folder'),
                            ],
                          ),
                        ),
                    ],
                    const PopupMenuItem(
                      value: _HistoryOption.info,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: _HistoryOption.delete,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete from history', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: fileExists ? () => _openFile(context, entry, dispatcher) : null,
              ),
            );
          }),
      ],
    );
  }
}
