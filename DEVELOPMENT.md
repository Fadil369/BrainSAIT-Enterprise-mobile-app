# BrainSAIT Enterprise Mobile Development Guide

## 🚀 Quick Start

### Option 1: Using the Startup Script (Recommended)
```bash
./start.sh
```

### Option 2: Manual Commands
```bash
# Install dependencies
npm install

# Start development server
npm start

# For specific platforms
npm run ios      # iOS Simulator
npm run android  # Android Emulator
npm run web      # Web Browser
```

## 📱 Platform Setup

### iOS Development
1. **Install Xcode** (latest version from App Store)
2. **Install iOS Simulator** (included with Xcode)
3. **Run on iOS**:
   ```bash
   npm run ios
   ```

### Android Development
1. **Install Android Studio**
2. **Set up Android SDK** (API level 23+)
3. **Create Android Virtual Device (AVD)**
4. **Run on Android**:
   ```bash
   npm run android
   ```

## 🛠 Development Tools

### Required Tools
- **Node.js**: 18.x or later
- **npm**: 8.x or later
- **Expo CLI**: Latest version
- **EAS CLI**: For building and deploying

### Recommended IDE Setup
- **VS Code** with extensions:
  - React Native Tools
  - TypeScript Hero
  - Expo Tools
  - ES7+ React/Redux/React-Native snippets
  - Prettier - Code formatter

## 🧪 Testing

### Demo Accounts
Use these accounts to test different user roles:

| Username | Password | Role | Department |
|----------|----------|------|------------|
| `admin` | `admin123` | System Administrator | IT |
| `dr.sarah` | `demo123` | Doctor | Clinical AI |
| `eng.mohammed` | `demo123` | Engineer | Engineering |
| `hr.fatima` | `demo123` | HR Manager | Human Resources |

### Features to Test
1. **Authentication**:
   - Login with demo accounts
   - Biometric authentication (on device)
   - Logout functionality

2. **Dashboard**:
   - Module navigation
   - Language switching (Arabic ⇄ English)
   - Category filtering
   - Pull-to-refresh

3. **Mobile Features**:
   - Push notifications
   - Haptic feedback
   - Offline functionality
   - RTL/LTR layouts

## 🔧 Development Commands

```bash
# Development
npm start              # Start Expo dev server
npm run dev           # Start with dev client
npm run clean         # Clean cache and restart

# Type Checking
npm run type-check    # Run TypeScript compiler

# Building
npm run build:ios     # Build for iOS
npm run build:android # Build for Android
npm run build:all     # Build for all platforms

# Deployment
npm run submit:ios    # Submit to App Store
npm run submit:android # Submit to Google Play
```

## 🎨 Theming & Styling

### BrainSAIT Design System
The app uses a comprehensive design system located in `src/theme/BrainSAITTheme.ts`:

- **Colors**: Medical-focused color palette
- **Typography**: Arabic and English font systems
- **Spacing**: Consistent spacing scale
- **Shadows**: Elevation system
- **Healthcare Colors**: Department-specific colors

### Key Design Principles
1. **Healthcare-First**: Optimized for medical environments
2. **Accessibility**: WCAG 2.1 AA compliance
3. **Bilingual**: Full Arabic and English support
4. **Mobile-Optimized**: Touch-friendly interactions
5. **Professional**: Enterprise-grade appearance

## 🌐 Internationalization

### Adding New Languages
1. Update `src/contexts/LanguageContext.tsx`
2. Add translations to the `translations` object
3. Test RTL/LTR compatibility
4. Validate medical terminology

### Current Languages
- **Arabic (العربية)**: Primary language with RTL support
- **English**: Secondary language with LTR support

## 🔐 Security Implementation

### Authentication Flow
1. **Splash Screen**: Initialize app and check auth state
2. **Login Screen**: Username/password or biometric auth
3. **Dashboard**: Access control based on user role

### Security Features
- **Biometric Authentication**: Face ID/Touch ID
- **Secure Storage**: Keychain/Keystore for tokens
- **Encryption**: AES-256 for sensitive data
- **Audit Logging**: Complete activity tracking
- **Session Management**: Token refresh and expiry

## 📊 Performance Optimization

### Best Practices
- **Code Splitting**: Lazy load heavy components
- **Image Optimization**: Use appropriate formats and sizes
- **Memory Management**: Clean up listeners and timers
- **Bundle Analysis**: Monitor and reduce bundle size
- **Caching Strategy**: Implement smart caching

### Monitoring
- **Performance Metrics**: Track load times and responsiveness
- **Crash Reporting**: Monitor app stability
- **User Analytics**: Track user behavior and engagement
- **Health Checks**: Monitor system dependencies

## 🚨 Troubleshooting

### Common Issues

#### Metro bundler issues:
```bash
npm run clean
npm install
npm start -- --reset-cache
```

#### iOS build issues:
```bash
cd ios && pod install && cd ..
npm run ios
```

#### Android build issues:
```bash
cd android && ./gradlew clean && cd ..
npm run android
```

#### TypeScript errors:
```bash
npm run type-check
```

### Device Testing

#### iOS Device:
1. Connect iPhone/iPad via USB
2. Trust developer certificate in Settings
3. Run: `npm run ios -- --device`

#### Android Device:
1. Enable Developer Options and USB Debugging
2. Connect via USB and authorize computer
3. Run: `npm run android -- --device`

## 🏗 Build Configuration

### Environment Variables
Create `.env` file with:
```env
API_BASE_URL=https://api.brainsait.sa
EXPO_PROJECT_ID=your_expo_project_id
```

### Build Profiles (eas.json)
- **Development**: Internal testing with simulators
- **Preview**: Internal distribution for testing
- **Production**: App Store/Google Play release

### Deployment Process
1. **Development Build**: Test features locally
2. **Preview Build**: Internal team testing
3. **Production Build**: Store submission
4. **Store Review**: Platform-specific review process
5. **Release**: Public availability

## 📝 Code Style Guide

### TypeScript
- Strict type checking enabled
- Explicit return types for functions
- Interface over type aliases
- Consistent naming conventions

### React Native
- Functional components with hooks
- Proper cleanup in useEffect
- Memoization for performance
- Accessibility labels

### File Organization
```
src/
├── components/     # Reusable UI components
├── screens/        # Full-screen components
├── contexts/       # React context providers
├── hooks/          # Custom React hooks
├── services/       # API and external services
├── utils/          # Utility functions
├── types/          # TypeScript type definitions
├── theme/          # Design system and styling
└── constants/      # App-wide constants
```

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Make changes and test thoroughly
4. Run type check: `npm run type-check`
5. Commit with conventional commits
6. Push and create pull request

### Code Review Checklist
- [ ] TypeScript errors resolved
- [ ] Both Arabic and English tested
- [ ] iOS and Android compatibility
- [ ] Accessibility compliance
- [ ] Performance impact assessed
- [ ] Security considerations reviewed

## 📞 Support

### Development Support
- **Email**: dev-support@brainsait.sa
- **Slack**: #brainsait-mobile-dev
- **Documentation**: https://docs.brainsait.sa/mobile

### Platform-Specific Support
- **iOS**: https://developer.apple.com/support/
- **Android**: https://developer.android.com/support
- **Expo**: https://expo.dev/support

---

**Happy coding! 🧠💙**