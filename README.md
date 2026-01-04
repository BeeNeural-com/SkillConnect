# SkillConnect

A Flutter mobile application connecting customers with skilled technicians for home services.

## Overview

SkillConnect is a service marketplace platform that enables:
- **Customers** to find and book skilled technicians for various home services
- **Vendors/Technicians** to receive service requests and manage their bookings

## Features

### Customer Features
- Browse service categories (Plumbing, Electrical, Carpentry, etc.)
- Request services with photos and location
- Find nearby technicians
- Track booking status
- Chat with technicians
- Rate and review services

### Vendor Features
- Create technician profile with skills
- Receive service requests
- Accept/reject bookings
- Update booking status
- Manage availability
- View earnings

## Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod 3.0
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Navigation**: GoRouter
- **Maps**: Google Maps Flutter

## Getting Started

### Prerequisites
- Flutter SDK (3.35.7 or higher)
- Android Studio / VS Code
- Firebase account

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/           # App configuration, constants, theme
├── models/         # Data models
├── services/       # Business logic layer
├── providers/      # State management
├── features/       # Feature modules
│   ├── auth/      # Authentication
│   ├── customer/  # Customer features
│   ├── vendor/    # Vendor features
│   └── shared/    # Shared components
└── main.dart
```

## Implementation Plan

See [implementation_plan.md](.gemini/antigravity/brain/b4d46425-d68f-4800-b5ae-2814b5d80f28/implementation_plan.md) for detailed feature breakdown and development roadmap.

## Current Status

✅ Project setup complete  
✅ Firebase configured  
✅ Android configuration complete  
⏳ Features ready to implement

## Contributing

This is a private project. For questions or issues, contact the development team.

## License

Private - All rights reserved
