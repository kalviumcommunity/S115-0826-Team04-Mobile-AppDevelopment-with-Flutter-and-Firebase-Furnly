# Furnly

Furnly is a Furniture Rental Management App built with Flutter and Firebase.

## Setup Instructions

This project requires Firebase to run locally. If this is your first time setting up the repository, follow these steps to configure your local environment:

### 1. Install Flutter & Dart
Make sure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and added to your system `PATH`.

### 2. Install Firebase CLI Tools
Run the following commands in your terminal to install the necessary CLI tools:
```bash
# Install Firebase Tools via npm
npm install -g firebase-tools

# Login to your Firebase account
firebase login

# Activate the FlutterFire CLI globally
dart pub global activate flutterfire_cli
```

### 3. Configure the Project
Connect the app to the Furnly Firebase project:
```bash
flutterfire configure
```
*(Select the `furnly-app` project and enable your target platforms).*

### 4. Run the App
Once configured, fetch the dependencies and run the application:
```bash
flutter pub get
flutter run -d chrome
```

## Architecture
Please refer to the `architecture.md` and `design.md` files for structural and design guidelines.
