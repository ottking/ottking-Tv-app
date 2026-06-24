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

  // RouteObserver — app.dart এ MaterialApp.navigatorObservers এ পাস করতে হবে
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with RouteAware {
  // KeyboardListener এর FocusNode — autofocus: false রাখতে হবে
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'settings-root');
  // সাইডবারের প্রথম আইটেমে ফোকাস নিয়ে যাওয়ার জন্য
  final FocusNode _firstSidebarNode = FocusNode(debugLabel: 'settings-first-nav');
  _Section _activeSection = _Section.account;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // স্ক্রিন লোড হলে সাইডবারের প্রথম আইটেমে ফোকাস
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _firstSidebarNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RouteAware সাবস্ক্রাইব
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _rootFocusNode.dispose();
    _firstSidebarNode.dispose();
    super.dispose();
  }

  /// Dialog বা sub-screen থেকে ফিরে এলে sidebar focus রিস্টোর
  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _firstSidebarNode.requestFocus();
      }
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      _safelyPop();
    }
  }

  void _safelyPop() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _requestSidebarFocus() {
    if (mounted) {
      _firstSidebarNode.requestFocus();
    }
  }

  void _selectSection(int index) {
    setState(() => _activeSection = _Section.values[index]);
    // Section switch হলে sidebar focus রিস্টোর
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestSidebarFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return PopScope(
      canPop: true,
      child: KeyboardListener(
        focusNode: _rootFocusNode,
        // autofocus: false — সাইডবারের ফোকাস নোডে সঠিকভাবে ফোকাস যাবে
        autofocus: false,
        onKeyEvent: _handleKey,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B0F19),
          body: Row(
            children: [
              // ── Left Sidebar ──────────────────────────────────────────
          
              FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: SettingsNavSidebar(
                  activeSection: _activeSection.index,
                  firstFocusNode: _firstSidebarNode,
                  onSelect: _selectSection,
                  onBack: _safelyPop,
                ),
              ),

              Container(
                width: 1,
                color: Colors.white.withOpacity(0.05),
              ),

              // ── Right Content Area ────────────────────────────────────
              Expanded(
                child: SafeArea(
                  child: FocusTraversalGroup(
                    policy: WidgetOrderTraversalPolicy(),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 32,
                      ),
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
    );
  }

  Widget _buildActiveSection(AppState appState) {
    switch (_activeSection) {
      case _Section.account:
        return SettingsAccountSection(key: const ValueKey('account'), appState: appState);
      case _Section.tvSettings:
        return SettingsTvSection(key: const ValueKey('tv'), appState: appState);
      case _Section.system:
        return SettingsSystemSection(key: const ValueKey('system'), appState: appState);
    }
  }
}
