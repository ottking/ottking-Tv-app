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
    if (!_rootFocusNode.disposed) _rootFocusNode.dispose();
    if (!_settingsFocusNode.disposed) _settingsFocusNode.dispose();
    _clearCatNodes();
    _clearChNodes();
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Restore focus to settings button when returning from player/settings
    if (mounted && !_settingsFocusNode.disposed) {
      _settingsFocusNode.requestFocus();
    }
  }

  void _clearCatNodes() {
    for (final n in _catNodes) {
      if (!n.disposed) n.dispose();
    }
    _catNodes.clear();
  }

  void _clearChNodes() {
    for (final n in _chNodes) {
      if (!n.disposed) n.dispose();
    }
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
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  void _requestSettingsFocus() {
    if (mounted && !_settingsFocusNode.disposed) {
      _settingsFocusNode.requestFocus();
    }
  }

  void _requestCategoryFocus(int index) {
    if (_catNodes.length > index && mounted && !_catNodes[index].disposed) {
      _catNodes[index].requestFocus();
    }
  }

  void _requestGridFocus(int index) {
    if (_chNodes.length > index && mounted && !_chNodes[index].disposed) {
      _chNodes[index].requestFocus();
    }
  }

  void _changeCategory(int index) {
    if (_selectedCategoryIndex == index) return;
    setState(() {
      _selectedCategoryIndex = index;
      _clearChNodes();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestCategoryFocus(index);
    });
  }

  void _requestCategoryFocus(int index) {
    if (_catNodes.length > index && mounted && !_catNodes[index].disposed) {
      _catNodes[index].requestFocus();
    }
  }

  void _moveFocusToGrid() {
    _requestGridFocus(0);
  }

  /// চ্যানেল গ্রিড থেকে ← চাপলে কারেন্ট ক্যাটাগরিতে ফোকাস
  void _moveFocusToSidebar() {
    _requestCategoryFocus(_selectedCategoryIndex);
  }

  /// সেটিংস বাটন থেকে ↓ চাপলে প্রথম ক্যাটাগরিতে ফোকাস
  void _moveFocusFromSettingsToSidebar() {
    _requestCategoryFocus(_selectedCategoryIndex);
  }

  void _oldMoveFocusToGrid() {

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    final cats = <Map<String, String>>[
      {'name': 'All', 'icon': ''},
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
