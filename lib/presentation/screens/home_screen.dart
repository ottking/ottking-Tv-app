import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/tv_focus_utils.dart';
import 'home_screen_widgets/home_top_bar.dart';
import 'home_screen_widgets/category_sidebar.dart';
import 'home_screen_widgets/channel_grid.dart';
import 'player_widgets/app_exit_settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // RouteObserver — app.dart এ MaterialApp.navigatorObservers এ পাস করতে হবে
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final FocusNode _settingsFocusNode = FocusNode(debugLabel: 'home-settings');

  int _selectedCategoryIndex = 0;
  int _lastFocusedGridIndex = 0;

  final List<FocusNode> _catNodes = [];
  final List<FocusNode> _chNodes = [];

  /// Settings/Player থেকে ফিরে আসার পর একই Back press Home exit ধরবে না।
  DateTime? _suppressExitUntil;

  bool get _canShowExitPopup {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return false;
    if (_suppressExitUntil != null &&
        DateTime.now().isBefore(_suppressExitUntil!)) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _suppressExitUntil = DateTime.now().add(const Duration(milliseconds: 400));
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RouteAware সাবস্ক্রাইব — routeObserver অ্যাপের MaterialApp.navigatorObservers এ থাকতে হবে
    HomeScreen.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    HomeScreen.routeObserver.unsubscribe(this);
    _settingsFocusNode.dispose();
    _clearCatNodes();
    _clearChNodes();
    super.dispose();
  }

  /// Settings/Player থেকে ফিরে এলে focus restore + exit suppress
  @override
  void didPopNext() {
    _suppressExitUntil = DateTime.now().add(const Duration(milliseconds: 600));
    restoreFocusAfterFrame(_settingsFocusNode, ifMounted: () => mounted);
  }

  Future<void> _handleHomeBack() async {
    if (!_canShowExitPopup) return;
    await AppExitHandler.handleHomeExit(context);
  }

  void _clearCatNodes() {
    for (final n in _catNodes) {
      n.dispose();
    }
    _catNodes.clear();
  }

  void _clearChNodes() {
    for (final n in _chNodes) {
      n.dispose();
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

  void _requestCategoryFocus(int index) {
    if (_catNodes.length > index && mounted) {
      _catNodes[index].requestFocus();
    }
  }

  void _requestGridFocus(int index) {
    if (_chNodes.isEmpty) return;
    final safeIndex = index.clamp(0, _chNodes.length - 1);
    if (mounted) {
      _chNodes[safeIndex].requestFocus();
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

  void _moveFocusToGrid() {
    _requestGridFocus(_lastFocusedGridIndex.clamp(0, _chNodes.length - 1));
  }

  /// চ্যানেল গ্রিড থেকে ← চাপলে কারেন্ট ক্যাটাগরিতে ফোকাস
  void _moveFocusToSidebar() {
    _requestCategoryFocus(_selectedCategoryIndex);
  }

  /// সেটিংস বাটন থেকে ↓ চাপলে প্রথম ক্যাটাগরিতে ফোকাস
  void _moveFocusFromSettingsToSidebar() {
    _requestCategoryFocus(_selectedCategoryIndex);
  }

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_canShowExitPopup) return;
        await _handleHomeBack();
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              HomeTopBar(
                appState: appState,
                settingsFocusNode: _settingsFocusNode,
                onSettingsDown: _moveFocusFromSettingsToSidebar,
                onBack: _handleHomeBack,
              ),
              Expanded(
                child: appState.isLoading
                    ? const Center(
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
                            SizedBox(
                              width: size.width * 0.18,
                              child: Focus(
                                skipTraversal: true,
                                onKeyEvent: (node, event) {
                                  if (event is! KeyDownEvent) {
                                    return KeyEventResult.ignored;
                                  }
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
                                  onMoveRight: _moveFocusToGrid,
                                  onBack: _handleHomeBack,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: FocusTraversalGroup(
                                policy: WidgetOrderTraversalPolicy(),
                                child: Focus(
                                  skipTraversal: true,
                                  onKeyEvent: (node, event) {
                                    if (event is! KeyDownEvent) {
                                      return KeyEventResult.ignored;
                                    }
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
                                    onBack: _handleHomeBack,
                                    onFocusIndex: (i) =>
                                        _lastFocusedGridIndex = i,
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
