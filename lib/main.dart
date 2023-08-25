import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geofence/app.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geofence/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeService();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  SharedPreferences entry_tap = await SharedPreferences.getInstance();
  if(prefs.getInt('count') != 1){
    prefs.setInt('count', 0);
  }
  if(entry_tap.getInt('cnt') != 1){
    entry_tap.setInt('cnt', 0);
  }
  bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<void> initializeService() async{
  final service = FlutterBackgroundService();

  await service.configure(
      iosConfiguration: IosConfiguration(),
      androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      isForegroundMode: false,
      onStart:  onStart,
      ),
  );
  await service.startService();
}


@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });


  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // if you don't using custom notification, uncomment this
        service.setForegroundNotificationInfo(
          title: "GeoFence",
          content: "Attendance in progress...",
        );
      }
    }
  });
}

class MyApp extends StatelessWidget {
  bool isLoggedIn = false;

  MyApp({required this.isLoggedIn, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: App(
        isLoggedIn: isLoggedIn,
      ),
      // Define routes for the login and signup pages if needed
    );
  }
}