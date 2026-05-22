# World Cup Hub - Mobile Application

This directory contains the frontend implementation of the World Cup Hub platform, developed using the Flutter framework.

## Project Overview

The mobile application serves as the primary interface for users to access tournament information, participate in prediction pools, and manage their digital sticker albums.

## Technical Stack

- **Framework**: Flutter
- **Language**: Dart
- **Navigation**: go_router
- **Styling**: Material Design 3
- **Icons**: flutter_launcher_icons

## Prerequisites

Ensure you have the following installed on your development environment:

- Flutter SDK
- Android Studio or Xcode (for mobile emulation)
- A physical or virtual device for testing

## Setup and Installation

1. Navigate to the project directory:
   ```bash
   cd FRONTEND_PROYECTO_WCH
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate application icons (if modified):
   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. Launch the application:
   ```bash
   flutter run
   ```

## Directory Structure

- `lib/`: Contains the core application logic and UI components.
  - `screens/`: Application views and page layouts.
  - `services/`: API integration and business logic.
  - `utils/`: Common helpers and constants.
- `assets/`: Static resources such as images and icons.
- `android/` & `ios/`: Platform-specific configurations.

## Documentation and Resources

For detailed information on the Flutter framework, refer to the [official documentation](https://docs.flutter.dev/).
