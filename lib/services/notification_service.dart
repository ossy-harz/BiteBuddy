import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitebuddy/models/pantry_item.dart';
import 'package:bitebuddy/models/meal_plan.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'bitebuddy_channel',
      'BiteBuddy Notifications',
      channelDescription: 'Notifications from BiteBuddy app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'bitebuddy_scheduled_channel',
      'BiteBuddy Scheduled Notifications',
      channelDescription: 'Scheduled notifications from BiteBuddy app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Schedule notifications for expiring pantry items
  Future<void> scheduleExpiryNotifications(List<PantryItem> pantryItems) async {
    // Cancel existing expiry notifications
    for (int i = 1000; i < 2000; i++) {
      await cancelNotification(i);
    }

    int notificationId = 1000;
    final now = DateTime.now();

    for (final item in pantryItems) {
      if (item.expiryDate != null) {
        final daysUntilExpiry = item.expiryDate!.difference(now).inDays;

        // Notify 3 days before expiry
        if (daysUntilExpiry <= 3 && daysUntilExpiry > 0) {
          final scheduledDate = now.add(const Duration(hours: 9)); // 9 AM today

          await scheduleNotification(
            id: notificationId++,
            title: 'Item Expiring Soon',
            body: '${item.name} will expire in $daysUntilExpiry days',
            scheduledDate: scheduledDate,
            payload: 'pantry_item_${item.id}',
          );
        }

        // Notify on expiry day
        if (daysUntilExpiry == 0) {
          final scheduledDate = now.add(const Duration(hours: 9)); // 9 AM today

          await scheduleNotification(
            id: notificationId++,
            title: 'Item Expiring Today',
            body: '${item.name} expires today',
            scheduledDate: scheduledDate,
            payload: 'pantry_item_${item.id}',
          );
        }
      }
    }
  }

  // Schedule notifications for meal plans
  Future<void> scheduleMealPlanNotifications(List<MealPlan> mealPlans) async {
    // Cancel existing meal plan notifications
    for (int i = 2000; i < 3000; i++) {
      await cancelNotification(i);
    }

    int notificationId = 2000;
    final now = DateTime.now();

    for (final mealPlan in mealPlans) {
      final daysUntilMealPlan = mealPlan.date.difference(now).inDays;

      // Notify 1 day before meal plan
      if (daysUntilMealPlan == 1) {
        final scheduledDate = now.add(const Duration(hours: 18)); // 6 PM today

        int totalMeals = 0;
        for (final meals in mealPlan.meals.values) {
          totalMeals += meals.length;
        }

        await scheduleNotification(
          id: notificationId++,
          title: 'Meal Plan Tomorrow',
          body: 'You have $totalMeals meals planned for tomorrow',
          scheduledDate: scheduledDate,
          payload: 'meal_plan_${mealPlan.id}',
        );
      }

      // Notify on meal plan day
      if (daysUntilMealPlan == 0) {
        final scheduledDate = now.add(const Duration(hours: 7)); // 7 AM today

        for (final entry in mealPlan.meals.entries) {
          final mealType = entry.key;
          final meals = entry.value;

          if (meals.isNotEmpty) {
            await scheduleNotification(
              id: notificationId++,
              title: '$mealType Today',
              body: 'You have ${meals.length} ${meals.length == 1 ? 'recipe' : 'recipes'} planned for $mealType',
              scheduledDate: scheduledDate,
              payload: 'meal_plan_${mealPlan.id}_$mealType',
            );
          }
        }
      }
    }
  }

  // Check and schedule all notifications
  Future<void> checkAndScheduleAllNotifications(String userId) async {
    try {
      // Get pantry items
      final pantrySnapshot = await FirebaseFirestore.instance
          .collection('pantry_items')
          .where('userId', isEqualTo: userId)
          .get();

      final pantryItems = pantrySnapshot.docs.map((doc) {
        final data = doc.data();
        return PantryItem.fromMap(data, doc.id);
      }).toList();

      // Schedule expiry notifications
      await scheduleExpiryNotifications(pantryItems);

      // Get meal plans for the next 7 days
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final mealPlans = <MealPlan>[];
      for (var day = now; day.isBefore(nextWeek); day = day.add(const Duration(days: 1))) {
        final docId = '${userId}_${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final doc = await FirebaseFirestore.instance
            .collection('meal_plans')
            .doc(docId)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          mealPlans.add(MealPlan.fromMap(data, doc.id));
        }
      }

      // Schedule meal plan notifications
      await scheduleMealPlanNotifications(mealPlans);
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }
}

