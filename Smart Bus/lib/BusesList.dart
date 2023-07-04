import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartbus/Paths.dart';

class BusesList extends StatefulWidget {
  const BusesList({Key? key}) : super(key: key);

  @override
  State<BusesList> createState() => _BusesListState();
}

class _BusesListState extends State<BusesList> {
  var destinations = [
    "Thiruvananthapuram",
    "Kollam",
    "Kottayam",
    "Pathanamthitta"
  ];
  var timer;

  var buses = [];
  var dio = Dio();
  var ApiKey = "AIzaSyC82yHplmDt-JGwazkcILZkcF0VEbhP7bg";

  var bus_location_url =
      "https://smart-bus-iot-42439-default-rtdb.firebaseio.com/Bus%20Detail/Location%20Coordinates.json";
  var bus_capacity_url =
      "https://smart-bus-iot-42439-default-rtdb.firebaseio.com/Bus%20Detail/Seat%20Count.json";

  var total_capacity = "50";
  var live_capacity = "50";
  var live_index = -1;

  late Marker bus_marker =
      Marker(markerId: MarkerId(Paths().BusDetails['bus_name'].toString()));
  var markers = {};

  var selected_bus = -1;

  void update_arrival_time() async {
    try {
      for (var bus in Paths().Buses) {
        // var dist = await calculateDistance(bus['current_lat'], bus['current_long'], Paths().POSITION.latitude, Paths().POSITION.longitude);
        var dist = Geolocator.distanceBetween(
            bus['current_lat'],
            bus['current_long'],
            Paths().POSITION.latitude,
            Paths().POSITION.longitude);
        bus['arrival_time'] = ((dist / 1000)).toStringAsFixed(2) + "Mins";
        log("Distance : ${dist.toString()}m, Arrival time : ${bus['arrival_time'].toString()}");
      }
    } on Exception catch (error) {
      Fluttertoast.showToast(msg: "Update Arrival Time error");
      log("Update Arrival Time error : " + error.toString());
    }
  }

  void get_buses() async {
    try {
      var response = await dio.get(Paths().BASE_URL + "get_buses");
      log("buses : " + response.data.toString());
      if (response.statusCode == 200) {
        var data = json.decode(response.data);
        if (data['result'].isEmpty) {
          Fluttertoast.showToast(msg: "Invalid user details");
        } else {
          log("Reached Here");
          get_reaching_time();
          setState(() {
            Paths().Buses = data['result'];
            update_arrival_time();
            var temp_buses = [];
            for (var bus in Paths().Buses) {
              if (bus['stops'].contains(Paths().Destination)) {
                temp_buses.add(bus);
              }
            }
            buses = temp_buses;
          });
        }
      } else {
        Fluttertoast.showToast(
            msg: "Some error occured. Please check server connection");
      }
    } on Exception catch (error) {
      Fluttertoast.showToast(msg: "Error occured. Error : " + error.toString());
    }
  }

  void get_reaching_time() async {
    var geocoding_url =
        "https://maps.googleapis.com/maps/api/geocode/json?address=${Paths().Destination}&key=$ApiKey";
    try {
      var response = await dio.get(geocoding_url);
      log("Geocoded Response : " + response.data.toString());
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data.toString().isNotEmpty) {
        log("Geocoded position : " +
            response.data['results'][0]['geometry']['location'].toString());
        setState(() {
          var dest_loc = response.data['results'][0]['geometry']['location'];
          for (var bus in buses) {
            live_index = 0;
            var dist = Geolocator.distanceBetween(Paths().POSITION.latitude,
                Paths().POSITION.longitude, dest_loc['lat'], dest_loc['lng']);
            bus['reaching_time'] =
                (((dist / 1000) / 40) * 60).toStringAsFixed(3);
            // calculateDistance(Paths().Buses[live_index]['current_lat'], Paths().Buses[live_index]['current_long'], dest_loc['lat'], dest_loc['lng']).then((value) =>
            // {bus['reaching_time'] = value/40});
          }
        });
      }
    } on Exception catch (error) {
      log("Geocoding error : " + error.toString());
    }
  }

  void get_bus_location() async {
    try {
      var response = await dio.get(bus_location_url);
      //log("Bus Location : " + response.data.toString());
      if (response.statusCode == 200) {
        double dist = await calculateDistance(
            response.data['Latitude'],
            response.data['Longitude'],
            Paths().POSITION.latitude,
            Paths().POSITION.latitude);
        setState(() {
          if (live_index != -1) {
            Paths().Buses[live_index]['current_lat'] =
                response.data['latitude'];
            Paths().Buses[live_index]['current_long'] =
                response.data['longitude'];
            Paths().BUS_POSITION =
                LatLng(response.data['latitude'], response.data['longitude']);
            markers[live_index] = Marker(
                markerId: MarkerId("Bus tracker"),
                position: LatLng(
                    response.data['Latitude'], response.data['Longitude']));
          }
          get_reaching_time();
          bus_marker = Marker(
              markerId: MarkerId("Bus tracker"),
              position:
                  LatLng(response.data['Latitude'], response.data['Longitude']),
              infoWindow: InfoWindow(
                title: "Live Bus (${live_capacity}/${total_capacity})",
                snippet: "Arrival in " + (dist / 60).toString(),
              ));
        });
      } else {
        Fluttertoast.showToast(msg: "Could not fetch live location...");
      }
    } on DioError catch (error) {
      // log("Bus Location error : " + error.toString());
      Fluttertoast.showToast(
          msg: "Some error occured. Please check firebase url");
    }
  }

  void book_bus_clicked() {
    if (selected_bus != -1) {
      Paths().BusDetails = buses[selected_bus];
      Navigator.pushNamed(context, Paths().BookBus);
    }
  }

  void back_pressed() {
    Navigator.popAndPushNamed(context, Paths().Home);
  }

  void start_timer() {
    timer = Timer(Duration(seconds: 5), get_buses);
  }

  Future<double> calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) async {
    try {
      double distanceInMeters = await Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );

      // Convert meters to kilometers
      double distanceInKilometers = distanceInMeters / 1000;

      return distanceInKilometers;
    } on Exception catch (error) {
      Fluttertoast.showToast(msg: "Distance Calculation Error");
      log("Distance Calculation Error : " + error.toString());
    }
    return 0;
  }

  @override
  void initState() {
    get_buses();
    get_reaching_time();
    start_timer();
  }

  @override
  void dispose() {
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
              leading: IconButton(
                  onPressed: back_pressed, icon: Icon(Icons.arrow_back)),
              title: Text("Buses to " + Paths().Destination)),
          body: Container(
            padding: EdgeInsets.all(15),
            height: MediaQuery.of(context).size.height,
            color: Colors.green.shade200,
            child: buses.isNotEmpty
                ? ListView.builder(
                    itemCount: buses.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 6,
                        ),
                        child: Container(
                          child: ElevatedButton(
                            onPressed: () {
                              get_reaching_time();
                              setState(() {
                                selected_bus = index;
                              });
                              book_bus_clicked();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      buses[index]['bus_name']
                                          .toString()
                                          .trim(),
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      width: 15,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(buses[index]['reg_no'].toString()),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text("Arrival time : " +
                                            buses[index]['arrival_time']
                                                .toString()),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text("Reaching time : " +
                                            buses[index]['reaching_time']
                                                .toString() +
                                            " min")
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: selected_bus == index
                                    ? Colors.blue
                                    : Colors.white,
                                foregroundColor: selected_bus == index
                                    ? Colors.white
                                    : Colors.black,
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                )),
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      "No buses available to that destination....",
                      // "dest: "+Paths().Buses[0]['stops'].contains(Paths().Destination).toString(),
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
          // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          // floatingActionButton: Container(
          //   padding: EdgeInsets.symmetric(
          //       vertical: 10
          //   ),
          //   child: ElevatedButton(
          //     onPressed: book_bus_clicked,
          //     child: Text("Book Bus"),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: selected_bus>=0?Colors.blue:Colors.grey.shade500,
          //       foregroundColor: Colors.white
          //     ),
          //   ),
          // ),
        ),
        onWillPop: () async {
          back_pressed();
          return false;
        });
  }
}
