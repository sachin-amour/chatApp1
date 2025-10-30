import 'package:feelings/screen/ui%20helper/custom_textFormField.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../model/const/consts.dart';
import '../services/alart_service.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';

class logInScreen extends StatefulWidget {
  @override
  State<logInScreen> createState() => _logInScreenState();
}

class _logInScreenState extends State<logInScreen> {
  final GetIt _getIt = GetIt.instance;
  final GlobalKey<FormState> _loginFromKey = GlobalKey();
  late NavigattionService _navigationService;
  late Authservice _authservice;
  late AlertService _alertService;
  String? email, password;

  @override
  void initState() {
    super.initState();
    _authservice = _getIt.get<Authservice>();
    _navigationService = _getIt.get<NavigattionService>();
    _alertService = _getIt.get<AlertService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            child: Column(
              children: [
                _header(),
                SizedBox(height: 30),
                Container(
                  height: 180,
                  width: 180,
                  child: Image.asset("assets/images/login.png"),
                ),
                SizedBox(height: 20),
                _loginForm(),
                _signUp(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "Hi, Welcome back!",
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Hello again, you've been missed!",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginForm() {
    return Form(
      key: _loginFromKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          customTextField(
            hintText: "Email",
            height: 70,
            validationRegEx: EMAIL_VALIDATION_REGEX,
            onSaved: (value) {
              setState(() {
                email = value;
              });
            },
          ),
          SizedBox(height: 16),
          customTextField(
            hintText: "Password",
            height: 70,
            validationRegEx: PASSWORD_VALIDATION_REGEX,
            obscureText: true,
            onSaved: (value) {
              setState(() {
                password = value;
              });
            },
          ),
          SizedBox(height: 24),
          _loginBtn(),
        ],
      ),
    );
  }

  Widget _loginBtn() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 54,
      child: MaterialButton(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onPressed: () async {
          if (_loginFromKey.currentState?.validate() ?? false) {
            _loginFromKey.currentState?.save();
            bool result = await _authservice.login(email!, password!);
            if (result) {
              _navigationService.pushReplacementNamed("/home");
            } else {
              _alertService.showToast(
                message: "Invalid email or password",
                icon: Icons.error,
              );
            }
          }
        },
        child: Text(
          "Login",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        color: Colors.teal.shade400,
      ),
    );
  }

  Widget _signUp() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          TextButton(
            onPressed: () {
              _navigationService.pushNamed("/signup");
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "Sign Up",
              style: TextStyle(
                color: Colors.teal.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}