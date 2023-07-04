import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartbus/Paths.dart';

class HomeFragment extends StatefulWidget {
  const HomeFragment({Key? key}) : super(key: key);

  @override
  State<HomeFragment> createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment> {
  var dio = Dio();

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  StreamSubscription? timerSubscription;

  var ApiKey = "AIzaSyC82yHplmDt-JGwazkcILZkcF0VEbhP7bg";

  void getMyLocation() async {
    var stats = await Geolocator.checkPermission();
    if (mounted) {
      if (stats == LocationPermission.always ||
          stats == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition();
        // log("Login response : " + position.toString());
        if (mounted) {
          setState(() {
            Paths().CAMERA = position;
            log("HomeFrag" + Paths().CAMERA.toString());
          });
        }
      } else {
        await Geolocator.requestPermission();
        var updatedStats = await Geolocator.checkPermission();
        if (mounted &&
            (updatedStats == LocationPermission.always ||
                updatedStats == LocationPermission.whileInUse)) {
          getMyLocation(); // Recursive call after permission is granted and widget is still mounted.
        }
      }
    }
  }

  late CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(
      Paths().CAMERA?.Latitude ?? 9.624231666666667,
      Paths().CAMERA?.Longitude ?? 76.848545,
    ),
    zoom: 14.4746,
  );

  late Marker bus_marker = Marker(markerId: MarkerId("Bus tracker"));
  late Marker self_marker = Marker(
    markerId: MarkerId("Self tracker"),
    position: LatLng(
        Paths().POSITION != null ? Paths().POSITION.Latitude : 9.3814395,
        Paths().POSITION != null ? Paths().POSITION.Longitude : 76.556662),
  );

  late CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(Paths().CAMERA?.latitude ?? 9.624231,
          Paths().CAMERA?.longitude ?? 76.848545),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  var destination_controller = TextEditingController();
  var location_controller = TextEditingController();

  var bus_location_url =
      "https://smart-bus-iot-42439-default-rtdb.firebaseio.com/Bus%20Detail/Location%20Coordinates.json";
  var bus_capacity_url =
      "https://smart-bus-iot-42439-default-rtdb.firebaseio.com/Bus%20Detail/Seat%20Count.json";
  var total_capacity = "50";
  var live_capacity = "50";
  var live_index = -1;
  var markers = {};

  var destinations = [
    "Thiruvananthapuram",
    "Kollam",
    "Kottayam",
    "Pathanamthitta"
  ];

  void get_buses() async {
    try {
      var response = await dio.get(Paths().BASE_URL + "get_buses");
      if (response.statusCode == 200) {
        var data = json.decode(response.data);
        if (data['result'].isEmpty) {
          Fluttertoast.showToast(msg: "Invalid user details");
        } else {
          setState(() {
            Paths().Buses = data['result'];
            for (var item in Paths().Buses) {
              if (item['reg_no'].toString() == "KL-01A 1243") {
                live_index = Paths().Buses.indexOf(item);
              }
            }
          });
        }
      } else {
        Fluttertoast.showToast(
            msg: "Some error occured. Please check server connection");
      }
    } on DioError catch (error) {
      Fluttertoast.showToast(
          msg: "Some error occured. Please check server connection");
    }
  }

  void start_timer() {
    timerSubscription = Stream.periodic(Duration(seconds: 5)).listen((_) {
      get_bus_capacity();
      get_my_location();
      get_bus_location();
    });
  }

  Future<double> calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) async {
    double distanceInMeters = await Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );

    // Convert meters to kilometers
    double distanceInKilometers = distanceInMeters / 1000;

    return distanceInKilometers;
  }

  void get_bus_location() async {
    try {
      var response = await dio.get(bus_location_url);
      log("Bus Location : " + response.data.toString());
      if (response.statusCode == 200) {
        double dist = await calculateDistance(
            response.data['Latitude'],
            response.data['Longitude'],
            Paths().POSITION?.latitude ?? 0.0,
            Paths().POSITION?.longitude ?? 0.0);
        if (mounted) {
          setState(() {
            if (live_index != -1) {
              Paths().Buses[live_index]['current_lat'] =
                  response.data['latitude'];
              Paths().Buses[live_index]['current_long'] =
                  response.data['longitude'];
              markers[live_index] = Marker(
                  markerId: MarkerId("Bus tracker"),
                  position: LatLng(
                      response.data['Latitude'], response.data['Longitude']));
            }
            if (response.data['latitude'] != null) {
              Paths().BUS_POSITION =
                  LatLng(response.data['latitude'], response.data['longitude']);
              bus_marker = Marker(
                  markerId: MarkerId("Bus tracker"),
                  position: LatLng(
                      response.data['Latitude'], response.data['Longitude']),
                  infoWindow: InfoWindow(
                    title: "Live Bus (${live_capacity}/${total_capacity})",
                    snippet: "Arrival in " + (dist / 40).toString(),
                  ));
            }
          });
        }
      } else {
        Fluttertoast.showToast(msg: "Could not fetch live location...");
      }
    } on Exception catch (error) {
      log("Bus Location error : " + error.toString());
      Fluttertoast.showToast(
          msg: "Some error occured. Please check firebase url");
    }
  }

  void get_my_location() async {
    var stats = await Geolocator.checkPermission();
    if (stats == LocationPermission.always ||
        stats == LocationPermission.whileInUse) {
      try {
        Position position = await Geolocator.getCurrentPosition();
        var reverse_geocoding_url =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude.toString()},${position.longitude.toString()}&key=$ApiKey";
        var response = await dio.get(reverse_geocoding_url);
        if (response.statusCode == 200 && response.data['plus_code'] != null) {
          if (mounted) {
            setState(() {
              location_controller.text =
                  response.data['plus_code']['compound_code'].toString();
              Paths().Location =
                  response.data['plus_code']['compound_code'].toString();
              Paths().POSITION = position;
              self_marker = Marker(
                markerId: MarkerId("Self tracker"),
                position: LatLng(position.latitude, position.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
              );
            });
          }
        }
      } on Exception catch (error) {
        log("Current position reverse geocoding error: " + error.toString());
        Fluttertoast.showToast(msg: "Unable to fetch my current location");
      }
    } else {
      await Geolocator.requestPermission();
    }
  }

  void get_bus_capacity() async {
    try {
      var response = await dio.get(bus_capacity_url);
      double dist = await calculateDistance(
          bus_marker.position.latitude,
          bus_marker.position.longitude,
          Paths().POSITION?.latitude ?? 0.0,
          Paths().POSITION?.longitude ?? 0.0);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            live_capacity = response.data.toString();
            log(response.data.toString());
            bus_marker = Marker(
              markerId: bus_marker.markerId,
              position: bus_marker.position,
              infoWindow: InfoWindow(
                title:
                    "Live Bus (${live_capacity.toString()}/${total_capacity})",
                snippet: "Arrival in " + (dist / 60).toString(),
              ),
            );
          });
        }
      } else {
        Fluttertoast.showToast(msg: "Unable to fetch capacity");
      }
    } on DioError catch (error) {
      Fluttertoast.showToast(
          msg: "Some error occured. Please check your firebase_url");
    }
  }

  void search(String value) {}

  void submit_clicked() {
    Paths().Location = location_controller.text.toString();
    Paths().Destination = destination_controller.text.toString();
    if (location_controller.text.toString().isNotEmpty &&
        destination_controller.text.toString().isNotEmpty) {
      Navigator.popAndPushNamed(context, Paths().BusesList);
    }
  }

  Future<void> show_location() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  @override
  void initState() {
    getMyLocation();
    super.initState();
    start_timer();
  }

  @override
  void dispose() {
    timerSubscription
        ?.cancel(); // Check if the subscription is not null before canceling it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
      height: MediaQuery.of(context).size.height / 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
            color: Colors.green.shade200,
            child: TextField(
              controller: location_controller,
              onChanged: search,
              decoration: InputDecoration(
                  labelText: "Enter your location",
                  contentPadding: EdgeInsets.symmetric(horizontal: 10)),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
            color: Colors.green.shade200,
            child: TextField(
              controller: destination_controller,
              onChanged: search,
              decoration: InputDecoration(
                  labelText: "Enter your destination",
                  contentPadding: EdgeInsets.symmetric(horizontal: 10)),
            ),
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: MediaQuery.of(context).size.height / 1.47,
                color: Colors.grey.withOpacity(0.2),
                child: Scaffold(
                  body: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _kGooglePlex,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    markers: {bus_marker, self_marker},
                  ),
                  floatingActionButton: FloatingActionButton.small(
                    onPressed: show_location,
                    child: Icon(Icons.my_location),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
                child: ElevatedButton(
                    onPressed: submit_clicked, child: Text("Check Buses")),
              ),
            ],
          ),
          destination_controller.text.trim().isNotEmpty
              ? Container(
                  padding: EdgeInsets.all(15),
                  height: MediaQuery.of(context).size.height - 209,
                  color: Colors.green.shade200,
                  child: ListView.builder(
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                destinations[index].toString().trim(),
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                child: Text("Book"),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              : SizedBox()
        ],
      ),
    ));
  }
}
