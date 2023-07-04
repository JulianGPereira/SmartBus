class Paths {
  static final Paths _instance = Paths.init();
  Paths.init() {}
  factory Paths() {
    return _instance;
  }

  var Login = "/login";
  var Otp = "/Otp";
  var Home = "/Home";
  var BusesList = "/BusesList";
  var BookBus = "/BookBus";
  var Signup = "/Signup";

  var BusDetails = {};
  var Location = "";
  var Destination = "";
  var Profile = {};
  var Buses = [];
  var OTP_VALUE = "999";
  var POSITION;
  var CAMERA;
  var Latitude;
  var Longitude;
  var BUS_POSITION;

  var API_RAZOR_PAY_KEY = "rzp_test_x7BlpeFAGJyg5m";

  var BASE_URL = "http://192.168.1.8:5000/";
}
