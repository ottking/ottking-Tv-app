import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart' as native_vp;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import 'player_widgets/player_top_panel.dart';
import 'player_widgets/channel_list_panel.dart';
import 'player_widgets/loading_overlay.dart';
import 'player_widgets/app_info_dialog.dart';
import 'player_widgets/app_exit_settings.dart';

class _SecurePlayerHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => "DIRECT"; 
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => false; 
    return client;
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  final FocusNode _focus = FocusNode(debugLabel: 'player-root');

  native_vp.VideoPlayerController? _nativeCtrl;
  VoidCallback? _nativeCtrlListener;

  String? _activeChannelId;

  bool _showControls = true;
  bool _isLoading = false;
  bool _hasStreamError = false;
  bool _showChannelList = false;
  bool _liveBlink = true;

  AppState? _appState;

  Timer? _controlsTimer;
  Timer? _numberTimer;
  Timer? _retryTimer;
  Timer? _blinkTimer;

  String _typed = '';
  int _retryCount = 0;
  static const int _maxRetry = 3;

  int _currentInitTimestamp = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _wakelock();
      if (_nativeCtrl?.value.hasError == true) {
        _retryCount = 0;
        _initController();
      }
    } else if (state == AppLifecycleState.paused) {
      _nativeCtrl?.pause();
    }
  }

  @override
  void initState() {
    super.initState();
    HttpOverrides.global = _SecurePlayerHttpOverrides();
    WidgetsBinding.instance.addObserver(this);
    _forceFullLandscape();
    _wakelock();
    _startBlinkTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _appState = Provider.of<AppState>(context, listen: false);
        _initController();
        _startControlsTimer();
        _focus.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextState = context.watch<AppState>();
    if (_appState != null && _activeChannelId != null) {
      final nextChannelId = nextState.channels.isNotEmpty 
          ? nextState.channels[nextState.currentChannelIndex].id 
          : null;
      if (nextChannelId == _activeChannelId) {
        _appState = nextState;
        return; 
      }
    }
    _appState = nextState;
  }

  void _forceFullLandscape() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _wakelock() async {
    try { await WakelockPlus.enable(); } catch (_) {}
  }

  void _startBlinkTimer() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (mounted) setState(() => _liveBlink = !_liveBlink);
    });
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _showControls && _typed.isEmpty && !_showChannelList) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_showChannelList) return; 
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  void _disposeControllers() {
    if (_nativeCtrl != null) {
      final oldCtrl = _nativeCtrl!;
      _nativeCtrl = null;
      if (_nativeCtrlListener != null) {
        oldCtrl.removeListener(_nativeCtrlListener!);
        _nativeCtrlListener = null;
      }
      try {
        unawaited(oldCtrl.setVolume(0));
        if (oldCtrl.value.isPlaying) {
          unawaited(oldCtrl.pause());
        }
      } catch (_) {}
      unawaited(oldCtrl.dispose());
    }
  }

  void _prepareForExitRelease() {
    _controlsTimer?.cancel();
    _numberTimer?.cancel();
    _retryTimer?.cancel();
    _blinkTimer?.cancel();
    _disposeControllers();
  }

  Future<void> _initController() async {
    if (!mounted || _appState == null) return;
    final channel = _appState!.currentChannel;
    final int thisInitTimestamp = DateTime.now().millisecondsSinceEpoch;
    _currentInitTimestamp = thisInitTimestamp;

    setState(() {
      _isLoading = true;
      _hasStreamError = false;
      _activeChannelId = channel.id;
    });

    _disposeControllers();

    final activeController = _nativeCtrl;
    if (activeController != null && activeController.value.isPlaying) {
      unawaited(activeController.pause());
    }

    final newCtrl = native_vp.VideoPlayerController.networkUrl(
      Uri.parse(channel.streamUrl),
      videoPlayerOptions: native_vp.VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: false,
      ),
      httpHeaders: {
        'User-Agent': 'oTtking-AndroidTV-Secure-Agent',
        'X-App-Token': 'backend_generated_secret_handshake_token',
        'Origin': 'https://ottking.internal',
        'Accept': '*/*',
      },
    );

    try {
      await newCtrl.initialize().timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw TimeoutException('timeout'),
          );

      if (_currentInitTimestamp != thisInitTimestamp || !mounted) {
        unawaited(newCtrl.dispose());
        return;
      }

      await newCtrl.play();
      _wakelock();

      final previousCtrl = _nativeCtrl;
      if (previousCtrl != null && previousCtrl != newCtrl) {
        if (previousCtrl.value.isPlaying) {
          unawaited(previousCtrl.pause());
        }
        unawaited(previousCtrl.dispose());
      }

      _nativeCtrlListener = _onNativeCtrlUpdate;
      _nativeCtrl = newCtrl;
      newCtrl.addListener(_nativeCtrlListener!);
      _retryCount = 0;

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasStreamError = false;
        });
      }
    } catch (e) {
      if (_currentInitTimestamp == thisInitTimestamp && mounted) {
        newCtrl.dispose();
        _handleLoadError();
      } else {
        newCtrl.dispose();
      }
    }
  }

  void _onNativeCtrlUpdate() {
    if (!mounted) return;
    if (_nativeCtrl?.value.hasError == true) {
      _scheduleRetry();
      return;
    }
    if (_nativeCtrl != null && _nativeCtrl!.value.isInitialized) {
      if (!_nativeCtrl!.value.isBuffering && !_nativeCtrl!.value.isPlaying && !_hasStreamError && !_isLoading) {
        _nativeCtrl!.play();
      }
    }
    setState(() {});
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_retryCount >= _maxRetry) {
      if (mounted) setState(() { _isLoading = false; _hasStreamError = true; });
      return;
    }
    _retryCount++;
    if (mounted) setState(() => _isLoading = true);
    _retryTimer = Timer(Duration(seconds: _retryCount * 2), () {
      if (mounted) {
        setState(() => _activeChannelId = null);
        _initController();
      }
    });
  }

  void _handleLoadError() {
    if (!mounted) return;
    if (_retryCount < _maxRetry) {
      _scheduleRetry();
    } else {
      setState(() { _isLoading = false; _hasStreamError = true; });
    }
  }

  void _switchChannel(int direction) async {
    if (_appState == null) return;
    _retryTimer?.cancel();
    _retryCount = 0;
    _currentInitTimestamp = DateTime.now().millisecondsSinceEpoch;
    _disposeControllers();

    setState(() {
      _showControls = true;
      _isLoading = true;
      _hasStreamError = false;
      _activeChannelId = null;
    });
    _startControlsTimer();
    _appState!.switchChannel(direction);
    if (mounted) _initController();
  }

  void _switchToIndex(int index) async {
    if (_appState == null) return;
    final allCh = _appState!.channels;
    if (index < 0 || index >= allCh.length) {
      _showSnack('$index No channel is available on this number.');
      return;
    }
    _retryTimer?.cancel();
    _retryCount = 0;
    _currentInitTimestamp = DateTime.now().millisecondsSinceEpoch;
    _disposeControllers();

    setState(() {
      _showControls = true;
      _isLoading = true;
      _hasStreamError = false;
      _activeChannelId = null;
    });
    _appState!.selectChannelByIndex(index);
    if (mounted) _initController();
  }

  void _handleNumberInput(String digit) {
    _numberTimer?.cancel();
    setState(() { _showControls = true; _typed += digit; });
    _numberTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _typed.isNotEmpty) {
        final n = int.tryParse(_typed);
        if (n != null) _switchToIndex(n - 1);
        setState(() => _typed = '');
        _startControlsTimer();
      }
    });
  }

  void _openSettings() {
    _controlsTimer?.cancel();
    showDialog(
      context: context,
      builder: (_) => Consumer<AppState>(
        builder: (ctx, state, __) => PlayerSettingsDialog(
          state: state,
          onAppInfo: () { Navigator.pop(context); _showAppInfo(); },
          onNavigateSettings: () { Navigator.pop(context); Navigator.pushNamed(context, '/settings'); },
          onClose: () => Navigator.pop(context),
        ),
      ),
    ).then((_) {
      _focus.requestFocus(); 
      _startControlsTimer();
    });
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (_) => const AppInfoDialog(),
    ).then((_) { _focus.requestFocus(); _startControlsTimer(); });
  }

  Future<void> _invokeExitWidget() async {
    if (_appState == null) return;
    await AppExitHandler.handleExit(
      context: context,
      appState: _appState!,
      onBeforeDispose: _prepareForExitRelease,
    );
  }

  void _togglePlayPause() {
    if (_isLoading || _hasStreamError) return;
    final c = _nativeCtrl;
    if (c == null || !c.value.isInitialized) return;
    setState(() { c.value.isPlaying ? c.pause() : c.play(); });
    _wakelock();
    _startControlsTimer();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2), backgroundColor: AppTheme.card));
  }

  void _handleKey(KeyEvent event) {
    final label = event.logicalKey.keyLabel;

    if (event is KeyDownEvent) {
      if (RegExp(r'^[0-9]$').hasMatch(label)) {
        _handleNumberInput(label);
        return;
      }
      // চ্যানেল লিস্ট খোলা থাকলে এই হ্যান্ডলার কাজ করবে না — লিস্টের ফোকাস নোড হ্যান্ডেল করবে
      if (!_showChannelList) {
        if (event.logicalKey == LogicalKeyboardKey.channelUp ||
            event.logicalKey == LogicalKeyboardKey.pageUp ||
            event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _switchChannel(-1);
          return;
        }
        if (event.logicalKey == LogicalKeyboardKey.channelDown ||
            event.logicalKey == LogicalKeyboardKey.pageDown ||
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _switchChannel(1);
          return;
        }
      }

      if (!_showControls) {
        setState(() => _showControls = true);
        _startControlsTimer();
        return;
      }
      _startControlsTimer();

      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.goBack) {
        _invokeExitWidget();
      }
    }

    if (event is KeyUpEvent) {
      if (!_showChannelList &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        setState(() {
          _showChannelList = true;
          _showControls = true;
        });
        return;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prepareForExitRelease();
    _focus.dispose();
    HttpOverrides.global = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_appState == null) return const Scaffold(backgroundColor: Colors.black);

    final ch = _appState!.currentChannel;
    final bool initialized = _nativeCtrl != null && _nativeCtrl!.value.isInitialized && !_hasStreamError;
    final bool isLive = (_nativeCtrl?.value.duration == Duration.zero || _nativeCtrl?.value.duration == null);

    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _invokeExitWidget(); 
      },
      child: KeyboardListener(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: _toggleControls,
            onHorizontalDragEnd: (d) {
              if (d.primaryVelocity == null) return;
              if (d.primaryVelocity! < -300) _switchChannel(1);
              if (d.primaryVelocity! > 300) _switchChannel(-1);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (initialized)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox(
                        width: _nativeCtrl!.value.size.width,
                        height: _nativeCtrl!.value.size.height,
                        child: native_vp.VideoPlayer(_nativeCtrl!),
                      ),
                    ),
                  )
                else
                  LoadingOverlay(
                    hasError: _hasStreamError,
                    retryCount: _retryCount,
                    maxRetry: _maxRetry,
                    channelName: ch.name,
                    onRetry: () {
                      _retryCount = 0;
                      setState(() { _hasStreamError = false; _activeChannelId = null; });
                      _initController();
                    },
                    onNext: () => _switchChannel(1),
                  ),

                if (_showControls)
                  PlayerTopPanel(
                    channel: ch,
                    currentIndex: _appState!.currentChannelIndex,
                    totalChannels: _appState!.channels.length,
                    typedNumber: _typed,
                  ),

                if (_showChannelList)
                  ChannelListPanel(
                    channels: _appState!.channels,
                    currentIndex: _appState!.currentChannelIndex,
                    onSettings: _openSettings,
                    onSelect: (i) {
                      setState(() => _showChannelList = false);
                      _switchToIndex(i);
                      _focus.requestFocus();
                    },
                    onClose: () {
                      setState(() => _showChannelList = false);
                      // প্যানেল বন্ধ হলে player root focus ফেরত
                      _focus.requestFocus();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
