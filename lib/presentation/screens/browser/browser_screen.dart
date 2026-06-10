import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/video_detection/video_detector.dart';
import '../../providers/browser_provider.dart';
import '../../providers/download_provider.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import 'browser_tabs_view.dart';
import 'download_bottom_sheet.dart';
import 'browser_bookmarks_sheet.dart';
import 'browser_history_sheet.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen>
    with SingleTickerProviderStateMixin {
  late WebViewController _webViewController;
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();
  bool _isEditingUrl = false;
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeOutBack,
    );
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          ref.read(browserProvider.notifier).updateUrl(url);
          ref.read(browserProvider.notifier).setLoading(true);
          ref.read(browserProvider.notifier).clearDetectedVideos();
          _fabAnimController.reverse();
          _updateUrlBar(url);
          // Inject network monitor early
          _webViewController.runJavaScript(VideoDetector.networkMonitorScript);
        },
        onPageFinished: (url) {
          ref.read(browserProvider.notifier).setLoading(false);
          ref.read(browserProvider.notifier).updateUrl(url);
          _updateUrlBar(url);
          _updateNavigationState();
          _updatePageTitle();
          _addToHistory(url);
          // Detect videos after page load
          _detectVideos();
        },
        onProgress: (progress) {
          ref.read(browserProvider.notifier).setProgress(progress / 100.0);
        },
        onNavigationRequest: (request) {
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse('https://www.google.com'));
  }

  void _updateUrlBar(String url) {
    if (!_isEditingUrl) {
      _urlController.text = url;
    }
  }

  Future<void> _updateNavigationState() async {
    final canGoBack = await _webViewController.canGoBack();
    final canGoForward = await _webViewController.canGoForward();
    ref.read(browserProvider.notifier).setNavigationState(
          canGoBack: canGoBack,
          canGoForward: canGoForward,
        );
  }

  Future<void> _updatePageTitle() async {
    final title = await _webViewController.getTitle();
    if (title != null && title.isNotEmpty) {
      ref.read(browserProvider.notifier).updateTitle(title);
    }
  }

  void _addToHistory(String url) {
    final state = ref.read(browserProvider);
    final title = state.activeTab?.title ?? url;
    ref.read(browserProvider.notifier).addToHistory(url, title);
  }

  Future<void> _detectVideos() async {
    try {
      // Run detection script
      final result = await _webViewController
          .runJavaScriptReturningResult(VideoDetector.detectionScript);

      String jsonStr = result.toString();
      // Remove quotes if wrapped (Android returns quoted string)
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonStr.substring(1, jsonStr.length - 1);
        jsonStr = jsonStr.replaceAll(r'\"', '"');
      }

      final List<dynamic> videoData = json.decode(jsonStr);

      // Also check network-detected URLs
      final networkResult = await _webViewController
          .runJavaScriptReturningResult(VideoDetector.getDetectedUrlsScript);
      String networkJson = networkResult.toString();
      if (networkJson.startsWith('"') && networkJson.endsWith('"')) {
        networkJson = networkJson.substring(1, networkJson.length - 1);
        networkJson = networkJson.replaceAll(r'\"', '"');
      }
      final List<dynamic> networkUrls = json.decode(networkJson);

      final currentUrl = ref.read(browserProvider).currentUrl;
      final List<DetectedVideo> detected = [];

      for (final video in videoData) {
        detected.add(DetectedVideo(
          url: video['url'] ?? '',
          pageUrl: currentUrl,
          title: video['title'] ?? '',
          duration: (video['duration'] ?? 0).toDouble(),
          width: (video['width'] ?? 0).toInt(),
          height: (video['height'] ?? 0).toInt(),
          isEmbed: video['isEmbed'] ?? false,
        ));
      }

      // Add network-detected video URLs
      for (final url in networkUrls) {
        if (!detected.any((v) => v.url == url)) {
          detected.add(DetectedVideo(
            url: url.toString(),
            pageUrl: currentUrl,
            title: ref.read(browserProvider).activeTab?.title ?? '',
          ));
        }
      }

      // Also check if current page is a known video page
      if (detected.isEmpty && VideoDetector.isVideoPage(currentUrl)) {
        detected.add(DetectedVideo(
          url: currentUrl,
          pageUrl: currentUrl,
          title: ref.read(browserProvider).activeTab?.title ?? '',
          isEmbed: false,
        ));
      }

      if (detected.isNotEmpty) {
        ref.read(browserProvider.notifier).setDetectedVideos(detected);
        _fabAnimController.forward();
      }
    } catch (_) {
      // Silent fail - video detection is best-effort
    }
  }

  void _navigateToUrl(String input) {
    String url = input.trim();
    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Check if it looks like a URL
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        // Search query
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      }
    }

    _webViewController.loadRequest(Uri.parse(url));
    _urlFocusNode.unfocus();
    setState(() => _isEditingUrl = false);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(browserProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Browser toolbar
            _buildToolbar(browserState),
            // Progress indicator
            if (browserState.isLoading)
              LinearProgressIndicator(
                value: browserState.progress > 0 ? browserState.progress : null,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
            // WebView
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController),
                  // Floating download button
                  if (browserState.hasDetectedVideo)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: ScaleTransition(
                        scale: _fabScaleAnimation,
                        child: _buildDownloadFab(browserState),
                      ),
                    ),
                ],
              ),
            ),
            // Banner ad (if not premium)
            if (!isPremium) const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BrowserState browserState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: browserState.canGoBack
                    ? () => _webViewController.goBack()
                    : null,
                tooltip: 'Back',
                visualDensity: VisualDensity.compact,
              ),
              // Forward button
              IconButton(
                icon: const Icon(Icons.arrow_forward, size: 20),
                onPressed: browserState.canGoForward
                    ? () => _webViewController.goForward()
                    : null,
                tooltip: 'Forward',
                visualDensity: VisualDensity.compact,
              ),
              // Refresh / Stop button
              IconButton(
                icon: Icon(
                  browserState.isLoading ? Icons.close : Icons.refresh,
                  size: 20,
                ),
                onPressed: () {
                  if (browserState.isLoading) {
                    // Stop loading - reload acts as stop in webview
                    _webViewController.reload();
                  } else {
                    _webViewController.reload();
                  }
                },
                tooltip: browserState.isLoading ? 'Stop' : 'Refresh',
                visualDensity: VisualDensity.compact,
              ),
              // Home button
              IconButton(
                icon: const Icon(Icons.home_outlined, size: 20),
                onPressed: () {
                  _webViewController.loadRequest(Uri.parse('https://www.google.com'));
                },
                tooltip: 'Home',
                visualDensity: VisualDensity.compact,
              ),
              // URL bar
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextField(
                    controller: _urlController,
                    focusNode: _urlFocusNode,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search or enter URL',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      prefixIcon: Icon(
                        browserState.isLoading
                            ? Icons.public
                            : Icons.lock_outline,
                        size: 16,
                        color: AppColors.success,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                    onTap: () => setState(() => _isEditingUrl = true),
                    onSubmitted: _navigateToUrl,
                    textInputAction: TextInputAction.go,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Tabs button
              GestureDetector(
                onTap: _showTabsView,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${browserState.tabs.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              // Menu button
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'bookmarks',
                    child: ListTile(
                      leading: Icon(Icons.bookmark_outline, size: 20),
                      title: Text('Bookmarks'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'history',
                    child: ListTile(
                      leading: Icon(Icons.history, size: 20),
                      title: Text('History'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_bookmark',
                    child: ListTile(
                      leading: Icon(Icons.bookmark_add_outlined, size: 20),
                      title: Text('Add Bookmark'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'downloads',
                    child: ListTile(
                      leading: Icon(Icons.download_outlined, size: 20),
                      title: Text('Downloads'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined, size: 20),
                      title: Text('Settings'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'bookmarks':
                      _showBookmarks();
                      break;
                    case 'history':
                      _showHistory();
                      break;
                    case 'add_bookmark':
                      _addCurrentPageBookmark();
                      break;
                    case 'downloads':
                      _showDownloads();
                      break;
                    case 'settings':
                      _showSettings();
                      break;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadFab(BrowserState browserState) {
    return FloatingActionButton(
      onPressed: () => _showDownloadSheet(browserState),
      backgroundColor: AppColors.primaryPurple,
      elevation: 8,
      child: const Icon(
        Icons.download_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  void _showDownloadSheet(BrowserState browserState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DownloadBottomSheet(
        detectedVideos: browserState.detectedVideos,
        pageTitle: browserState.activeTab?.title ?? '',
        pageUrl: browserState.currentUrl,
      ),
    );
  }

  void _showTabsView() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BrowserTabsView(
          onTabSelected: (index) {
            ref.read(browserProvider.notifier).switchTab(index);
            final tab = ref.read(browserProvider).tabs[index];
            _webViewController.loadRequest(Uri.parse(tab.url));
            Navigator.of(context).pop();
          },
          onTabClosed: (index) {
            ref.read(browserProvider.notifier).closeTab(index);
          },
          onNewTab: () {
            ref.read(browserProvider.notifier).addTab();
            _webViewController.loadRequest(Uri.parse('https://www.google.com'));
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BrowserBookmarksSheet(
        onBookmarkSelected: (url) {
          _webViewController.loadRequest(Uri.parse(url));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BrowserHistorySheet(
        onHistorySelected: (url) {
          _webViewController.loadRequest(Uri.parse(url));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _addCurrentPageBookmark() {
    final state = ref.read(browserProvider);
    final url = state.currentUrl;
    final title = state.activeTab?.title ?? url;
    ref.read(browserProvider.notifier).addBookmark(url, title);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark added'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showDownloads() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _DownloadsPage(),
      ),
    );
  }

  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _SettingsPage(),
      ),
    );
  }
}

/// Simple downloads page accessible from browser menu
class _DownloadsPage extends ConsumerWidget {
  const _DownloadsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: downloads.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('No downloads yet'));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                leading: Icon(
                  task.isFinished ? Icons.check_circle : Icons.downloading,
                  color: task.isFinished ? AppColors.success : AppColors.downloading,
                ),
                title: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: task.isActive
                    ? LinearProgressIndicator(value: task.progress)
                    : Text(task.status.name),
                trailing: task.isActive
                    ? IconButton(
                        icon: const Icon(Icons.pause),
                        onPressed: () => ref
                            .read(downloadActionsProvider.notifier)
                            .pauseDownload(task.id),
                      )
                    : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Simple settings page accessible from browser menu
class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (value) {
                // Toggle theme handled by existing provider
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('Go Premium'),
            subtitle: const Text('Remove ads, faster downloads'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
