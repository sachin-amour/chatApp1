import 'dart:io';
import 'package:feelings/screen/ui%20helper/custom_textFormField.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../model/const/consts.dart';
import '../model/userProfile.dart';
import '../services/alart_service.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';
import '../services/media_service.dart';
import '../services/navigation_service.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _signupFromKey = GlobalKey();
  final GetIt getIt = GetIt.instance;
  late NavigattionService _navigationService;
  late MediaService _mediaService;
  late Authservice _authservice;
  late CloudinaryStorageService _cloudinaryStorageService;
  late FirestoreService _firestoreService;
  late AlertService _alertService;
  bool isloading = false;

  String? email;
  String? name;
  String? password;

  File? selectedImage;

  @override
  void initState() {
    super.initState();
    _mediaService = getIt.get<MediaService>();
    _navigationService = getIt.get<NavigattionService>();
    _authservice = getIt.get<Authservice>();
    _cloudinaryStorageService = getIt.get<CloudinaryStorageService>();
    _firestoreService = getIt.get<FirestoreService>();
    _alertService = getIt.get<AlertService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                child: Column(
                  children: [
                    _header(),
                    SizedBox(height: 30),
                    if (!isloading) _signupForm(),
                    if (!isloading) _login(),
                    if (isloading)
                      Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.teal.shade400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * -0.04,
              right: MediaQuery.of(context).size.width * -0.03,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.55,
                height: MediaQuery.of(context).size.width * 0.55,
                child: Image.asset('assets/images/chatbobles.png'),
              ),
            ),
          ],
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
            "Let's get started!",
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Register below with your details",
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

  Widget _signupForm() {
    return Form(
      key: _signupFromKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _profileImg(),
          SizedBox(height: 24),
          customTextField(
            hintText: "Name",
            height: 70,
            validationRegEx: NAME_VALIDATION_REGEX,
            onSaved: (value) {
              setState(() {
                name = value;
              });
            },
          ),
          SizedBox(height: 16),
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
          _signUpBtn(),
        ],
      ),
    );
  }

  Widget _profileImg() {
    return GestureDetector(
      onTap: () async {
        File? image = await _mediaService.getImageFormGallery();
        if (image != null) {
          setState(() {
            selectedImage = image;
          });
        }
      },
      child: Stack(
        children: [
          CircleAvatar(
            radius: MediaQuery.of(context).size.width * 0.15,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: selectedImage != null
                ? FileImage(selectedImage!)
                : NetworkImage(PLACEHOLDER_PFP) as ImageProvider,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signUpBtn() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 54,
      child: MaterialButton(
        elevation: 0,
        color: Colors.teal.shade400,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onPressed: () async {
          setState(() {
            isloading = true;
          });
          try {
            if ((_signupFromKey.currentState?.validate() ?? false) &&
                selectedImage != null) {
              _signupFromKey.currentState?.save();
              bool result = await _authservice.signup(email!, password!);
              if (result) {
                String? pfpURL = await _cloudinaryStorageService.uploadUserPfp(
                  file: selectedImage!,
                  uid: _authservice.user!.uid,
                );
                if (pfpURL != null) {
                  await _firestoreService.creatUserProfile(
                    userProfile: UserProfile(
                      uid: _authservice.user!.uid,
                      name: name!,
                      pfpURL: pfpURL,
                      email: email!,
                    ),
                  );
                  _alertService.showToast(
                    message: "User registered successfully!",
                    icon: Icons.check,
                  );

                  _navigationService.goBack();
                  _navigationService.pushReplacementNamed("/home");
                } else {
                  throw Exception("Unable to upload profile picture");
                }
              } else {
                throw Exception("Unable to register user");
              }
            } else {
              _alertService.showToast(
                message: "Please select a profile picture",
                icon: Icons.error,
              );
            }
          } catch (e) {
            print(e);
            _alertService.showToast(
              message: "Failed to register, please try again",
              icon: Icons.error,
            );
          }
          setState(() {
            isloading = false;
          });
        },
        child: Text(
          "Sign Up",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _login() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account? ",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          TextButton(
            onPressed: () {
              _navigationService.goBack();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "Login",
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