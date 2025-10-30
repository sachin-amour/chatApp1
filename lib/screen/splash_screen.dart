
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/wrapper_service.dart';

class splashScreen extends StatefulWidget {
  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> {
  late Size mQuery;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 2000), () {
      setState(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Wrapper()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    mQuery = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: mQuery.height * .3,
                    right: mQuery.width * .25,
                    width: mQuery.width * .5,
                    child: Image.asset("assets/images/login.png"),
                  ),
                  Positioned(
                    top: mQuery.height * .78,
                    left: mQuery.width * .25,
                    width: mQuery.width * .5,
                    child: Text(
                      "❤️ from Amour",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 22,
                        fontFamily: 'sFonts',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
