import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'database.dart' as db;
import 'database.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({Key? key}) : super(key: key);

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  bool isError = false;
  int timeSpan = DateTime.now().millisecondsSinceEpoch;
  late String errorText;
  var latitude;
  var longitude;
  late List<db.LocationData> newData;
  @override
  void initState() {
    super.initState();
    try {
      _determinePosition();
    } catch (e) {
      setState(() {
        isError = true;
        errorText = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Position> _determinePosition() async {
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

  var data;
  DatabaseHelper databaseHelper = DatabaseHelper();
  Future<dynamic> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      latitude = position.latitude;
      longitude = position.longitude;
      data = LocationData(timeSpan: timeSpan, lat: latitude, long: longitude);
      print("inserting");

      await databaseHelper.insertData(data);
      newData = await databaseHelper.getAll();

      print('Data is $newData\n');
    } catch (e) {
      print(e);
    }
  }

  bool isStarted = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<List<db.LocationData>>(
                    future: databaseHelper.getAll(),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<db.LocationData>> snapshot) {
                      if (snapshot.hasData) {
                        return ListView.builder(
                            shrinkWrap: true,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                        "time : ${snapshot.data![index].timeSpan}"),
                                    Text("Lat : ${snapshot.data![index].lat}"),
                                    Text(
                                        "Long : ${snapshot.data![index].long}"),
                                  ],
                                ),
                              );
                            });
                      } else if (snapshot.hasError) {
                        return Text(
                          "error : ${snapshot.error.toString()}",
                          style: const TextStyle(color: Colors.red),
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    }),
                // const Text(
                //   'Location Latitude and longitude are:',
                //   style: TextStyle(color: Colors.blue),
                // ),
                // Text(
                //   'Latitude is $latitude \n Longitude is $longitude',
                //   style: const TextStyle(color: Colors.blue),
                // ),
                // const SizedBox(
                //   height: 50,
                // ),
                Container(
                  width: 150,
                  decoration: ShapeDecoration(
                    color: isStarted ? Colors.red : Colors.blue,
                    shape: const StadiumBorder(
                      side: BorderSide(
                        color: Colors.blue,
                        width: 1,
                      ),
                    ),
                  ),
                  child: TextButton(
                    onPressed: isStarted
                        ? () {
                            setState(() {
                              latitude = latitude;
                              isStarted = true;
                            });
                          }
                        : () {
                            Timer.periodic(const Duration(seconds: 10),
                                (Timer t) async {
                              await getCurrentLocation();
                            });
                            setState(() {
                              latitude = latitude;
                              timeSpan = timeSpan;
                              isStarted = false;
                            });
                          },
                    child: isStarted
                        ? const Text(
                            'Stop',
                            style: TextStyle(color: Colors.blue),
                          )
                        : const Text(
                            'Start',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
