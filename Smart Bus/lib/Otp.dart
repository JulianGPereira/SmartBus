import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smartbus/Paths.dart';

class Otp extends StatefulWidget {
  const Otp({Key? key}) : super(key: key);

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> {

  TextEditingController otp_controller = TextEditingController();
  var otp_error = null;

  void on_submit() {
    if(otp_error==null && otp_controller.text.length==4) {
      Navigator.popAndPushNamed(context, Paths().Home);
    }
  }


  @override
  void initState() {
    Fluttertoast.showToast(msg: "Otp : "+Paths().Otp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Otp"),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.all(15),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                controller: otp_controller,
                maxLength: 4,
                onChanged: (value) {
                  if(value!=Paths().OTP_VALUE) {
                    setState(() {
                      otp_error = "Invalid Otp";
                    });
                  }
                  else {
                    setState(() {
                      otp_error = null;
                    });
                  }
                },
                decoration: InputDecoration(
                    suffixText: otp_controller.text.length.toString()+"/4",
                    errorText: otp_error
                ),
              ),
              SizedBox(height: 20,),
              ElevatedButton(
                onPressed: on_submit,
                child: Text("Login")
              ),
            ],
          ),
        ),
      ),
    );
  }
}
