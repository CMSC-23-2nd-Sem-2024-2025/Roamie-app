# Travel Planning App

A modern, user-friendly mobile application designed to help you plan, organize, and enjoy your travels with ease.

## Table of Contents
- [Travel Planning App](#travel-planning-app)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Screenshots](#screenshots)
  - [Installation](#installation)
  - [Deployment](#deployment)
  - [Developer Guidelines](#developer-guidelines)
    - [Best Coding Practices](#best-coding-practices)
    - [Branching Strategy](#branching-strategy)
    - [Commit Message Format](#commit-message-format)

## Features
- Create and manage travel plans
- Include a daily itinerary for each trip
- Connect and find similar people with the same travel styles
- Share your travel plans to other users
- Get notified when a travel plan is near

## Screenshots
<!-- Add screenshots of app here -->

## Installation
1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/travelplanning_app.git
   cd travelplanning_app
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the app:**
   ```bash
   flutter run
   ```

## Deployment
To deploy the app in APK format, follow these steps:
1. **Build the APK:**
   ```bash
   flutter build apk
   ```
2. **Locate the APK file:**
   The APK file will be located at `build/app/outputs/flutter-apk/app-release.apk`.
3. **Install the APK:**
   Transfer the APK file to your Android device and install it.

## Developer Guidelines
### Best Coding Practices
- Follow the Flutter style guide for consistent code formatting.
- Write meaningful comments and documentation for your code.
- Use meaningful variable and function names.

### Branching Strategy
- Use feature branches for new features or bug fixes.
- Branch naming convention: `feature/feature-name` or `fix/bug-name`.
- Merge feature branches into the `main` branch after code review and testing.

### Commit Message Format
Follow the [Conventional Commits](https://www.conventionalcommits.org/) format for commit messages:
- **Types:**
  - `feat`: A new feature
  - `fix`: A bug fix
  - `docs`: Documentation only changes
  - `style`: Changes that do not affect the meaning of the code
  - `refactor`: A code change that neither fixes a bug nor adds a feature
  - `perf`: A code change that improves performance
  - `test`: Adding missing tests or correcting existing tests
  - `chore`: Changes to the build process or auxiliary tools and libraries