# React Native Expo Project Automation

Automated setup scripts for creating React Native Expo projects with multi-environment support.

## Features

### Bare Minimum Workflow
- Interactive project setup with custom app IDs
- Multi-environment support (develop, qa, preprod, production)
- Pre-configured navigation with Zustand state management
- Example modules (splash, login, home screens)
- Android product flavors with environment-specific configurations
- iOS schemes for each environment
- Automated icon generation with preview
- ESLint, Prettier, and TypeScript configuration
- Environment-specific build scripts
- Full native code access

### Managed Workflow
- Simplified Expo managed setup
- Interactive project generator with Plop.js
- Multi-environment support (develop, qa, preprod, production)
- Pre-configured navigation and state management
- Automated icon and splash screen generation
- TypeScript and ESLint configuration
- No native code management required

## Usage

### Quick Install (One-liner)

```bash
rm -rf /tmp/rn-automation && git clone https://github.com/Nishan666/rn-automation.git /tmp/rn-automation && chmod +x /tmp/rn-automation/setup.sh && /tmp/rn-automation/setup.sh && rm -rf /tmp/rn-automation
```

### Manual Setup

```bash
git clone https://github.com/Nishan666/rn-automation.git
cd rn-automation
chmod +x setup.sh
./setup.sh
```

## Workflow Selection

When you run the setup script, you'll be prompted to choose between two workflows:

### 1. Bare Minimum Workflow

Choose this if you need:
- Full control over native code
- Custom native modules
- Direct access to Android/iOS projects
- Advanced customization

**Setup Process:**
1. Select workflow type (Bare Minimum)
2. Enter project name
3. Enter app display name
4. Choose project location
5. Configure Android package ID
6. Optionally configure iOS
7. Optionally set up app icons with preview

**What gets created:**
- Expo project with bare-minimum template
- Organized project structure (src/modules, navigation, etc.)
- Android product flavors (develop, qa, preprod, production)
- iOS schemes for each environment (if configured)
- Environment files (.env.develop, .env.qa, etc.)
- Example modules (splash, login, home)
- Testing setup with example tests

### 2. Managed Workflow

Choose this if you want:
- Simplified setup without native code
- Faster development
- Expo's managed services
- Less configuration overhead

**Setup Process:**
1. Select workflow type (Managed)
2. Choose project location via file browser
3. Enter project name
4. Enter bundle identifier (e.g., com.company.app)
5. Select build variants (develop, qa, preprod, prod)
6. Optionally select icons for each variant

**What gets created:**
- Expo managed project
- Pre-configured navigation (React Navigation)
- State management (Redux Toolkit)
- TypeScript configuration
- ESLint setup
- Environment-specific configurations
- Automated icon and splash screen generation

## Icon Preview Feature

When setting up icons in Bare Minimum workflow:
- Select icon file via fuzzy finder or manual path
- Preview shows:
  - File name
  - File path
  - File size
  - Dimensions
- Confirm before applying
- Re-select if not satisfied
- Recommended size: 1024x1024 PNG

## Project Structure (Bare Minimum)

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

## Project Structure (Managed)

```
src/
├── assets/icons/        # App icons for each variant
├── components/          # Reusable components
├── constants/           # Colors, fonts, strings
├── features/            # Feature-based modules
├── hooks/               # Custom React hooks
├── navigation/          # Navigation setup
├── screens/             # Screen components
├── services/            # API services
├── store/               # Redux store
├── theme/               # Theme configuration
└── types/               # TypeScript types
```

## Build Commands

### Bare Minimum Workflow

**Android:**
- `npm run android:dev` - Development build
- `npm run android:qa` - QA build  
- `npm run android:preprod` - Pre-production build
- `npm run android:prod` - Production build

**iOS (macOS only):**
- `npm run ios:dev` - Development build
- `npm run ios:qa` - QA build
- `npm run ios:preprod` - Pre-production build
- `npm run ios:prod` - Production build
- `npm run ios:clean` - Clean build folder

**Code Quality:**
- `npm run lint` - Check code quality
- `npm run lint:fix` - Auto-fix linting issues
- `npm run format` - Format code with Prettier

**Testing:**
- `npm test` - Run tests
- `npm run test:watch` - Run tests in watch mode
- `npm run test:coverage` - Run tests with coverage report

**WebdriverIO E2E Testing:**
- `npm run wdio` - Run WebdriverIO tests
- `npm run test:android` - Run Android E2E tests

### Managed Workflow

**Build:**
- `npm run prebuild` - Generate native projects
- `npm start` - Start development server
- `npm run build` - Build for Android
- `npm run build:ios` - Build for iOS

**Code Quality:**
- `npm run lint` - Check code quality
- `npm run lint:fix` - Auto-fix linting issues

## WebdriverIO Mobile Testing

The setup script includes an optional WebdriverIO configuration for mobile automation testing.

### Setup

During project setup, you'll be prompted to configure WebdriverIO. If you choose yes:
- WebdriverIO CLI wizard will guide you through configuration
- Appium will be installed for mobile automation
- Test structure will be created automatically

### Manual Setup

If you skip WebdriverIO during initial setup, you can add it later:

```bash
cd your-project
npx wdio config
```

### Running Tests

1. Start Android Emulator:
   ```bash
   emulator -avd <your_avd_name>
   ```

2. Build your app:
   ```bash
   npm run android:dev
   ```

3. Run tests:
   ```bash
   npm run wdio
   ```

### Test Structure

WebdriverIO tests are organized in:
- `test/step-definitions/`
- `test/unit-testing/`

## Environment Configuration

### Bare Minimum
Update the `.env.*` files with your API endpoints:
- `.env` - Default/production environment
- `.env.develop` - Development environment
- `.env.qa` - QA environment  
- `.env.preprod` - Pre-production environment

### Managed
Set `APP_VARIANT` in `.env` file:
```bash
APP_VARIANT=develop  # or qa, preprod, prod
```

## Dependencies Included

### Bare Minimum Workflow
- **Navigation**: @react-navigation/native, @react-navigation/native-stack
- **State Management**: zustand
- **UI Components**: react-native-gesture-handler, react-native-safe-area-context, react-native-screens
- **SVG Support**: react-native-svg
- **Environment Config**: react-native-config
- **Utilities**: react-native-toast-message, @react-native-async-storage/async-storage, react-native-device-info
- **Testing**: jest, @testing-library/react-native, @testing-library/jest-native
- **Development**: ESLint, Prettier, TypeScript, Babel module resolver

### Managed Workflow
- **Navigation**: @react-navigation/native, @react-navigation/native-stack
- **State Management**: @reduxjs/toolkit, react-redux
- **UI Components**: react-native-gesture-handler, react-native-safe-area-context, react-native-screens
- **Development**: TypeScript, ESLint, Prettier
- **Utilities**: Plop.js for code generation, Sharp for image processing

## Requirements

- Node.js (v14 or higher) and npm
- Expo CLI
- Git
- **For Bare Minimum:**
  - Android Studio (for Android builds)
  - Xcode (for iOS builds, macOS only)
  - jq (for JSON processing)
- **For Managed:**
  - fzf (optional, for fuzzy file finder)

## Troubleshooting

### Temp folders not cleaned up
If you see leftover temp folders in `/tmp/`, clean them manually:
```bash
rm -rf /tmp/expo-managed-workflow-*
```

### iOS build issues (Bare Minimum)
Clean the build folder:
```bash
npm run ios:clean
```

### Package installation fails
Retry with:
```bash
npm install --legacy-peer-deps
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT