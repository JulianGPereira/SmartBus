import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smartbus/Paths.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  var name_controller = TextEditingController();
  var email_controller = TextEditingController();
  var mobile_controller = TextEditingController();

  var phone_error = null;
  var name_error = null;
  var email_error = null;

  var dio = Dio();

  void signup() async {
    if(name_error==null && email_error==null && phone_error==null) {
      var request = {
        "name": name_controller.text.toString(),
        "mobile": mobile_controller.text.toString(),
        "email": email_controller.text.toString()
      };
      try {
        var response = await dio.post(Paths().BASE_URL+"create_user", data: request);
        if(response.statusCode==200) {
          Fluttertoast.showToast(msg: "User created succesfully");
          Navigator.pop(context);
        }
        else {
          Fluttertoast.showToast(msg: "Some error occured. Please check server connection");
        }
      } on DioError catch(error) {
        Fluttertoast.showToast(msg: "Some error occured. Please check server connection");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("Signup"),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width/2,
                height: MediaQuery.of(context).size.width/2,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width/2),
                    color: Colors.grey.withOpacity(0.4)
                ),
              ),
              SizedBox(height: 50,),

              TextField(
                keyboardType: TextInputType.number,
                controller: mobile_controller,
                onChanged: (value) {
                  if(value.length!=10) {
                    setState(() {
                      phone_error = "Invalid Phone Number";
                    });
                  }
                  else {
                    setState(() {
                      phone_error = null;
                    });
                  }
                },
                decoration: InputDecoration(
                    label: Text("Mobile"),
                    suffixText: mobile_controller.text.length.toString()+"/10",
                    errorText: phone_error,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    )
                ),
              ),
              SizedBox(height: 50,),

              TextField(
                controller: name_controller,
                onChanged: (value) {
                  if(value.length<1) {
                    setState(() {
                      name_error = "Name cannot be empty";
                    });
                  }
                  else {
                    setState(() {
                      name_error = null;
                    });
                  }
                },
                decoration: InputDecoration(
                    label: Text("Name"),
                    errorText: name_error,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    )
                ),
              ),
              SizedBox(height: 50,),

              TextField(
                controller: email_controller,
                onChanged: (value) {
                  if(value.length<1) {
                    setState(() {
                      email_error = "Email cannot be empty";
                    });
                  }
                  else {
                    setState(() {
                      email_error = null;
                    });
                  }
                },
                decoration: InputDecoration(
                    label: Text("Email Id"),
                    errorText: email_error,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    )
                ),
              ),
              SizedBox(height: 50,),

              ElevatedButton(
                  onPressed: signup,
                  child: Text("Signup")
              ),
            ],
          ),
        ),
      ),
    );
  }
}
