import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

// In alarm_service.dart
// Make sure this is outside any class, at the top level
// Ensure this is a global function
@pragma('vm:entry-point')
void callbackDispatcher() {
  final SendPort? sendPort = IsolateNameServer.lookupPortByName(AlarmService.isolateName);
  
  // Reinitialize the alarm manager inside the callback
  AndroidAlarmManager.initialize();

  debugPrint('✅ Alarm Manager initialized in background isolate');
}


class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  static const String isolateName = 'alarm_isolate';
  static const String channelId = 'taskverse_reminders';
  static const String channelName = 'Task Reminders';
  static SendPort? uiSendPort;
  
  // ID used to identify task info in notifications
  static const String taskIdentifier = 'task_id';

  // Initialize both AndroidAlarmManager and notifications
  static Future<void> init() async {
    // Initialize alarm manager
    await AndroidAlarmManager.initialize();
    
    // Initialize notification settings
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );
    
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap - navigate to task details
        debugPrint('Notification tapped with payload: ${details.payload}');
      },
    );
    
    // Set up background communication
    final ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, isolateName);
    port.listen((dynamic data) {
      // Handle data from alarm callback
      debugPrint('Received alarm data: $data');
    });
    
    // Request notification permissions
    // await _requestNotificationPermissions();
  }
  // Add this to your AlarmService class
  static Future<void> testAlarm() async {
    final now = DateTime.now();
    final alarmTime = now.add(const Duration(seconds: 10));
    
    await setAlarm(
      id: 12345,
      alarmTime: alarmTime,
      title: 'Test Alarm',
      body: 'This is a test alarm to verify functionality',
    );
    
    debugPrint('Test alarm set for $alarmTime');
  }
  // static Future<void> _requestNotificationPermissions() async {
  //   await _notificationsPlugin
  //       .resolvePlatformSpecificImplementation<
  //           AndroidFlutterLocalNotificationsPlugin>()
  //       ?.requestPermission();
  // }

  // Set an alarm for a task
  static Future<void> setAlarm({
    required int id, 
    required DateTime alarmTime,
    String title = 'Task Reminder',
    String body = 'It\'s time for your task!',
    String? payload,
  }) async {
    if (alarmTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Cannot set alarm in the past: $alarmTime');
      return;
    }
    
    debugPrint('🔔 Setting alarm for $alarmTime with ID: $id');
    
    // Schedule alarm using AndroidAlarmManager
    // Schedule alarm using AndroidAlarmManager
    bool success = await AndroidAlarmManager.oneShotAt(
      alarmTime,
      id, // Unique ID
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );

    if (!success) {
      debugPrint('❌ Failed to schedule alarm for ID: $id');
      return;
    }

    
    // Store parameters in a static map for later retrieval
    _alarmParameters[id] = {
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
    };
    
    debugPrint('⏰ Alarm scheduled for $alarmTime with ID: $id');
  }
  
  // Static map to store alarm parameters
  static final Map<int, Map<String, dynamic>> _alarmParameters = {};
  
  // Entry point for alarm callback
  @pragma('vm:entry-point')
  static Future<void> _alarmCallback(int id) async {
    debugPrint('🔥 Alarm triggered with ID: $id at ${DateTime.now()}');
    
    // Check if parameters exist
    final Map<String, dynamic>? params = _alarmParameters[id];
    if (params == null) {
      debugPrint('⚠️ No parameters found for alarm ID: $id');
      return;
    }
    
    // Show notification
    await _showNotification(
      id: id,
      title: params['title'] ?? 'Task Reminder',
      body: params['body'] ?? 'It\'s time for your task!',
      payload: params['payload'],
    );

    // Send message to UI isolate if needed
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(isolateName);
    if (sendPort != null) {
      sendPort.send({
        'id': id,
        'triggered': DateTime.now().toIso8601String(),
      });
    }
  }

  
  // Show a notification
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for task reminders',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm.mp3'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
    
    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true, 
      presentBadge: true,
      presentSound: true,
      sound: 'alarm.wav',
    );
    
    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
    
    debugPrint('📱 Notification displayed: $title');
  }
  
  // Method to directly show a notification without alarm
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
  
  // Cancel an alarm by ID
  static Future<void> cancelAlarm(int id) async {
    await AndroidAlarmManager.cancel(id);
    await _notificationsPlugin.cancel(id);
    _alarmParameters.remove(id);
    debugPrint('❌ Alarm with ID $id canceled');
  }
  
  // Cancel multiple alarms
  static Future<void> cancelAlarms(List<int> ids) async {
    for (int id in ids) {
      await cancelAlarm(id);
    }
  }
  
  // Cancel all alarms
  static Future<void> cancelAllAlarms() async {
    _alarmParameters.keys.toList().forEach((id) async {
      await cancelAlarm(id);
    });
    await _notificationsPlugin.cancelAll();
    debugPrint('🧹 All alarms canceled');
  }
}