import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartbus/Paths.dart';
import 'package:smartbus/main.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController phone_controller = TextEditingController();
  TextEditingController otp_controller = TextEditingController();
  TextEditingController url_controller = TextEditingController();
  var phone_validated = false;
  var phone_error = null;
  var otp_error = null;
  var recieved_otp = "999";
  var url_error = null;
  var dio = Dio();

  void get_otp() async {
    if (phone_error == null) {
      try {
        var response = await dio.post(Paths().BASE_URL + "get_otp",
            data: {"mobile": phone_controller.text.trim()});
        if (response.statusCode == 200) {
          if (response.data.toString() != recieved_otp) {
            setState(() {
              recieved_otp = response.data.toString();
              log("Otp : " + response.data.toString());
              Paths().OTP_VALUE = response.data.toString();
              Fluttertoast.showToast(msg: "Otp : " + response.data.toString());
              // flutterLocalNotificationsPlugin.show(int.parse(response.data.toString()), "Otp", response.data.toString(), NotificationDetails(
              //     android: AndroidNotificationDetails(
              //       androidNotificationChannel.id,
              //       androidNotificationChannel.name,
              //       channelDescription: androidNotificationChannel.description,
              //       showWhen: true,
              //     ),
              //     iOS: iosNotificationChannel
              // ));
              phone_validated = true;
            });
          } else {
            Fluttertoast.showToast(msg: "Invalid user details");
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
  }

  void login() async {
    if (otp_controller.text.trim() == recieved_otp && otp_error == null) {
      try {
        var response = await dio.get(Paths().BASE_URL + "get_user",
            data: {"mobile": phone_controller.text.trim()});
        if (response.statusCode == 200) {
          log("profile response : " + response.data.toString());
          if (response.data.toString().isNotEmpty) {
            get_my_location();
            setState(() {
              Paths().Profile = json.decode(response.data);
              otp_error = null;
            });
            Navigator.popAndPushNamed(context, Paths().Home);
          } else {
            Fluttertoast.showToast(msg: "Invalid user details");
          }
        } else {
          Fluttertoast.showToast(
              msg: "Some error occured. Please check server connection");
        }
      } on DioError catch (error) {
        Fluttertoast.showToast(
            msg: "Some error occured. Please check server connection");
      }
    } else {
      otp_error = "Invalid Otp";
    }
  }

  void url_set(var value) {
    setState(() {
      if (value.trim().isEmpty) {
        url_error = "Url must be specified";
      } else {
        url_error = null;
        Paths().BASE_URL = value.trim();
      }
    });
  }

  void get_my_location() async {
    var stats = await Geolocator.checkPermission();
    if (mounted) {
      if (stats == LocationPermission.always ||
          stats == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition();
        // log("Login response : " + position.toString());
        if (mounted) {
          setState(() {
            Paths().POSITION = position;
            Paths().Latitude = position.latitude;
            Paths().Longitude = position.longitude;
          });
        }
      } else {
        await Geolocator.requestPermission();
        var updatedStats = await Geolocator.checkPermission();
        if (mounted &&
            (updatedStats == LocationPermission.always ||
                updatedStats == LocationPermission.whileInUse)) {
          get_my_location(); // Recursive call after permission is granted and widget is still mounted.
        }
      }
    }
  }

  @override
  void initState() {
    setState(() {
      url_controller.text = Paths().BASE_URL;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(15),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width / 2,
                  height: MediaQuery.of(context).size.width / 2,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width / 2),
                      color: Colors.grey.withOpacity(0.4)),
                ),
                SizedBox(
                  height: 50,
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: phone_controller,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                  ],
                  onChanged: (value) {
                    if (value.length != 10) {
                      setState(() {
                        phone_error = "Invalid Phone Number";
                      });
                    } else {
                      setState(() {
                        phone_error = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    suffixText: phone_controller.text.length.toString() + "/10",
                    errorText: phone_error,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300, width: 1)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300, width: 1)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.red, width: 1)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.red, width: 1)),
                  ),
                ),
                SizedBox(
                  height: 50,
                ),
                phone_validated
                    ? TextField(
                        keyboardType: TextInputType.number,
                        controller: otp_controller,
                        onChanged: (value) {
                          if (value.length != 4 && value != recieved_otp) {
                            setState(() {
                              otp_error = "Invalid OTP";
                            });
                          } else {
                            setState(() {
                              otp_error = null;
                            });
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                        ],
                        style: TextStyle(
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          enabled: true,
                          suffixText:
                              otp_controller.text.length.toString() + "/4",
                          errorText: otp_error,
                          hintText: "Otp",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1)),
                          errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide:
                                  BorderSide(color: Colors.red, width: 1)),
                          focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide:
                                  BorderSide(color: Colors.red, width: 1)),
                        ),
                      )
                    : SizedBox(),
                SizedBox(
                  height: phone_validated ? 50 : 0,
                ),
                ElevatedButton(
                    onPressed: () {
                      if (!phone_validated) {
                        get_otp();
                      } else {
                        login();
                      }
                    },
                    child: Text(phone_validated ? "Login" : "Get Otp")),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Paths().Signup);
                    },
                    child: Text("Signup")),
                SizedBox(
                  height: 50,
                ),
                TextField(
                  controller: url_controller,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[htps 0-9 :./]'))
                  ],
                  onChanged: url_set,
                  decoration: InputDecoration(
                      label: Text("Server Url"),
                      errorText: url_error,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
