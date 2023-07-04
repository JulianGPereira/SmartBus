import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smartbus/BusDetails.dart';
import 'package:smartbus/BusesList.dart';
import 'package:smartbus/Home.dart';
import 'package:smartbus/Login.dart';
import 'package:smartbus/Otp.dart';
import 'package:smartbus/Paths.dart';
import 'package:smartbus/SignupPage.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel androidNotificationChannel = AndroidNotificationChannel(
    "Smart_Bus_Android",
    "SmartBus",
    description: "Android Notification Channel for Smart Bus App",
    importance: Importance.high
);

const DarwinNotificationDetails iosNotificationChannel = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    threadIdentifier: "SmartBus",
    subtitle: "SmartBus",
    categoryIdentifier: "SmartBus",
    attachments: []
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> notificationInitializer() async {
    AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings("assets/logo.png");
    DarwinInitializationSettings darwinInitializationSettings = DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: darwinInitializationSettings
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: Paths().Login,
      routes: {
        Paths().Login: (context) => Login(),
        Paths().Otp: (context) => Otp(),
        Paths().Home: (context) => Home(),
        Paths().BusesList: (context) => BusesList(),
        Paths().BookBus: (context) => BusDetails(),
        Paths().Signup: (context) => SignupPage()
      },
    );
  }
}