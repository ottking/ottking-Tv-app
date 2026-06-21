import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import 'home_screen_widgets/home_top_bar.dart';
import 'home_screen_widgets/category_sidebar.dart';
import 'home_screen_widgets/channel_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'home-root');
  final FocusNode _settingsFocusNode = FocusNode(debugLabel: 'home-settings');

  int _selectedCategoryIndex = 0;

  final List<FocusNode> _catNodes = [];
  final List<FocusNode> _chNodes = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_catNodes.isNotEmpty && mounted) {
        _catNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _rootFocusNode.dispose();
    _settingsFocusNode.dispose();
    _clearCatNodes();
    _clearChNodes();
    super.dispose();
  }

  void _clearCatNodes() {
    for (final n in _catNodes) n.dispose();
    _catNodes.clear();
  }

  void _clearChNodes() {
    for (final n in _chNodes) n.dispose();
    _chNodes.clear();
  }

  void _updateFocusNodes(
      int targetLength, List<FocusNode> nodeList, String prefix) {
    if (nodeList.length == targetLength) return;
    if (nodeList.length < targetLength) {
      while (nodeList.length < targetLength) {
        nodeList.add(FocusNode(debugLabel: '$prefix-${nodeList.length}'));
      }
    } else {
      while (nodeList.length > targetLength) {
        nodeList.removeLast().dispose();
      }
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      // বাগ ফিক্স: আগে এখানে ব্যাক/এসকেপ চাপলেই সরাসরি পুরো অ্যাপ ক্লোজ হয়ে
      // যেত (SystemNavigator.pop), এমনকি ইউজার যখন চ্যানেল গ্রিড থেকে কেবল
      // ক্যাটাগরি সাইডবারে ফিরে যেতে চাইতো তখনও। এখন আগে চেক করা হচ্ছে বর্তমান
      // ফোকাস চ্যানেল গ্রিডে আছে কিনা — থাকলে শুধু সাইডবারে ফোকাস ফিরিয়ে দেওয়া
      // হবে, অ্যাপ বন্ধ হবে না।
      final current = FocusManager.instance.primaryFocus;
      if (current != null && _chNodes.contains(current)) {
        _moveFocusToSidebar();
        return;
      }
      // অন্য কোথাও (সাইডবার/সেটিংস বাটনে) থাকলেই কেবল এক্সিট কনফার্মেশন দেখানো হবে
      _confirmExit();
    }
  }

  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        title: const Text('Are You Sure?',
            style: TextStyle(color: Colors.white)),
        content: const Text('You went Exit App?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('হ্যাঁ', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  void _changeCategory(int index) {
    if (_selectedCategoryIndex == index) return;
    setState(() {
      _selectedCategoryIndex = index;
      _clearChNodes();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_catNodes.length > index && mounted) {
        _catNodes[index].requestFocus();
      }
    });
  }

  /// সাইডবার থেকে → চাপলে চ্যানেল গ্রিডের প্রথম আইটেমে সরাসরি ফোকাস
  void _moveFocusToGrid() {
    if (_chNodes.isNotEmpty) {
      _chNodes[0].requestFocus();
    }
  }

  /// চ্যানেল গ্রিড থেকে ← চাপলে কারেন্ট ক্যাটাগরিতে ফোকাস
  void _moveFocusToSidebar() {
    if (_catNodes.length > _selectedCategoryIndex) {
      _catNodes[_selectedCategoryIndex].requestFocus();
    }
  }

  /// সেটিংস বাটন থেকে ↓ চাপলে প্রথম ক্যাটাগরিতে ফোকাস
  void _moveFocusFromSettingsToSidebar() {
    if (_catNodes.isNotEmpty) {
      _catNodes[_selectedCategoryIndex].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    final cats = <Map<String, String>>[
      {'name': 'All', 'icon': '🌐'},
      ...appState.categories.map((c) => {'name': c.name, 'icon': c.icon}),
    ];

    _updateFocusNodes(cats.length, _catNodes, 'cat');

    final currentCat = cats[_selectedCategoryIndex]['name']!;
    final filtered = appState.channels.where((ch) {
      if (currentCat == 'All') return true;
      return ch.category.trim().toLowerCase() ==
          currentCat.trim().toLowerCase();
    }).toList();

    _updateFocusNodes(filtered.length, _chNodes, 'chan');

    return KeyboardListener(
      focusNode: _rootFocusNode,
      // autofocus: false — ফোকাস ট্রি সঠিকভাবে ক্যাটাগরি/সেটিংসে যেতে পারবে
      autofocus: false,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar (Settings button) ────────────────────────────
              HomeTopBar(
                appState: appState,
                settingsFocusNode: _settingsFocusNode,
                // ↓ চাপলে সাইডবারে ফোকাস
                onSettingsDown: _moveFocusFromSettingsToSidebar,
              ),

              Expanded(
                child: appState.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 3,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Category Sidebar ─────────────────────
                            SizedBox(
                              width: size.width * 0.18,
                              child: Focus(
                                skipTraversal: true,
                                onKeyEvent: (node, event) {
                                  if (event is! KeyDownEvent) {
                                    return KeyEventResult.ignored;
                                  }
                                  // ↑ চাপলে সেটিংস বাটনে
                                  if (event.logicalKey ==
                                          LogicalKeyboardKey.arrowUp &&
                                      _selectedCategoryIndex == 0) {
                                    _settingsFocusNode.requestFocus();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: CategorySidebar(
                                  cats: cats,
                                  catNodes: _catNodes,
                                  selectedIndex: _selectedCategoryIndex,
                                  onSelect: _changeCategory,
                                  // → চাপলে গ্রিডে যাবে (সরাসরি FocusNode)
                                  onMoveRight: _moveFocusToGrid,
                                ),
                              ),
                            ),

                            const SizedBox(width: 20),

                            // ── Channel Grid ────────────────────────
                            Expanded(
                              child: FocusTraversalGroup(
                                policy: WidgetOrderTraversalPolicy(),
                                child: Focus(
                                  skipTraversal: true,
                                  onKeyEvent: (node, event) {
                                    if (event is! KeyDownEvent) {
                                      return KeyEventResult.ignored;
                                    }
                                    // ← চাপলে সাইডবারে ফোকাস ফেরত
                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowLeft) {
                                      _moveFocusToSidebar();
                                      return KeyEventResult.handled;
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: ChannelGrid(
                                    channels: filtered,
                                    chNodes: _chNodes,
                                    appState: appState,
                                    categoryName: currentCat,
                                  ),
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
      ),
    );
  }
}
