import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:smartbus/Paths.dart';

class BusDetails extends StatefulWidget {
  const BusDetails({Key? key}) : super(key: key);

  @override
  State<BusDetails> createState() => _BusDetailsState();
}

class _BusDetailsState extends State<BusDetails> {
  CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: Paths().BUS_POSITION == null
          ? LatLng(
              Paths().POSITION != null ? Paths().POSITION.latitude : 9.3814395,
              Paths().POSITION != null ? Paths().POSITION.longitude : 76.556662)
          : Paths().BUS_POSITION,
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);
  CameraPosition _kGooglePlex = CameraPosition(
    target: Paths().BUS_POSITION == null
        ? LatLng(
            Paths().POSITION != null ? Paths().POSITION.latitude : 9.3814395,
            Paths().POSITION != null ? Paths().POSITION.longitude : 76.556662)
        : Paths().BUS_POSITION,
    zoom: 14.4746,
  );
  Marker self_marker = Marker(
    markerId: MarkerId("Self tracker"),
    position: LatLng(
        Paths().POSITION != null ? Paths().POSITION.latitude : 9.3814395,
        Paths().POSITION != null ? Paths().POSITION.longitude : 76.556662),
  );
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  var bus_location_url =
      "https://smart-bus-iot-42439-default-rtdb.firebaseio.com/Bus%20Detail/Location%20Coordinates.json";
  var bus_capacity_url =
      "https://smart-bus-iot-42439-default-rtdb.firebaseio.com/Bus%20Detail/Seat%20Count.json";

  var total_capacity = "50";
  var live_capacity = "00";
  var live_index = -1;

  Marker bus_marker = Marker(
      markerId: MarkerId(Paths().BusDetails['bus_name'].toString()),
      position: Paths().BUS_POSITION == null
          ? LatLng(
              Paths().POSITION != null ? Paths().POSITION.latitude : 9.3814395,
              Paths().POSITION != null ? Paths().POSITION.longitude : 76.556662)
          : Paths().BUS_POSITION);

  CameraPosition _kBus = CameraPosition(
      bearing: 192.8334901395799,
      target: Paths().BUS_POSITION == null
          ? LatLng(
              Paths().BUS_POSITION != null
                  ? Paths().POSITION.latitude
                  : 9.3814395,
              Paths().BUS_POSITION != null
                  ? Paths().POSITION.longitude
                  : 76.556662)
          : Paths().BUS_POSITION,
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  var markers = {};

  var bus_details = Paths().BusDetails;
  var bus_booked = false;
  var dio = Dio();
  var loading = false;
  var timer;
  var _razorpay = Razorpay();

  void back_pressed() {
    Navigator.pop(context);
  }

  void book_bus_clicked() async {
    var request = {
      "driver_mobile": bus_details['driver_mobile'].toString(),
      "bus_name": bus_details['bus_name'].toString(),
      "designation": bus_details['designation'].toString(),
      "reg_no": bus_details['reg_no'].toString(),
      "arrival_time": bus_details['arrival_time'].toString(),
      "reaching_time": bus_details['reaching_time'].toString(),
      "booked_user_count": bus_details['booked_user_count'] + 1,
      "current_lat": bus_details['current_lat'].toString(),
      "current_long": bus_details['current_long'].toString(),
      "stops": bus_details['stops'].toString()
    };
    setState(() {
      loading = true;
    });
    try {
      var response =
          await dio.get(Paths().BASE_URL + "get_buses", data: request);
      if (response.statusCode == 200) {
        if (response.data.toString().toLowerCase().contains("fail")) {
          Fluttertoast.showToast(msg: "Invalid bus details");
        } else {
          var options_pay = {
            'key': Paths().API_RAZOR_PAY_KEY.toString(),
            'amount': bus_details['amount'].toString(),
            'name': 'Smart Bus Booking',
            'order_id': "test order 1234",
            'description': "test order description",
            'timeout': 90,
            'prefill': {
              'contact': Paths().Profile['mobile'].toString(),
              'email': Paths().Profile['email'].toString()
            }
          };
          Fluttertoast.showToast(msg: "Booking initiated....");
          _razorpay.open(options_pay);
        }
      } else {
        Fluttertoast.showToast(
            msg: "Some error occured. Please check server connection");
      }
    } on DioError catch (error) {
      setState(() {
        loading = false;
      });
      Fluttertoast.showToast(
          msg: "Some error occured. Please check server connection");
    }
  }

  void get_reaching_time() async {}

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

  void start_timer() {
    timer = Timer(Duration(seconds: 5), () {
      get_bus_location();
      get_bus_capacity();
    });
  }

  Future<void> show_location() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  void get_bus_location() async {
    try {
      var response = await dio.get(bus_location_url);
      log("Bus Location : " + response.data.toString());
      if (response.statusCode == 200) {
        double dist = await calculateDistance(
            response.data['Latitude'],
            response.data['Longitude'],
            Paths().POSITION.latitude,
            Paths().POSITION.longitude);
        log("Coordates" + response.data.toString());
        log("Distance " + dist.toString());
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
          bus_marker = Marker(
              markerId: MarkerId("Bus tracker"),
              position:
                  LatLng(response.data['Latitude'], response.data['Longitude']),
              infoWindow: InfoWindow(
                title: "Live Bus (${live_capacity}/${total_capacity})",
                snippet: "Arrival in " + (dist / 40).toStringAsFixed(3),
              ));
          _kLake = CameraPosition(
              bearing: 192.8334901395799,
              target: Paths().BUS_POSITION == null
                  ? LatLng(
                      Paths().POSITION != null
                          ? Paths().POSITION.latitude
                          : 9.3814395,
                      Paths().POSITION != null
                          ? Paths().POSITION.longitude
                          : 76.556662)
                  : Paths().BUS_POSITION,
              tilt: 59.440717697143555,
              zoom: 19.151926040649414);
          _kGooglePlex = CameraPosition(
            target: Paths().BUS_POSITION == null
                ? LatLng(
                    Paths().POSITION != null
                        ? Paths().POSITION.latitude
                        : 9.3814395,
                    Paths().POSITION != null
                        ? Paths().POSITION.longitude
                        : 76.556662)
                : Paths().BUS_POSITION,
            zoom: 14.4746,
          );
        });
      } else {
        Fluttertoast.showToast(msg: "Could not fetch live location...");
      }
    } on DioError catch (error) {
      log("Bus Location error : " + error.toString());
      Fluttertoast.showToast(
          msg: "Some error occured. Please check firebase url");
    }
  }

  void get_bus_capacity() async {
    try {
      var response = await dio.get(bus_capacity_url);
      double dist = await calculateDistance(
          bus_marker.position.latitude,
          bus_marker.position.longitude,
          Paths().POSITION.latitude,
          Paths().POSITION.longitude);
      if (response.statusCode == 200) {
        setState(() {
          live_capacity = response.data.toString();
          bus_marker = Marker(
            markerId: bus_marker.markerId,
            position: bus_marker.position,
            infoWindow: InfoWindow(
              title: "Live Bus (${live_capacity.toString()}/${total_capacity})",
              snippet: "Arrival in " + (dist / 40).toStringAsFixed(3),
            ),
          );
        });
      } else {
        Fluttertoast.showToast(msg: "Unable to fetch capacity");
      }
    } on DioError catch (error) {
      Fluttertoast.showToast(
          msg: "Some error occured. Please check your firebase_url");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Do something when payment succeeds
    setState(() {
      bus_booked = true;
      loading = false;
    });
    Fluttertoast.showToast(msg: "Bus Booked");
    log("Payment Success order id : " + response.orderId.toString());
    log("Payment Success payment id : " + response.paymentId.toString());
    log("Payment Success signature : " + response.signature.toString());
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    // Do something when payment fails
    setState(() {
      loading = false;
    });
    log("Payment Failure : " + response.toString());
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Do something when an external wallet was selected
  }

  @override
  void initState() {
    get_bus_location();
    start_timer();
    get_reaching_time();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          body: RefreshIndicator(
              child: Container(
                padding: EdgeInsets.all(15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Location : " + Paths().Location),
                    SizedBox(
                      height: 20,
                    ),
                    Text("Destination : " + Paths().Destination),
                    SizedBox(
                      height: 50,
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height / 2,
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
                      // child: GoogleMap(),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Text("Bus name : " + bus_details['bus_name'].toString()),
                    SizedBox(
                      height: 20,
                    ),
                    Text("Current Capacity : " + live_capacity.toString()),
                    SizedBox(
                      height: 20,
                    ),
                    Text("Arrival time : " +
                        bus_details['arrival_time'].toString()),
                    SizedBox(
                      height: 20,
                    ),
                    Text("Reach Destination : " +
                        bus_details['reaching_time'].toString()),
                    SizedBox(
                      height: 20,
                    ),
                    loading
                        ? CircularProgressIndicator()
                        : bus_booked
                            ? Container(
                                decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                        color: Colors.green.shade800)),
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                                child: Text(
                                  "Bus Booked",
                                  style:
                                      TextStyle(color: Colors.green.shade800),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: book_bus_clicked,
                                child: Text("Book Bus"))
                  ],
                ),
              ),
              onRefresh: () async {
                get_bus_capacity();
              }),
        ),
        onWillPop: () async {
          back_pressed();
          return false;
        });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }
}
