// lib/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import 'settings_screen_widgets/settings_nav_sidebar.dart';
import 'settings_screen_widgets/settings_account_section.dart';
import 'settings_screen_widgets/settings_tv_section.dart';
import 'settings_screen_widgets/settings_system_section.dart';
import 'settings_screen_widgets/settings_status_footer.dart';

enum _Section { account, tvSettings, system }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Sidebar nav item nodes (active section এর node এ wrap করা যাবে)
  final List<FocusNode> _sidebarNodes = [
    FocusNode(debugLabel: 'settings-nav-0'),
    FocusNode(debugLabel: 'settings-nav-1'),
    FocusNode(debugLabel: 'settings-nav-2'),
  ];

  // Content area: প্রথম ও শেষ focusable item এর node
  final FocusNode _contentFirstNode = FocusNode(debugLabel: 'settings-content-first');
  final FocusNode _contentLastNode  = FocusNode(debugLabel: 'settings-content-last');

  _Section _activeSection = _Section.account;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sidebarNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final n in _sidebarNodes) {
      n.dispose();
    }
    _contentFirstNode.dispose();
    _contentLastNode.dispose();
    super.dispose();
  }

  void _safelyPop() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // Sidebar এর active section node এ ফোকাস
  void _requestActiveSidebarFocus() {
    final node = _sidebarNodes[_activeSection.index];
    if (mounted && !node.disposed) node.requestFocus();
  }

  // Content এর প্রথম item এ ফোকাস (postFrame দরকার AnimatedSwitcher rebuild এর জন্য)
  void _requestContentFirstFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_contentFirstNode.disposed) _contentFirstNode.requestFocus();
    });
  }

  void _selectSection(int index) {
    setState(() => _activeSection = _Section.values[index]);
    // Section বদলালে sidebar এ ফোকাস থাকে
    _requestActiveSidebarFocus();
  }

  // Sidebar → Right → content এর first item
  void _onSidebarNavigateRight() => _requestContentFirstFocus();

  // Content → Left → sidebar
  void _onContentNavigateLeft() => _requestActiveSidebarFocus();

  // Content এর last item → Down → sidebar এর active item (wrap)
  void _onContentLastItemDown() => _requestActiveSidebarFocus();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return PopScope(
      canPop: true,
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.escape): const _PopIntent(),
          LogicalKeySet(LogicalKeyboardKey.goBack): const _PopIntent(),
        },
        child: Actions(
          actions: {
            _PopIntent: CallbackAction<_PopIntent>(onInvoke: (_) => _safelyPop()),
          },
          child: Focus(
            autofocus: false,
            child: Scaffold(
              backgroundColor: const Color(0xFF0B0F19),
              body: Row(
                children: [
                  // ── Left Sidebar ──────────────────────────────────────
                  FocusTraversalGroup(
                    policy: _VerticalTraversalPolicy(),
                    child: SettingsNavSidebar(
                      activeSection: _activeSection.index,
                      sidebarNodes: _sidebarNodes,       // ← সব sidebar node pass
                      onSelect: _selectSection,
                      onBack: _safelyPop,
                      onNavigateRight: _onSidebarNavigateRight,
                    ),
                  ),

                  Container(width: 1, color: Colors.white.withOpacity(0.05)),

                  // ── Right Content Area ────────────────────────────────
                  Expanded(
                    child: SafeArea(
                      child: FocusTraversalGroup(
                        policy: WidgetOrderTraversalPolicy(),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _buildActiveSection(appState),
                              ),
                              const SizedBox(height: 40),
                              Divider(color: Colors.white.withOpacity(0.05)),
                              const SizedBox(height: 16),
                              SettingsStatusFooter(appState: appState),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSection(AppState appState) {
    switch (_activeSection) {
      case _Section.account:
        return SettingsAccountSection(
          key: const ValueKey('account'),
          appState: appState,
          firstFocusNode: _contentFirstNode,
          lastFocusNode: _contentLastNode,
          onNavigateLeft: _onContentNavigateLeft,
          onLastItemDown: _onContentLastItemDown,
        );
      case _Section.tvSettings:
        // TV section এ ১টি মাত্র card — first == last
        return SettingsTvSection(
          key: const ValueKey('tv'),
          appState: appState,
          firstFocusNode: _contentFirstNode,
          lastFocusNode: _contentFirstNode, // same node
          onNavigateLeft: _onContentNavigateLeft,
          onLastItemDown: _onContentLastItemDown,
        );
      case _Section.system:
        return SettingsSystemSection(
          key: const ValueKey('system'),
          appState: appState,
          firstFocusNode: _contentFirstNode,
          lastFocusNode: _contentLastNode,
          onNavigateLeft: _onContentNavigateLeft,
          onLastItemDown: _onContentLastItemDown,
        );
    }
  }
}

class _PopIntent extends Intent {
  const _PopIntent();
}

// Sidebar এর জন্য vertical-only traversal policy
class _VerticalTraversalPolicy extends FocusTraversalPolicy {
  @override
  bool next(FocusNode node) => _move(node, forward: true);

  @override
  bool previous(FocusNode node) => _move(node, forward: false);

  bool _move(FocusNode node, {required bool forward}) {
    final scope = node.enclosingScope;
    if (scope == null) return false;
    final sorted = _sortedNodes(scope);
    final idx = sorted.indexOf(node);
    if (idx == -1) return false;
    final next = idx + (forward ? 1 : -1);
    if (next < 0 || next >= sorted.length) return false;
    sorted[next].requestFocus();
    return true;
  }

  List<FocusNode> _sortedNodes(FocusScopeNode scope) {
    final nodes = scope.traversalDescendants.toList();
    nodes.sort((a, b) {
      final aBox = a.context?.findRenderObject() as RenderBox?;
      final bBox = b.context?.findRenderObject() as RenderBox?;
      if (aBox == null || bBox == null) return 0;
      return aBox.localToGlobal(Offset.zero).dy
          .compareTo(bBox.localToGlobal(Offset.zero).dy);
    });
    return nodes;
  }

  @override
  FocusNode? findFirstFocus(FocusNode currentNode,
      {bool ignoreCurrentFocus = false}) {
    final nodes = _sortedNodes(currentNode.enclosingScope!);
    return nodes.isEmpty ? null : nodes.first;
  }

  @override
  FocusNode? findLastFocus(FocusNode currentNode,
      {bool ignoreCurrentFocus = false}) {
    final nodes = _sortedNodes(currentNode.enclosingScope!);
    return nodes.isEmpty ? null : nodes.last;
  }

  @override
  FocusNode? findFirstFocusInDirection(
          FocusNode currentNode, TraversalDirection direction) =>
      null;

  @override
  Iterable<FocusNode> sortDescendants(
          Iterable<FocusNode> descendants, FocusNode currentNode) =>
      descendants;
}
