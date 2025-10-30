import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/alart_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/navigation_service.dart';
import '../../model/userProfile.dart';
import '../profile_screen.dart';
import 'aboutus.dart';
import 'contactus.dart';

class slidler extends StatefulWidget {
  @override
  State<slidler> createState() => _slidlerState();
}

class _slidlerState extends State<slidler> {
  final GetIt _getIt = GetIt.instance;
  late NavigattionService _navigationService;
  late AlertService _alertService;
  late Authservice _authservice;
  late FirestoreService _firestoreService;

  // Share App Details
  final String appLink = "https://play.google.com/store/apps/details?id=com.yourapp.id";
  final String shareMessage = "Check out this awesome app! You can download it here:";

  @override
  void initState() {
    super.initState();
    _navigationService = _getIt.get<NavigattionService>();
    _alertService = _getIt.get<AlertService>();
    _authservice = _getIt.get<Authservice>();
    _firestoreService = _getIt.get<FirestoreService>();
  }

  // Smooth page transition helper
  Route _createSmoothRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeIn),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.pop(context); // Close drawer first
    Future.delayed(const Duration(milliseconds: 80), () {
      Navigator.of(context).push(_createSmoothRoute(screen));
    });
  }

  // Function to handle the actual sharing
  void _shareApp() {
    final String text = "$shareMessage\n$appLink";
    Navigator.pop(context);
    Share.share(text, subject: 'App Recommendation');
  }

  // Function to show the Share Dialog Popup
  void _showShareDialog() {
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Share This App'),
          content: const Text(
              'Help us grow by sharing this useful application with your friends and family!',
              style: TextStyle(fontSize: 16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareApp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text('Share', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool result = await _authservice.logout();
              if (result) {
                _alertService.showToast(message: "Logged out successfully");
                _navigationService.pushReplacementNamed("/login");
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      backgroundColor: Colors.white,
      child: FutureBuilder<UserProfile?>(
        future: _firestoreService.getUserProfile(_authservice.user!.uid),
        builder: (context, snapshot) {
          // Default values
          String userName = 'Guest';
          String userEmail = 'No email';
          String? profileImageUrl;

          // Load user data if available
          if (snapshot.hasData && snapshot.data != null) {
            final userProfile = snapshot.data!;
            userName = userProfile.name ?? 'Guest';
            userEmail = userProfile.email ?? _authservice.user?.email ?? 'No email';
            profileImageUrl = userProfile.pfpURL;
          }

          return Column(
            children: [
              // Custom Drawer Header with reduced height
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 20,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.shade700,
                      Colors.teal.shade500,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const CircularProgressIndicator(
                          color: Colors.teal,
                          strokeWidth: 2,
                        )
                            : (profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? ClipOval(
                          child: Image.network(
                            profileImageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.teal,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.teal,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          ),
                        )
                            : const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.teal,
                        )),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // User Name
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // User Email
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Profile',
                      iconColor: Colors.teal,
                      onTap: () => _navigateToScreen(const ProfileScreen()),
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      icon: Icons.share,
                      title: 'Share App',
                      iconColor: Colors.blue,
                      onTap: _showShareDialog,
                    ),
                    _buildMenuItem(
                      icon: Icons.contact_mail,
                      title: 'Contact Us',
                      iconColor: Colors.orange,
                      onTap: () {
                        // Import your ContactUsPage here
                        _navigateToScreen(ContactUsScreen());
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.info,
                      title: 'About Us',
                      iconColor: Colors.purple,
                      onTap: () {
                        // Import your AboutUsPage here
                        _navigateToScreen(AboutUsScreen());
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      iconColor: Colors.red,
                      textColor: Colors.red,
                      onTap: _showLogoutDialog,
                    ),
                  ],
                ),
              ),

              // App Version Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// Placeholder classes - replace with your actual imports
class ContactUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}