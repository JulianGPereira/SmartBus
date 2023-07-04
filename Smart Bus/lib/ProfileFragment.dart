import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smartbus/Paths.dart';

class ProfileFragment extends StatefulWidget {
  const ProfileFragment({Key? key}) : super(key: key);

  @override
  State<ProfileFragment> createState() => _ProfileFragmentState();
}

class _ProfileFragmentState extends State<ProfileFragment> {

  var name_controller = TextEditingController();
  var phone_controller = TextEditingController();
  var email_controller = TextEditingController();

  var name_error = null;
  var email_error = null;
  var phone_error = null;

  var valid = false;
  var dio = Dio();

  void validate() {
    setState(() {
      if(name_controller.text.isEmpty) {
        name_error = "Name cannot be empty";
      }
      else {
        name_error = null;
      }

      if(email_controller.text.isEmpty) {
        email_error = "Email cannot be empty";
      }
      else {
        email_error = null;
      }

      if(phone_controller.text.isEmpty) {
        phone_error = "Phone number cannot be empty";
      }
      else {
        if(phone_controller.text.trim().length!=0) {
          phone_error = "Invalid Phone Number";
        }
        else {
          phone_error = null;
        }
      }
    });
  }

  void image_clicked() async {}

  void submit() async {
    try {
      var request = {
        "name": name_controller.text.trim(),
        "email": email_controller.text.trim(),
        "mobile": phone_controller.text.trim()
      };
      var response = await dio.post(Paths().BASE_URL+"update_user",data: request);
      if(response.statusCode==200) {
        if(response.data.toString().toLowerCase().contains("failed")) {
          Fluttertoast.showToast(msg: "Invalid user details");
        }
        else {
          setState(() {
            Paths().Profile['name'] = name_controller.text.trim();
            Paths().Profile['mobile'] = phone_controller.text.trim();
            Paths().Profile['email'] = email_controller.text.trim();
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

  void get_profile() {
    setState(() {
      name_controller.text = Paths().Profile['name'].toString();
      email_controller.text = Paths().Profile['email'].toString();
      phone_controller.text = Paths().Profile['mobile'].toString();
    });
  }

  @override
  void initState() {
    get_profile();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      height: MediaQuery.of(context).size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.width/3,
            width: MediaQuery.of(context).size.width/3,
            child: ElevatedButton(
              onPressed: image_clicked,
              child: Image.network("src"),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Colors.grey,
                    width: 2
                  )
                )
              ),
            ),
          ), //for image
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 5
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1
              ),
              borderRadius: BorderRadius.circular(10)
            ),
            child: TextField(
              controller: name_controller,
              onChanged: (_) {
                validate();
              },
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                  labelText: "Full Name",
                  hintText: "Enter your full name",
                  errorText: name_error,
                  border: InputBorder.none
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 5
            ),
            decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.grey,
                    width: 1
                ),
                borderRadius: BorderRadius.circular(10)
            ),
            child: TextField(
              controller: email_controller,
              onChanged: (_) {
                validate();
              },
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  labelText: "Email ID",
                  hintText: "Enter your email id",
                  errorText: email_error,
                  border: InputBorder.none
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 5
            ),
            decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.grey,
                    width: 1
                ),
                borderRadius: BorderRadius.circular(10)
            ),
            child: TextField(
              controller: phone_controller,
              onChanged: (_) {
                validate();
              },
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  labelText: "Phone Number",
                  hintText: "Enter your phone number",
                  errorText: phone_error,
                  border: InputBorder.none
              ),
            ),
          ),

          ElevatedButton(
            onPressed: submit,
            child: Text("Save")
          )
        ],
      ),
    );
  }
}
