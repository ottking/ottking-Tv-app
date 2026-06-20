import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/channel_model.dart';
import '../../data/repositories/live_tv_repository.dart';
import '../../data/services/secure_storage_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.repository,
    required this.prefs,
    required this.secureStorage,
  });

  final LiveTvRepository repository;
  final SharedPreferences prefs;
  final SecureStorageService secureStorage;

  // ── State ──────────────────────────────────────────────────────────────────

  bool isLoading = true;
  bool bootToPlayer = false;
  ThemeMode themeMode = ThemeMode.dark;
  String errorMessage = '';

  List<ChannelModel> channels = [];
  List<CategoryModel> categories = [];
  List<BannerModel> banners = [];
  List<SubscriptionPlanModel> plans = [];

  int _currentChannelIndex = 0;
  int get currentChannelIndex => _currentChannelIndex;

  set currentChannelIndex(int value) {
    if (channels.isEmpty) return;
    _currentChannelIndex = value.clamp(0, channels.length - 1);
    _saveLastChannelId(channels[_currentChannelIndex].id);
    notifyListeners();
  }

  bool showToast = false;
  String toastMessage = '';

  UserProfileModel? userProfile;
  bool isAuthenticated = false;

  Timer? _toastTimer;

  // ── Bootstrap ──────────────────────────────────────────────────────────────

  Future<void> bootstrap() async {
    themeMode = prefs.getString(AppConstants.keyThemeMode) == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;

    bootToPlayer = prefs.getBool(AppConstants.keyBootToPlayer) ?? false;

    isAuthenticated = await secureStorage.hasUserSession();
    userProfile = await secureStorage.readUserProfile();

    await loadCatalog();
    isLoading = false;
    notifyListeners();
  }

  // ── Catalog ────────────────────────────────────────────────────────────────

  Future<void> loadCatalog() async {
    try {
      final catalog = await repository.fetchCatalog();
      channels = catalog.channels;
      categories = catalog.categories;
      banners = catalog.banners;
      plans = catalog.plans;

      // Restore last played channel
      final lastId = prefs.getString(AppConstants.keyLastChannelId);
      if (lastId != null) {
        final idx = channels.indexWhere((c) => c.id == lastId);
        _currentChannelIndex = idx >= 0 ? idx : 0;
      } else {
        if (_currentChannelIndex >= channels.length) _currentChannelIndex = 0;
      }

      errorMessage = '';
    } catch (e) {
      channels = [];
      categories = [];
      banners = [];
      plans = [];
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  // ── Boot Player ────────────────────────────────────────────────────────────

  /// Returns true when app should go directly to player on boot.
  bool shouldBootToPlayer() => bootToPlayer && channels.isNotEmpty;

  Future<void> setBootToPlayer(bool enabled) async {
    bootToPlayer = enabled;
    await prefs.setBool(AppConstants.keyBootToPlayer, enabled);
    notifyListeners();
  }

  void togglePlayerBoot() => setBootToPlayer(!bootToPlayer);
  bool get isPlayerBootEnabled => bootToPlayer;

  // ── Theme ──────────────────────────────────────────────────────────────────

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    prefs.setString(
      AppConstants.keyThemeMode,
      themeMode == ThemeMode.light ? 'light' : 'dark',
    );
    notifyListeners();
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    errorMessage = '';
    notifyListeners();
    try {
      final res = await repository.authenticate(email, password);
      await _handleAuthResponse(res, email);
      await loadCatalog();
    } catch (e) {
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    errorMessage = '';
    notifyListeners();
    try {
      final res = await repository.register(email, password);
      await _handleAuthResponse(res, email);
      await loadCatalog();
    } catch (e) {
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> _handleAuthResponse(
      Map<String, dynamic> res, String fallbackEmail) async {
    final token = res['token'] as String? ?? 'demo-token';
    final profile = UserProfileModel(
      email: res['email'] as String? ?? fallbackEmail,
      plan: res['plan'] as String? ?? 'Premium',
    );
    await secureStorage.saveAuthToken(token);
    await secureStorage.saveUserProfile(profile);
    userProfile = profile;
    isAuthenticated = true;
    errorMessage = '';
  }

  Future<void> logout() async {
    await secureStorage.clearSession();
    isAuthenticated = false;
    userProfile = null;
    _currentChannelIndex = 0;
    await loadCatalog();
    notifyListeners();
  }

  // ── Channel Switching ──────────────────────────────────────────────────────

  /// Switches by direction (+1 or -1). Always switches regardless of
  /// whether the current channel has an error — error handling is in the player.
  void switchChannel(int direction) {
    if (channels.isEmpty) return;
    _currentChannelIndex =
        (_currentChannelIndex + direction + channels.length) % channels.length;
    _saveLastChannelId(channels[_currentChannelIndex].id);
    _showChannelToast(channels[_currentChannelIndex].name);
  }

  void selectChannelByIndex(int index) {
    if (channels.isEmpty) return;
    _currentChannelIndex = index.clamp(0, channels.length - 1);
    _saveLastChannelId(channels[_currentChannelIndex].id);
    _showChannelToast(channels[_currentChannelIndex].name);
  }

  void _saveLastChannelId(String id) {
    prefs.setString(AppConstants.keyLastChannelId, id);
  }

  void _showChannelToast(String channelName) {
    toastMessage = channelName;
    showToast = true;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(AppConstants.toastDuration, () {
      showToast = false;
      notifyListeners();
    });
  }

  // ── Current Channel ────────────────────────────────────────────────────────

  // নতুন ৩টি DRM প্রপার্টির ডিফল্ট ভ্যালু সহ সম্পূর্ণ ফিক্সড অবজেক্ট
  static const ChannelModel _fallbackChannel = ChannelModel(
    id: 'fallback',
    name: 'Live Preview',
    category: 'Preview',
    streamUrl: AppConstants.fallbackStreamUrl,
    logoUrl: '',
    description: 'Secure preview channel',
    quality: 'HD',
    isPremium: 0,
    isClearKey: false,     // ফিক্সড: টাইপ এরর হ্যান্ডলিংয়ের জন্য
    clearKeyId: null,      // ফিক্সড: নাল ভ্যালু ডিফাইন
    clearKeyValue: null,   // ফিক্সড: নাল ভ্যালু ডিফাইন
  );

  ChannelModel get currentChannel =>
      channels.isEmpty ? _fallbackChannel : channels[_currentChannelIndex];

  String get currentChannelName => currentChannel.name;

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}
