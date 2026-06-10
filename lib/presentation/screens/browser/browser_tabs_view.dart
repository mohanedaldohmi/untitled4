import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/browser_provider.dart';

/// Full-screen tabs overview similar to Chrome/Safari tab switcher.
class BrowserTabsView extends ConsumerWidget {
  const BrowserTabsView({
    super.key,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onNewTab,
  });

  final void Function(int index) onTabSelected;
  final void Function(int index) onTabClosed;
  final VoidCallback onNewTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserState = ref.watch(browserProvider);
    final tabs = browserState.tabs;

    return Scaffold(
      appBar: AppBar(
        title: Text('${tabs.length} Tabs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onNewTab,
            tooltip: 'New Tab',
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = index == browserState.activeTabIndex;

          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppColors.primaryPurple : Colors.grey.withOpacity(0.3),
                  width: isActive ? 2 : 1,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primaryPurple.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.public, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tab.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (tabs.length > 1)
                          GestureDetector(
                            onTap: () => onTabClosed(index),
                            child: const Icon(Icons.close, size: 16),
                          ),
                      ],
                    ),
                  ),
                  // Tab preview area
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(11),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.language,
                            size: 32,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _shortenUrl(tab.url),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }
}
