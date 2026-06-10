import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a single browser tab.
class BrowserTab {
  BrowserTab({
    required this.id,
    this.url = 'https://www.google.com',
    this.title = 'New Tab',
    this.isLoading = false,
  });

  final String id;
  String url;
  String title;
  bool isLoading;

  BrowserTab copyWith({
    String? url,
    String? title,
    bool? isLoading,
  }) {
    return BrowserTab(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Represents a bookmark entry.
class BookmarkEntry {
  const BookmarkEntry({
    required this.url,
    required this.title,
    required this.addedAt,
  });

  final String url;
  final String title;
  final DateTime addedAt;
}

/// Represents a browser history entry.
class BrowserHistoryEntry {
  const BrowserHistoryEntry({
    required this.url,
    required this.title,
    required this.visitedAt,
  });

  final String url;
  final String title;
  final DateTime visitedAt;
}

/// Detected video information from the current page.
class DetectedVideo {
  const DetectedVideo({
    required this.url,
    required this.pageUrl,
    this.title = '',
    this.duration = 0,
    this.width = 0,
    this.height = 0,
    this.isEmbed = false,
  });

  final String url;
  final String pageUrl;
  final String title;
  final double duration;
  final int width;
  final int height;
  final bool isEmbed;
}

/// State for the browser.
class BrowserState {
  const BrowserState({
    this.tabs = const [],
    this.activeTabIndex = 0,
    this.bookmarks = const [],
    this.history = const [],
    this.detectedVideos = const [],
    this.canGoBack = false,
    this.canGoForward = false,
    this.isLoading = false,
    this.currentUrl = 'https://www.google.com',
    this.progress = 0.0,
  });

  final List<BrowserTab> tabs;
  final int activeTabIndex;
  final List<BookmarkEntry> bookmarks;
  final List<BrowserHistoryEntry> history;
  final List<DetectedVideo> detectedVideos;
  final bool canGoBack;
  final bool canGoForward;
  final bool isLoading;
  final String currentUrl;
  final double progress;

  BrowserTab? get activeTab =>
      tabs.isNotEmpty && activeTabIndex < tabs.length ? tabs[activeTabIndex] : null;

  bool get hasDetectedVideo => detectedVideos.isNotEmpty;

  BrowserState copyWith({
    List<BrowserTab>? tabs,
    int? activeTabIndex,
    List<BookmarkEntry>? bookmarks,
    List<BrowserHistoryEntry>? history,
    List<DetectedVideo>? detectedVideos,
    bool? canGoBack,
    bool? canGoForward,
    bool? isLoading,
    String? currentUrl,
    double? progress,
  }) {
    return BrowserState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      bookmarks: bookmarks ?? this.bookmarks,
      history: history ?? this.history,
      detectedVideos: detectedVideos ?? this.detectedVideos,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      isLoading: isLoading ?? this.isLoading,
      currentUrl: currentUrl ?? this.currentUrl,
      progress: progress ?? this.progress,
    );
  }
}

/// Manages the browser state including tabs, bookmarks, history, and video detection.
class BrowserNotifier extends StateNotifier<BrowserState> {
  BrowserNotifier()
      : super(BrowserState(
          tabs: [
            BrowserTab(id: '1', url: 'https://www.google.com', title: 'Google'),
          ],
        ));

  int _tabCounter = 1;

  // ── Tab management ─────────────────────────────────────────────────────────

  void addTab({String url = 'https://www.google.com'}) {
    _tabCounter++;
    final newTab = BrowserTab(id: '$_tabCounter', url: url, title: 'New Tab');
    final tabs = [...state.tabs, newTab];
    state = state.copyWith(
      tabs: tabs,
      activeTabIndex: tabs.length - 1,
      currentUrl: url,
      detectedVideos: [],
    );
  }

  void closeTab(int index) {
    if (state.tabs.length <= 1) return; // Keep at least one tab
    final tabs = [...state.tabs]..removeAt(index);
    int newIndex = state.activeTabIndex;
    if (newIndex >= tabs.length) newIndex = tabs.length - 1;
    state = state.copyWith(
      tabs: tabs,
      activeTabIndex: newIndex,
      currentUrl: tabs[newIndex].url,
      detectedVideos: [],
    );
  }

  void switchTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    state = state.copyWith(
      activeTabIndex: index,
      currentUrl: state.tabs[index].url,
      detectedVideos: [],
    );
  }

  // ── Navigation state ───────────────────────────────────────────────────────

  void updateUrl(String url) {
    final tabs = [...state.tabs];
    if (state.activeTabIndex < tabs.length) {
      tabs[state.activeTabIndex] = tabs[state.activeTabIndex].copyWith(url: url);
    }
    state = state.copyWith(tabs: tabs, currentUrl: url);
  }

  void updateTitle(String title) {
    final tabs = [...state.tabs];
    if (state.activeTabIndex < tabs.length) {
      tabs[state.activeTabIndex] = tabs[state.activeTabIndex].copyWith(title: title);
    }
    state = state.copyWith(tabs: tabs);
  }

  void setLoading(bool loading) {
    final tabs = [...state.tabs];
    if (state.activeTabIndex < tabs.length) {
      tabs[state.activeTabIndex] = tabs[state.activeTabIndex].copyWith(isLoading: loading);
    }
    state = state.copyWith(tabs: tabs, isLoading: loading);
  }

  void setProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void setNavigationState({bool? canGoBack, bool? canGoForward}) {
    state = state.copyWith(canGoBack: canGoBack, canGoForward: canGoForward);
  }

  // ── Video detection ────────────────────────────────────────────────────────

  void setDetectedVideos(List<DetectedVideo> videos) {
    state = state.copyWith(detectedVideos: videos);
  }

  void clearDetectedVideos() {
    state = state.copyWith(detectedVideos: []);
  }

  // ── Bookmarks ──────────────────────────────────────────────────────────────

  void addBookmark(String url, String title) {
    final entry = BookmarkEntry(
      url: url,
      title: title,
      addedAt: DateTime.now(),
    );
    state = state.copyWith(bookmarks: [...state.bookmarks, entry]);
  }

  void removeBookmark(int index) {
    final bookmarks = [...state.bookmarks]..removeAt(index);
    state = state.copyWith(bookmarks: bookmarks);
  }

  bool isBookmarked(String url) {
    return state.bookmarks.any((b) => b.url == url);
  }

  // ── History ────────────────────────────────────────────────────────────────

  void addToHistory(String url, String title) {
    final entry = BrowserHistoryEntry(
      url: url,
      title: title,
      visitedAt: DateTime.now(),
    );
    // Keep last 500 entries
    final history = [entry, ...state.history];
    if (history.length > 500) {
      state = state.copyWith(history: history.sublist(0, 500));
    } else {
      state = state.copyWith(history: history);
    }
  }

  void clearHistory() {
    state = state.copyWith(history: []);
  }

  void removeHistoryEntry(int index) {
    final history = [...state.history]..removeAt(index);
    state = state.copyWith(history: history);
  }
}

final browserProvider = StateNotifierProvider<BrowserNotifier, BrowserState>(
  (ref) => BrowserNotifier(),
);
