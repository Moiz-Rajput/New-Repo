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
  var accuracy;
  int timeSpan = DateTime.now().millisecondsSinceEpoch;
  late String errorText;
  var latitude;
  var longitude;
  List<db.LocationData> newData = [];
  late StreamSubscription<Position> positionStream;
  var data;
  List<DataRow> displayedDataCell = [];
  DatabaseHelper databaseHelper = DatabaseHelper();

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

  Future<Object> _determinePosition() async {
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
    return Geolocator.getPositionStream();
  }

  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
  );

  void _startStream() {
    var index = 0;
    positionStream =
        Geolocator.getPositionStream(locationSettings: _locationSettings)
            .listen((Position? position) async {
      latitude = position!.latitude;
      longitude = position.longitude;
      accuracy = position.accuracy;
      data = LocationData(
          accuracy: accuracy,
          timeSpan: timeSpan,
          lat: latitude,
          long: longitude);
      print("inserting" + index.toString());
      await databaseHelper.insertData(data);
      newData = await databaseHelper.getAll();
      setState(() {
        for (var element in newData) {
          displayedDataCell.add(DataRow(cells: <DataCell>[
            DataCell(
              Text(
                element.timeSpan.toString(),
              ),
            ),
            DataCell(
              Text(
                element.accuracy.toString(),
              ),
            ),
            DataCell(
              Text(
                element.lat.toString(),
              ),
            ),
            DataCell(
              Text(
                element.long.toString(),
              ),
            )
          ]));
          index++;
          newData = newData;
          displayedDataCell = displayedDataCell;
        }
      });
      print(newData);
      print('Position is $latitude $longitude $accuracy');
    });
  }

  void _stopStream() {
    positionStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  child: DataTable(
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          'Timespan',
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Accuracy',
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Lat',
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'long',
                        ),
                      ),
                    ],
                    rows: displayedDataCell,
                  ),
                ),
                Container(
                  width: 150,
                  decoration: const ShapeDecoration(
                    color: Colors.blue,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: Colors.blue,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _stopStream();
                          });
                        },
                        child: const Text(
                          'Stop',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Container(
                        width: 15,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _startStream();
                          });
                        },
                        child: const Text(
                          'Start',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
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
