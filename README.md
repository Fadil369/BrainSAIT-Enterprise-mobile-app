# BrainSAIT Enterprise Mobile App

<div align="center">
  <img src="assets/icon.png" alt="BrainSAIT Logo" width="120" />
  
  <h3>🧠 الذكاء الاصطناعي الطبي المؤسسي • Medical AI Enterprise Platform</h3>
  
  [![React Native](https://img.shields.io/badge/React%20Native-0.79-blue.svg)](https://reactnative.dev/)
  [![Expo](https://img.shields.io/badge/Expo-SDK%2053-black.svg)](https://expo.dev/)
  [![TypeScript](https://img.shields.io/badge/TypeScript-5.8-blue.svg)](https://www.typescriptlang.org/)
  [![iOS](https://img.shields.io/badge/iOS-14%2B-lightgrey.svg)](https://developer.apple.com/)
  [![Android](https://img.shields.io/badge/Android-API%2023%2B-green.svg)](https://developer.android.com/)
</div>

## 📱 Overview | نظرة عامة

BrainSAIT Enterprise is a comprehensive mobile application for healthcare organizations, providing integrated management of all department modules with real-time data synchronization, workflow automation, and compliance with medical standards (HIPAA/NPHIES).

**برينسايت المؤسسي** هو تطبيق جوال شامل للمؤسسات الطبية، يوفر إدارة متكاملة لجميع وحدات الأقسام مع مزامنة البيانات في الوقت الفعلي وأتمتة سير العمل والامتثال للمعايير الطبية.

## 🏥 Core Features | الميزات الأساسية

### 📋 Department Integration | تكامل الأقسام
- **HR (الموارد البشرية)**: Employee lifecycle management
- **Finance (المالية)**: Payroll and budget management  
- **Scheduling (الجدولة)**: Medical shift management
- **R&D (البحث والتطوير)**: Research project management
- **Innovation Labs (مختبرات الابتكار)**: AI model development
- **Performance & KPIs (الأداء)**: Comprehensive tracking
- **Publications (المنشورات)**: Research publication management
- **Communications (الاتصالات)**: Multi-channel messaging
- **CPD (التطوير المهني)**: Continuing education
- **Onboarding (التأهيل)**: New employee integration

### 🔒 Security & Compliance | الأمان والامتثال
- **Biometric Authentication**: Face ID / Touch ID support
- **HIPAA Compliance**: Medical-grade data protection
- **NPHIES Integration**: Saudi healthcare standards
- **End-to-End Encryption**: Secure data transmission
- **Audit Trails**: Complete activity logging

### 🌐 Bilingual Support | الدعم ثنائي اللغة
- **Arabic (العربية)**: Full RTL layout support
- **English**: LTR layout support
- **Dynamic Switching**: Real-time language toggle
- **Cultural Context**: Healthcare terminology localization

### 📱 Mobile-First Design | تصميم محمول أولاً
- **Responsive UI**: Optimized for all screen sizes
- **Offline Capability**: Work without internet
- **Push Notifications**: Real-time alerts
- **Haptic Feedback**: Enhanced user experience
- **Dark Theme**: Optimized for healthcare environments

## 🚀 Quick Start | البدء السريع

### Prerequisites | المتطلبات الأساسية

- **Node.js**: 18.x or later
- **npm** or **yarn**: Package manager
- **Expo CLI**: `npm install -g @expo/cli`
- **EAS CLI**: `npm install -g eas-cli` (for builds)

#### For iOS Development:
- **Xcode**: Latest version
- **iOS Simulator**: Included with Xcode
- **Apple Developer Account**: For device testing/deployment

#### For Android Development:
- **Android Studio**: Latest version
- **Android SDK**: API level 23+
- **Android Virtual Device (AVD)**: For testing

### Installation | التثبيت

1. **Clone the repository**:
   ```bash
   git clone https://github.com/brainsait/enterprise-mobile.git
   cd enterprise-mobile
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Install iOS dependencies** (iOS only):
   ```bash
   npx pod-install ios
   ```

### Development | التطوير

1. **Start the development server**:
   ```bash
   npm run start
   ```

2. **Run on iOS Simulator**:
   ```bash
   npm run ios
   ```

3. **Run on Android Emulator**:
   ```bash
   npm run android
   ```

4. **Run on Web**:
   ```bash
   npm run web
   ```

## 🏗 Project Structure | هيكل المشروع

```
BrainSAITEnterprise/
├── App.tsx                    # Main application entry
├── app.json                   # Expo configuration
├── eas.json                   # Build configuration
├── src/
│   ├── components/           # Reusable UI components
│   │   └── MobileComponents.tsx
│   ├── contexts/            # React contexts
│   │   ├── AuthContext.tsx
│   │   ├── LanguageContext.tsx
│   │   └── ThemeContext.tsx
│   ├── screens/             # Application screens
│   │   ├── SplashScreen.tsx
│   │   ├── LoginScreen.tsx
│   │   └── MainDashboard.tsx
│   ├── theme/               # Design system
│   │   └── BrainSAITTheme.ts
│   ├── types/               # TypeScript definitions
│   ├── services/            # API services
│   ├── utils/               # Utility functions
│   └── constants/           # App constants
├── assets/                  # Static assets
└── docs/                   # Documentation
```

## 🔧 Configuration | التكوين

### Environment Setup | إعداد البيئة

Create a `.env` file in the project root:

```env
# API Configuration
API_BASE_URL=https://api.brainsait.sa
API_VERSION=v1

# Authentication
OAUTH_CLIENT_ID=your_client_id
OAUTH_CLIENT_SECRET=your_client_secret

# Push Notifications
EXPO_PROJECT_ID=your_expo_project_id
FCM_SERVER_KEY=your_fcm_server_key

# Analytics
ANALYTICS_ENABLED=true

# Feature Flags
ENABLE_BIOMETRICS=true
ENABLE_OFFLINE_MODE=true
ENABLE_PUSH_NOTIFICATIONS=true
```

### iOS Configuration | تكوين iOS

1. **Open iOS project in Xcode**:
   ```bash
   npx expo run:ios
   ```

2. **Configure capabilities in Xcode**:
   - Face ID / Touch ID
   - Push Notifications
   - Background App Refresh
   - Camera Usage
   - Location Services

3. **Set up provisioning profiles** for device testing

### Android Configuration | تكوين الأندرويد

1. **Open Android project**:
   ```bash
   npx expo run:android
   ```

2. **Configure permissions in `app.json`**:
   - Biometric authentication
   - Camera access
   - Location services
   - Push notifications

## 🛠 Building for Production | البناء للإنتاج

### Using EAS Build | استخدام EAS Build

1. **Configure EAS project**:
   ```bash
   eas init
   ```

2. **Build for iOS**:
   ```bash
   npm run build:ios
   ```

3. **Build for Android**:
   ```bash
   npm run build:android
   ```

4. **Build for both platforms**:
   ```bash
   npm run build:all
   ```

### Local Development Builds | البناء المحلي للتطوير

#### iOS Development Build:
```bash
npx expo run:ios --configuration Release
```

#### Android Development Build:
```bash
npx expo run:android --variant release
```

## 🧪 Testing | الاختبار

### Demo Accounts | الحسابات التجريبية

The app includes demo accounts for testing different user roles:

| Username | Password | Role | Department |
|----------|----------|------|------------|
| `admin` | `admin123` | System Administrator | IT |
| `dr.sarah` | `demo123` | Doctor | Clinical AI |
| `eng.mohammed` | `demo123` | Engineer | Engineering |
| `hr.fatima` | `demo123` | HR Manager | Human Resources |

### Testing Features | اختبار الميزات

1. **Biometric Authentication**: Test on physical device
2. **Push Notifications**: Configure with Expo push service
3. **Offline Mode**: Disable network and test functionality
4. **Language Switching**: Test Arabic/English toggle
5. **Department Modules**: Navigate through all modules

## 📈 Performance | الأداء

### Optimization | التحسين

- **Code Splitting**: Lazy loading of modules
- **Image Optimization**: WebP format support
- **Memory Management**: Efficient state management
- **Network Caching**: Offline-first architecture
- **Bundle Size**: Tree shaking and minification

### Monitoring | المراقبة

- **Crash Reporting**: Integrated error tracking
- **Performance Metrics**: Real-time monitoring
- **Usage Analytics**: User behavior insights
- **Health Checks**: System status monitoring

## 🔐 Security | الأمان

### Data Protection | حماية البيانات

- **Encryption at Rest**: AES-256 encryption
- **Encryption in Transit**: TLS 1.3
- **Biometric Storage**: Keychain/Keystore
- **Token Management**: Secure token refresh
- **Data Masking**: PII protection

### Compliance | الامتثال

- **HIPAA Compliance**: Healthcare data protection
- **NPHIES Integration**: Saudi healthcare standards
- **GDPR Compliance**: European privacy regulations
- **SOC 2 Type II**: Security controls audit
- **ISO 27001**: Information security management

## 🌍 Internationalization | التدويل

### Supported Languages | اللغات المدعومة

- **Arabic (العربية)**: Primary language with RTL support
- **English**: Secondary language with LTR support

### Adding New Languages | إضافة لغات جديدة

1. Add translations to `src/contexts/LanguageContext.tsx`
2. Update language selector in settings
3. Test RTL/LTR layout compatibility
4. Validate cultural context for medical terms

## 📚 Documentation | التوثيق

### API Documentation | توثيق API
- **Swagger/OpenAPI**: Interactive API docs
- **Postman Collection**: Request examples
- **SDKs**: Client libraries for integration

### User Guides | أدلة المستخدم
- **Admin Guide**: System administration
- **User Manual**: End-user documentation
- **Developer Guide**: Technical integration
- **Troubleshooting**: Common issues and solutions

## 🤝 Contributing | المساهمة

### Development Workflow | سير عمل التطوير

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/new-feature`
3. **Commit** changes: `git commit -m 'Add new feature'`
4. **Push** to branch: `git push origin feature/new-feature`
5. **Submit** a Pull Request

### Code Standards | معايير الكود

- **TypeScript**: Strict type checking
- **ESLint**: Code linting and formatting
- **Prettier**: Code formatting
- **Conventional Commits**: Commit message format
- **Husky**: Pre-commit hooks

### Testing Requirements | متطلبات الاختبار

- **Unit Tests**: Jest and React Native Testing Library
- **Integration Tests**: E2E testing with Detox
- **Accessibility**: Screen reader compatibility
- **Performance**: Bundle size and load time tests

## 📞 Support | الدعم

### Contact Information | معلومات الاتصال

- **Email**: support@brainsait.sa
- **Phone**: +966 11 123 4567
- **Website**: https://brainsait.sa
- **Documentation**: https://docs.brainsait.sa

### Issue Reporting | الإبلاغ عن المشاكل

1. **Search** existing issues first
2. **Use** the issue template
3. **Provide** detailed reproduction steps
4. **Include** system information and logs
5. **Label** appropriately (bug, feature, etc.)

## 📄 License | الترخيص

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Copyright © 2024 BrainSAIT Ltd. All rights reserved.**

---

<div align="center">
  <p><strong>🏥 Built for Healthcare Excellence | مبني للتميز في الرعاية الصحية 🏥</strong></p>
  
  [![BrainSAIT](https://img.shields.io/badge/BrainSAIT-Medical%20AI-0ea5e9.svg)](https://brainsait.sa)
  [![Saudi Arabia](https://img.shields.io/badge/Made%20in-Saudi%20Arabia-00AA00.svg)](https://brainsait.sa)
</div>