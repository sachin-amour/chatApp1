📱 Features
Core Features

🔐 User Authentication - Secure email/password authentication with Firebase Auth
💬 Real-time Chat - Instant messaging with live updates
👤 User Profiles - Customizable profiles with name, email, and profile pictures
🔍 User Search - Find and connect with other users by email
📸 Image Support - Upload and share images via Cloudinary
🎨 Modern UI - Clean, intuitive interface with Material Design

Advanced Features

✏️ Edit Profile - Change name and profile picture
🌊 Smooth Animations - Fluid transitions and micro-interactions
📱 Responsive Design - Optimized for all screen sizes
🔔 Real-time Updates - Live chat updates using Firebase Firestore streams
🎭 Hero Animations - Smooth transitions between screens
📤 Share App - Built-in app sharing functionality

🛠️ Tech Stack
Frontend

Flutter - Cross-platform mobile framework
Dart - Programming language
Material Design - UI components and design system

Backend & Services

Firebase Auth - User authentication
Cloud Firestore - Real-time database
Cloudinary - Image storage and CDN
GetIt - Dependency injection
lib/
├── main.dart                          # App entry point
├── model/
│   ├── chat.dart                      # Chat model
│   ├── messages.dart                  # Message model
│   └── userProfile.dart               # User profile model
├── screen/
│   ├── home_screen.dart               # Home/Chat list screen
│   ├── chat_screen.dart               # Individual chat screen
│   ├── search_screen.dart             # User search screen
│   ├── profile_screen.dart            # User profile screen
│   ├── login_screen.dart              # Login screen
│   ├── signup_screen.dart             # Registration screen
│   ├── contact_us_page.dart           # Contact information
│   ├── about_us_page.dart             # About the app
│   └── ui helper/
│       ├── chatTile.dart              # Chat list item widget
│       └── slider_screen.dart         # Navigation drawer
├── services/
│   ├── auth_service.dart              # Authentication logic
│   ├── firestore_service.dart         # Database operations
│   ├── cloudinary_service.dart        # Image upload service
│   ├── media_service.dart             # Image picker service
│   ├── navigation_service.dart        # Navigation management
│   └── alert_service.dart             # Toast/alert messages
└── utils/
└── constants.dart                 # App constants