import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:linko_app/core/navigation/router.dart';
import 'package:linko_app/gen/strings.g.dart';
import 'package:linko_app/provider/selection/selected_sending_files_provider.dart';
import 'package:linko_app/util/native/open_file.dart';
import 'package:linko_app/util/ui/nav_bar_padding.dart';
import 'package:linko_app/widget/dialogs/message_input_dialog.dart';
import 'package:linko_app/widget/file_thumbnail.dart';
import 'package:linko_app/widget/responsive_list_view.dart';
import 'package:linko_isolates/model/file_type.dart';
import 'package:linko_isolates/util/file_size_helper.dart';
import 'package:refena_flutter/refena_flutter.dart';

class SelectedFilesPage extends StatelessWidget {
  const SelectedFilesPage();

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final selectedFiles = ref.watch(selectedSendingFilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.sendTab.selection.title),
      ),
      body: ResponsiveListView.single(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        tabletPadding: const EdgeInsets.symmetric(horizontal: 15),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SizedBox(height: 15),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.folder_zip_rounded,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.sendTab.selection.files(files: selectedFiles.length),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.sendTab.selection.size(size: selectedFiles.fold(0, (prev, curr) => prev + curr.size).asReadableFileSize),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        ref.redux(selectedSendingFilesProvider).dispatch(ClearSelectionAction());
                        context.popUntilRoot();
                      },
                      child: Text(t.selectedFilesPage.deleteAll),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 14),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: selectedFiles.length,
                (context, index) {
                  final file = selectedFiles[index];

                  final String? message;
                  if (file.fileType == FileType.text && file.bytes != null) {
                    message = utf8.decode(file.bytes!);
                  } else {
                    message = null;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: file.path != null ? () async => openFile(context, file.fileType, file.path!) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            SmartFileThumbnail.fromCrossFile(file),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message != null ? '"${message.replaceAll('\n', ' ')}"' : file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    file.size.asReadableFileSize,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (file.fileType == FileType.text && file.bytes != null)
                              IconButton(
                                style: IconButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () async {
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder: (_) => MessageInputDialog(initialText: message),
                                  );
                                  if (result != null) {
                                    ref.redux(selectedSendingFilesProvider).dispatch(UpdateMessageAction(message: result, index: index));
                                  }
                                },
                                icon: const Icon(Icons.edit_outlined, size: 20),
                              ),
                            IconButton(
                              style: IconButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () {
                                final currCount = ref.read(selectedSendingFilesProvider).length;
                                ref.redux(selectedSendingFilesProvider).dispatch(RemoveSelectedFileAction(index));
                                if (currCount == 1) {
                                  context.popUntilRoot();
                                }
                              },
                              icon: const Icon(Icons.delete_outline, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 15 + getNavBarPadding(context)),
            ),
          ],
        ),
      ),
    );
  }
}
