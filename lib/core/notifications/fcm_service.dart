import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  FcmService._internal();

  static const String _tag = 'FcmService';
  static const String _dbgLogPath = 'debug-e6dec6.log';
  static const String _dbgRunId = 'pre-fix';

  static void _dbg(
    String hypothesisId,
    String location,
    String message, {
    Map<String, Object?> data = const {},
  }) {
    // #region agent log
    try {
      final payload = <String, Object?>{
        'sessionId': 'e6dec6',
        'runId': _dbgRunId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      File(
        _dbgLogPath,
      ).writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
  }

  @pragma('vm:entry-point')
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  final _messageController = StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onMessage => _messageController.stream;

  // Channel configuration
  static const String _highImportanceChannelId = 'leave_requests_channel';
  static const String _highImportanceChannelName = 'Leave Requests';
  static const String _highImportanceChannelDescription =
      'Notifications for leave requests requiring action';

  static const String _defaultChannelId = 'general_notifications_channel';
  static const String _defaultChannelName = 'General Notifications';

  // Define notification categories for iOS action buttons
  static const String _leaveRequestCategoryId = 'leave_request_category';
  static const String _dedupeStoreKey = 'fcm_recent_notification_keys';
  static const int _maxStoredDedupKeys = 50;

  // Track processed notifications to prevent duplicates
  GlobalKey<NavigatorState>? _navigatorKey;
  final Set<String> _processedNotifications = {};

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> init() async {
    if (_isInitialized) {
      developer.log('FCM Service already initialized', name: _tag);
      _dbg('H1', 'fcm_service.dart:init', 'init skipped (already initialized)');
      return;
    }

    try {
      _dbg('H1', 'fcm_service.dart:init', 'init start');
      await _initLocalNotifications();
      await _registerForPush();
      _configureFCMHandlers();
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      await _getInitialToken();
      await _handleInitialMessage();

      _isInitialized = true;
      developer.log('FCM Service initialized successfully', name: _tag);
      _dbg('H1', 'fcm_service.dart:init', 'init success');
    } catch (e, stack) {
      developer.log(
        'Failed to initialize FCM Service',
        name: _tag,
        error: e,
        stackTrace: stack,
      );
      _dbg(
        'H1',
        'fcm_service.dart:init',
        'init error',
        data: {'error': e.toString()},
      );
    }
  }

  /// Gets the phone ready for pushes: how they show while the app is open
  /// on iOS, and the FCM token. It asks the user nothing; the app explains
  /// notifications and asks for them once the user has signed in.
  Future<void> _registerForPush() async {
    try {
      final messaging = FirebaseMessaging.instance;
      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        await _initializeIOSPushNotifications(messaging);
      } else {
        await _initializeAndroidPushNotifications(messaging);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to register for push notifications',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _initializeIOSPushNotifications(
    FirebaseMessaging messaging,
  ) async {
    developer.log('Initializing iOS push notifications...', name: _tag);
    await Future.delayed(const Duration(milliseconds: 500));
    String? apnsToken;
    for (int attempt = 1; attempt <= 10; attempt++) {
      try {
        apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          developer.log('APNs token received on attempt $attempt', name: _tag);
          developer.log('APNs token: $apnsToken', name: _tag);
          break;
        }
      } catch (e) {
        developer.log('APNs token attempt $attempt failed: $e', name: _tag);
      }

      await Future.delayed(const Duration(seconds: 1));
    }
    if (apnsToken == null || apnsToken.isEmpty) {
      developer.log('APNs token was not received after retries.', name: _tag);

      // Do NOT call getToken() here.
      return;
    }

    // APNs token is now available, so FCM token can safely be requested.
    try {
      final fcmToken = await messaging.getToken();
      developer.log('FCM token: $fcmToken', name: _tag);
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await StorageService.saveFcmToken(fcmToken);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get FCM token after APNs token became available',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _initializeAndroidPushNotifications(
    FirebaseMessaging messaging,
  ) async {
    try {
      final token = await messaging.getToken();

      developer.log('FCM token: $token', name: _tag);

      if (token != null && token.isNotEmpty) {
        await StorageService.saveFcmToken(token);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get Android FCM token',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @pragma('vm:entry-point')
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final List<DarwinNotificationCategory> iOSCategories = [
      DarwinNotificationCategory(
        _leaveRequestCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'approve_action',
            'Approve',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
              DarwinNotificationActionOption.destructive,
            },
          ),
          DarwinNotificationAction.plain(
            'reject_action',
            'Reject',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
              DarwinNotificationActionOption.destructive,
            },
          ),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.customDismissAction,
          DarwinNotificationCategoryOption.allowAnnouncement,
        },
      ),
    ];

    final iosSettings = DarwinInitializationSettings(
      // Asked for after sign-in, with the reason first; not at launch.
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestProvisionalPermission: false,
      requestCriticalPermission: false,
      requestProvidesAppNotificationSettings: false,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
      notificationCategories: iOSCategories,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    const androidHighChannel = AndroidNotificationChannel(
      _highImportanceChannelId,
      _highImportanceChannelName,
      description: _highImportanceChannelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      enableLights: false,
      showBadge: true,
    );

    const androidDefaultChannel = AndroidNotificationChannel(
      _defaultChannelId,
      _defaultChannelName,
      description: 'General notifications',
      importance: Importance.defaultImportance,
      enableVibration: false,
      playSound: true,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(androidHighChannel);
    await androidPlugin.createNotificationChannel(androidDefaultChannel);
  }

  void _configureFCMHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    developer.log('remote Message:${message.notification?.toMap()}');
    final dedupeKey = _resolveNotificationKey(message);
    if (await _wasNotificationHandled(dedupeKey)) {
      return;
    }
    await _markNotificationHandled(dedupeKey);

    developer.log(
      'Received foreground message: ${message.notification}',
      name: _tag,
    );

    await _showLocalNotification(message);
    _messageController.add(message);
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    developer.log('App opened from notification', name: _tag);

    if (message.messageId != null) {
      _processedNotifications.remove(message.messageId);
    }

    _navigateToScreen(message);
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    developer.log(
      'Handling background message ${message.notification?.toMap()}',
      name: _tag,
    );

    final fcmService = FcmService();
    final dedupeKey = fcmService._resolveNotificationKey(message);
    if (await fcmService._wasNotificationHandled(dedupeKey)) {
      return;
    }
    await fcmService._markNotificationHandled(dedupeKey);

    // Android/iOS can auto-display "notification" payloads in background/terminated.
    // Only create a local notification for data-only payloads to prevent duplicates.
    if (message.notification != null) {
      return;
    }
    await fcmService.showBackgroundNotificationWithActions(message);
  }

  @pragma('vm:entry-point')
  Future<void> showBackgroundNotificationWithActions(
    RemoteMessage message,
  ) async {
    developer.log('Showing background notification with actions', name: _tag);

    try {
      final data = message.data;

      // Get values from data - NO HARDCODED FALLBACKS
      final String? title = data['title'];
      final String? body = data['body'];
      final String? type = data['type'];
      final String? leaveId = data['leaveId'] ?? data['leave_id'];

      // Log received data
      developer.log('📱 Received from server:', name: _tag);
      developer.log('   - Title: $title', name: _tag);
      developer.log('   - Body: $body', name: _tag);
      developer.log('   - Type: $type', name: _tag);
      developer.log('   - LeaveId: $leaveId', name: _tag);

      // Validate required fields
      if (title == null || body == null || type == null || leaveId == null) {
        developer.log('❌ Missing required fields', name: _tag);
        return;
      }

      // Check if this is a leave request
      final isLeaveRequest =
          type.toLowerCase().contains('leave') ||
          type == 'Sick Leave' ||
          type == 'Casual Leave' ||
          type == 'Earned Leave';

      if (!isLeaveRequest) {
        developer.log('Not a leave request', name: _tag);
        return;
      }

      final localNotifications = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationTap,
      );

      await _ensureNotificationChannels(localNotifications);

      final androidActions = [
        AndroidNotificationAction(
          'approve_$leaveId',
          'Approve',
          cancelNotification: true,
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'reject_$leaveId',
          'Reject',
          cancelNotification: true,
          showsUserInterface: true,
        ),
      ];

      final androidDetails = AndroidNotificationDetails(
        _highImportanceChannelId,
        _highImportanceChannelName,
        channelDescription: _highImportanceChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        actions: androidActions,
        enableVibration: true,
        playSound: true,
        enableLights: false,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Action required',
        ),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: _leaveRequestCategoryId,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = jsonEncode({
        'leaveId': leaveId,
        'type': type,
        'title': title,
        'body': body,
      });

      await localNotifications.show(
        id: leaveId.hashCode.abs() % 10000,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );

      developer.log('✓ Background notification shown with actions', name: _tag);
    } catch (e, stack) {
      developer.log(
        'Error showing background notification',
        name: _tag,
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _ensureNotificationChannels(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    const highChannel = AndroidNotificationChannel(
      _highImportanceChannelId,
      _highImportanceChannelName,
      description: _highImportanceChannelDescription,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      enableLights: false,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(highChannel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final messageId =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Get values from data first, then fallback to notification
    final String? title = data['title'] ?? notification?.title;
    final String? body = data['body'] ?? notification?.body;
    final String? type = data['type'];
    final String? leaveId = data['leaveId'] ?? data['leave_id'] ?? data['id'];

    if (title == null || body == null) return;

    final isLeaveRequest =
        type != null &&
        (type.toLowerCase().contains('leave') ||
            type == 'Sick Leave' ||
            type == 'Casual Leave' ||
            type == 'Earned Leave');

    final channelId = isLeaveRequest
        ? _highImportanceChannelId
        : _defaultChannelId;

    List<AndroidNotificationAction>? androidActions;

    if (isLeaveRequest && leaveId != null) {
      androidActions = [
        AndroidNotificationAction(
          'approve_$leaveId',
          'Approve',
          cancelNotification: true,
          showsUserInterface: true,
          contextual: true,
        ),
        AndroidNotificationAction(
          'reject_$leaveId',
          'Reject',
          cancelNotification: true,
          showsUserInterface: true,
          contextual: true,
        ),
      ];
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      isLeaveRequest ? _highImportanceChannelName : _defaultChannelName,
      channelDescription: isLeaveRequest
          ? _highImportanceChannelDescription
          : 'General notifications',
      importance: isLeaveRequest
          ? Importance.max
          : Importance.defaultImportance,
      priority: isLeaveRequest ? Priority.high : Priority.defaultPriority,
      actions: androidActions,
      enableVibration: isLeaveRequest,
      playSound: isLeaveRequest,
      enableLights: false,
      ticker: 'notification_ticker',
      styleInformation: isLeaveRequest
          ? BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Action required',
            )
          : null,
      category: isLeaveRequest
          ? AndroidNotificationCategory.call
          : AndroidNotificationCategory.status,
      fullScreenIntent: false,
      visibility: NotificationVisibility.public,
      color: Colors.blue,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      categoryIdentifier: isLeaveRequest ? _leaveRequestCategoryId : null,
      threadIdentifier: isLeaveRequest ? 'leave_requests' : null,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = messageId.hashCode.abs() % 10000;

    final payload = jsonEncode({
      'messageId': messageId,
      'data': data,
      'type': type,
      'leaveId': leaveId,
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    developer.log(
      'Background notification tap: ${response.actionId}',
      name: _tag,
    );

    if (response.payload == null || response.payload!.isEmpty) {
      if (response.actionId != null) {
        _handleActionFromId(response.actionId!);
      }
      return;
    }

    try {
      final payload = jsonDecode(response.payload!);
      _handleNotificationAction(response.actionId, payload);
    } catch (e) {
      if (response.actionId != null) {
        _handleActionFromId(response.actionId!);
      }
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    developer.log(
      'Foreground notification tap: ${response.actionId}',
      name: _tag,
    );

    if (response.payload == null || response.payload!.isEmpty) {
      if (response.actionId != null) {
        _handleActionFromId(response.actionId!);
      }
      return;
    }

    try {
      final payload = jsonDecode(response.payload!);

      if (response.actionId != null) {
        _handleNotificationAction(response.actionId, payload);
      } else {
        _navigateToScreenFromPayload(payload);
      }
    } catch (e) {
      if (response.actionId != null) {
        _handleActionFromId(response.actionId!);
      }
    }
  }

  static void _handleActionFromId(String actionId) {
    final parts = actionId.split('_');
    if (parts.length >= 2) {
      final action = parts[0];
      final leaveId = parts.sublist(1).join('_');

      if (action == 'approve') {
        _processLeaveAction(leaveId, 'approved', {});
      } else if (action == 'reject') {
        _processLeaveAction(leaveId, 'rejected', {});
      }
    }
  }

  @pragma('vm:entry-point')
  static void _handleNotificationAction(
    String? actionId,
    Map<String, dynamic> payload,
  ) {
    if (actionId == null) return;

    final parts = actionId.split('_');
    if (parts.isEmpty) return;

    final action = parts[0];
    String? leaveId = parts.length >= 2 ? parts.sublist(1).join('_') : null;

    if (leaveId == null && payload.isNotEmpty) {
      leaveId =
          payload['leaveId'] ??
          payload['leave_id'] ??
          payload['data']?['leaveId'] ??
          payload['data']?['leave_id'];
    }

    if (action == 'approve' || action.startsWith('approve')) {
      _processLeaveAction(leaveId, 'approved', payload);
    } else if (action == 'reject' || action.startsWith('reject')) {
      _processLeaveAction(leaveId, 'rejected', payload);
    }
  }

  static Future<void> _processLeaveAction(
    String? leaveId,
    String action,
    Map<String, dynamic>? payload,
  ) async {
    if (leaveId == null || leaveId.isEmpty) {
      await _showActionError('Unknown', action);
      return;
    }

    try {
      developer.log('Processing leave $action for ID: $leaveId', name: _tag);
      await _showActionConfirmation(leaveId, action);
    } catch (e) {
      await _showActionError(leaveId, action);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _showActionConfirmation(
    String leaveId,
    String action,
  ) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await flutterLocalNotificationsPlugin.initialize(settings: initSettings);

    const androidDetails = AndroidNotificationDetails(
      'action_confirmation_channel',
      'Action Confirmations',
      channelDescription: 'Notifications for action confirmations',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: '✅ Leave Request $action',
      body: 'Leave request #$leaveId has been $action successfully',
      notificationDetails: notificationDetails,
    );
  }

  static Future<void> _showActionError(String leaveId, String action) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await flutterLocalNotificationsPlugin.initialize(settings: initSettings);

    const androidDetails = AndroidNotificationDetails(
      'action_error_channel',
      'Action Errors',
      channelDescription: 'Notifications for action errors',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: '❌ Action Failed',
      body: 'Failed to $action leave request #$leaveId. Please try again.',
      notificationDetails: notificationDetails,
    );
  }

  void _navigateToScreen(RemoteMessage message) {
    if (_navigatorKey?.currentState == null) return;

    final data = message.data;
    final type = data['type'];
    final leaveId = data['leaveId'] ?? data['leave_id'];

    final isLeaveNotification =
        type != null &&
        (type.toString().toLowerCase().contains('leave') || leaveId != null);

    if (isLeaveNotification && leaveId != null) {
      _navigatorKey?.currentState?.pushNamed(
        AppRoutes.notifications,
        arguments: leaveId,
      );
    } else {
      _navigatorKey?.currentState?.pushNamed(AppRoutes.notifications);
    }
  }

  void _navigateToScreenFromPayload(Map<String, dynamic> payload) {
    if (_navigatorKey?.currentState == null) return;

    final leaveId =
        payload['leaveId'] ??
        payload['leave_id'] ??
        payload['data']?['leaveId'] ??
        payload['data']?['leave_id'];

    if (leaveId != null) {
      _navigatorKey?.currentState?.pushNamed(
        AppRoutes.notifications,
        arguments: leaveId,
      );
    } else {
      _navigatorKey?.currentState?.pushNamed(AppRoutes.notifications);
    }
  }

  Future<void> _getInitialToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveTokenToServer(token);
      }
    } catch (e) {
      developer.log('Failed to get initial token', name: _tag, error: e);
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    developer.log('FCM token refreshed', name: _tag);
    await _saveTokenToServer(token);
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _saveTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString('fcm_token');

      if (oldToken == token) return;

      await prefs.setString('fcm_token', token);
      await prefs.setBool('fcm_token_synced', false);
      await prefs.setString(
        'fcm_token_updated_at',
        DateTime.now().toIso8601String(),
      );

      developer.log('Token saved to SharedPreferences', name: _tag);
    } catch (e) {
      developer.log('Error saving token', name: _tag, error: e);
    }
  }

  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      developer.log('Error deleting token', name: _tag, error: e);
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (e) {
      developer.log('Error subscribing to topic', name: _tag, error: e);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (e) {
      developer.log('Error unsubscribing from topic', name: _tag, error: e);
    }
  }

  Future<void> dispose() async {
    await _messageController.close();
    _processedNotifications.clear();
  }

  String _resolveNotificationKey(RemoteMessage message) {
    final fromData =
        message.data['notification_id'] ??
        message.data['request_id'] ??
        message.data['leaveId'] ??
        message.data['leave_id'];
    if (fromData != null && fromData.toString().isNotEmpty) {
      return fromData.toString();
    }
    if (message.messageId != null && message.messageId!.isNotEmpty) {
      return message.messageId!;
    }
    final title = message.notification?.title ?? message.data['title'] ?? '';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final sent = message.sentTime?.millisecondsSinceEpoch ?? 0;
    return '$title|$body|$sent';
  }

  Future<bool> _wasNotificationHandled(String key) async {
    if (key.isEmpty) return false;
    if (_processedNotifications.contains(key)) return true;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_dedupeStoreKey) ?? <String>[];
    return existing.contains(key);
  }

  Future<void> _markNotificationHandled(String key) async {
    if (key.isEmpty) return;
    _processedNotifications.add(key);

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_dedupeStoreKey) ?? <String>[];
    if (!existing.contains(key)) {
      existing.add(key);
    }
    if (existing.length > _maxStoredDedupKeys) {
      final removeCount = max(0, existing.length - _maxStoredDedupKeys);
      existing.removeRange(0, removeCount);
    }
    await prefs.setStringList(_dedupeStoreKey, existing);
  }
}
