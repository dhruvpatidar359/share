import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:geofence/pages/login.dart';
import 'package:geofence/services/authServices/firebase_auth_services.dart';
import 'package:geofence/widgets/attendanceCard.dart';
import 'package:geofence/widgets/present_names.dart';
import 'package:geofence/widgets/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../services/firebase/firebase_services.dart';

class AdminCalender extends StatefulWidget {
  const AdminCalender({Key? key}) : super(key: key);

  @override
  State<AdminCalender> createState() => _AdminCalenderState();
}

class _AdminCalenderState extends State<AdminCalender> {
  Position? currentPosition;
  final officeReference = FirebaseDatabase.instance.ref('office');

  TextEditingController officeController = TextEditingController();

  TextEditingController latitudeController = TextEditingController();

  TextEditingController longitudeController = TextEditingController();

  TextEditingController radiusController = TextEditingController();

  FirebaseServices firebaseServices = FirebaseServices();

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void getCurrentLocation() async {
    currentPosition = await determinePosition();
    if (currentPosition != null) {
      setState(() {
        latitudeController.text = currentPosition!.latitude.toString();
        longitudeController.text = currentPosition!.longitude.toString();
      });
    }
  }

  String date_Control =
      DateFormat('yMd').format(DateTime.now()).toString().replaceAll("/", "-");
  FirebaseAuthService _firebaseAuthService =
      FirebaseAuthService(authService: FirebaseAuth.instance);
  DatabaseReference attendanceRef = FirebaseDatabase.instance.ref("attendance");

  bool isEmpty = true;
  late Query _query;
  Key _key = Key('New Key');

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    // TODO: implement your code here
    final date = args.value.toString();
    final inprocess = date.split(" ").first.split("-");
    final RegExp regexp = RegExp(r'^0+(?=.)');
    for (int i = 0; i < inprocess.length; i++) {
      inprocess[i] = inprocess[i].replaceAll(regexp, "");
    }
    setState(() {
      date_Control = "${inprocess[1]}-${inprocess[2]}-${inprocess[0]}";
      _query = attendanceRef.child(date_Control);
      _key = Key(date_Control);
    });
    noClass();
  }

  noClass() async {
    final snapshot = await attendanceRef.child(date_Control).get();
    if (snapshot.exists) {
      setState(() {
        isEmpty = false;
      });
    } else {
      setState(() {
        isEmpty = true;
      });
    }
  }

  getQuery() {
    _query = attendanceRef.child(date_Control);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.orange.shade100,
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.orange.shade50,
                    title: Text(
                      "Create Office",
                      textAlign: TextAlign.center,
                    ),
                    content: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: officeController,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5)),
                                    hintText: "office name..."),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: latitudeController,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5)),
                                    hintText: "latitude..."),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: longitudeController,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5)),
                                    hintText: "longitude..."),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: radiusController,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5)),
                                    hintText: "Radius..."),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: [
                      IconButton(
                          onPressed: () async {
                            getCurrentLocation();
                          },
                          icon: Icon(Icons.location_history)),
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close)),
                      IconButton(
                          onPressed: () {
                            firebaseServices.createOffice(
                                name: officeController.text,
                                latitude: double.parse(latitudeController.text),
                                longitude:
                                    double.parse(longitudeController.text),
                                radius: double.parse(radiusController.text));
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.check)),
                    ],
                  );
                });
          },
          child: Icon(Icons.add),
        ),
        appBar: AppBar(
          centerTitle: true,
          title: Text('Attendance'),
          actions: [
            IconButton(
              onPressed: () {
                _firebaseAuthService.signOut();
                nextScreenReplace(context, LoginPage());
              },
              icon: Icon(
                Icons.logout,
                size: 25,
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: SfDateRangePicker(
                  onSelectionChanged: _onSelectionChanged,
                  selectionMode: DateRangePickerSelectionMode.single,
                ),
              ),
              getAttendanceList(),
            ],
          ),
        ),
      ),
    );
  }

  getAttendanceList() {
    return isEmpty
        ? Expanded(
            child: Card(
            elevation: 5,
            shape: OutlineInputBorder(borderRadius: BorderRadius.circular(2)),
            color: Colors.orange.shade50,
            shadowColor: Colors.orange,
            child: Center(
              child: Text(
                'No Class',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
          ))
        : Expanded(

      child: FirebaseAnimatedList(
        query: _query,
        key: _key,
        itemBuilder: (context, snapshot, animation, index) {
          String userId = snapshot.value.toString();
          Object? data = snapshot.value;
          String userName = snapshot.child('$index').child('name').value.toString();
          String userOffice = snapshot.child('$index').child('office_name').value.toString();
          print(userId);
          return AttendanceName(userName: userName , officeName: userOffice);
        },
      ),
    );
  }
}
