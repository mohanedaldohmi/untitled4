import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/browser_provider.dart';

/// Bottom sheet displaying bookmarks.
class BrowserBookmarksSheet extends ConsumerWidget {
  const BrowserBookmarksSheet({
    super.key,
    required this.onBookmarkSelected,
  });

  final void Function(String url) onBookmarkSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(browserProvider).bookmarks;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.bookmark, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Bookmarks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${bookmarks.length} items',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Bookmarks list
          if (bookmarks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.bookmark_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No bookmarks yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap the menu to add the current page',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = bookmarks[index];
                  return ListTile(
                    leading: const Icon(Icons.bookmark_outline, size: 20),
                    title: Text(
                      bookmark.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      bookmark.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () {
                        ref.read(browserProvider.notifier).removeBookmark(index);
                      },
                    ),
                    onTap: () => onBookmarkSelected(bookmark.url),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
