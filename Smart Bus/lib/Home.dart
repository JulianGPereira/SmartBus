import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smartbus/HomeFragment.dart';
import 'package:smartbus/Paths.dart';
import 'package:smartbus/ProfileFragment.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  var current_page = 0;
  var dio = Dio();

  void logout() {
    Navigator.popAndPushNamed(context, Paths().Login);
  }

  Widget get_body() {
    if(current_page==0) {
      return HomeFragment();
    }
    else {
      return ProfileFragment();
    }
  }

  void get_buses() async {
    try {
      var response = await dio.get(Paths().BASE_URL+"get_buses");
      if(response.statusCode==200) {
        var data = json.decode(response.data);
        if(data['result'].isEmpty) {
          Fluttertoast.showToast(msg: "Invalid user details");
        }
        else {
          setState(() {
            Paths().Buses = data;
          });
        }
      }
      else {
        Fluttertoast.showToast(msg: "Some error occured. Please check server connection");
      }
    } on DioError catch(error) {
      Fluttertoast.showToast(msg:"Some error occured. Please check server connection");
    }
  }

  void bottom_navigation_item_clicked(int index) {
    setState(() {
      current_page = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          ElevatedButton(
            onPressed: logout,
            child: Text("Logout")
          ),
        ],
      ),
      body: get_body(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: bottom_navigation_item_clicked,
        currentIndex: current_page,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled),label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person_2_rounded),label: "Profile"),
        ],
      ),
    );
  }
}
