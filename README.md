# React Native Expo Project Automation

Automated setup scripts for creating React Native Expo projects with multi-environment support.

## Features

- Interactive project setup with custom app IDs
- Multi-environment support (develop, qa, preprod, production)
- Pre-configured navigation with Zustand state management
- Example modules (splash, login, home screens)
- Android product flavors with environment-specific configurations
- Automated icon generation for all environments
- ESLint, Prettier, and TypeScript configuration
- Environment-specific build scripts

## Usage

### 1. Project Setup

```bash
./setup.sh
```

This will:
- Prompt for project name and Android app ID
- Create Expo project with bare-minimum template
- Install all necessary dependencies
- Set up project structure with example modules
- Configure Android product flavors
- Create environment files (.env.develop, .env.qa, etc.)
- Add build scripts to package.json

### 2. Icon Setup

Icon generation is integrated into the main setup script. During setup, you'll be prompted to optionally generate app icons for your chosen environment.

For post-setup icon generation, you can re-run the setup script or manually place icons in the appropriate directories.

## Project Structure

```
src/
├── assets/fonts/
├── constants/
├── model/
├── modules/
│   ├── splash/          # Splash screen with session check
│   ├── login/           # Login flow with Zustand store
│   └── home/            # Home screen
├── navigation/          # React Navigation setup
├── services/
├── store/slices/
├── styles/
├── utils/
└── viewmodels/
```

## Build Commands

After setup, use these commands in your project directory:

### Android
- `npm run android:dev` - Development build
- `npm run android:qa` - QA build  
- `npm run android:preprod` - Pre-production build
- `npm run android:prod` - Production build

### Code Quality
- `npm run lint` - Check code quality
- `npm run lint:fix` - Auto-fix linting issues
- `npm run format` - Format code with Prettier

## Environment Configuration

Update the `.env.*` files with your API endpoints and configuration:

- `.env` - Default/production environment
- `.env.develop` - Development environment
- `.env.qa` - QA environment  
- `.env.preprod` - Pre-production environment

## Dependencies Included

- **Navigation**: @react-navigation/native, @react-navigation/native-stack
- **State Management**: zustand
- **UI Components**: react-native-gesture-handler, react-native-safe-area-context, react-native-screens
- **SVG Support**: react-native-svg
- **Environment Config**: react-native-config
- **Animations**: react-native-reanimated
- **Utilities**: react-native-toast-message, @react-native-async-storage/async-storage, react-native-device-info
- **Development**: ESLint, Prettier, TypeScript, Babel module resolver

## Requirements

- Node.js and npm
- Expo CLI
- Android Studio (for Android builds)
- Xcode (for iOS builds, macOS only)
- ImageMagick (for icon generation)
- jq (for JSON processing)