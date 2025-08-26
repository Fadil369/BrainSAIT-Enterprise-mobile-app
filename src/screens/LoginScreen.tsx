import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  Animated,
  Dimensions,
  KeyboardAvoidingView,
  Platform,
  Alert,
  StatusBar,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import * as Haptics from 'expo-haptics';
import * as LocalAuthentication from 'expo-local-authentication';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '../contexts/AuthContext';
import { useLanguage } from '../contexts/LanguageContext';
import { useTheme } from '../contexts/ThemeContext';
import { BrainSAITColors } from '../theme/BrainSAITTheme';

const { width, height } = Dimensions.get('window');

const LoginScreen: React.FC = () => {
  const navigation = useNavigation<any>();
  const { login, loginWithBiometrics } = useAuth();
  const { t, isRTL } = useLanguage();
  const { colors } = useTheme();
  
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [biometricsAvailable, setBiometricsAvailable] = useState(false);
  const [biometricType, setBiometricType] = useState<string>('');

  // Animation refs
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const slideAnim = useRef(new Animated.Value(50)).current;
  const shakeAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    startAnimations();
    checkBiometrics();
  }, []);

  const startAnimations = () => {
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 1000,
      useNativeDriver: true,
    }).start();

    Animated.timing(slideAnim, {
      toValue: 0,
      duration: 800,
      delay: 300,
      useNativeDriver: true,
    }).start();
  };

  const checkBiometrics = async () => {
    try {
      const hasHardware = await LocalAuthentication.hasHardwareAsync();
      const isEnrolled = await LocalAuthentication.isEnrolledAsync();
      const supportedTypes = await LocalAuthentication.supportedAuthenticationTypesAsync();
      
      if (hasHardware && isEnrolled) {
        setBiometricsAvailable(true);
        
        if (supportedTypes.includes(LocalAuthentication.AuthenticationType.FACIAL_RECOGNITION)) {
          setBiometricType('Face ID');
        } else if (supportedTypes.includes(LocalAuthentication.AuthenticationType.FINGERPRINT)) {
          setBiometricType('Touch ID');
        } else {
          setBiometricType('Biometric');
        }
      }
    } catch (error) {
      console.error('Biometric check failed:', error);
    }
  };

  const shakeAnimation = () => {
    Animated.sequence([
      Animated.timing(shakeAnim, { toValue: 10, duration: 100, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: -10, duration: 100, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 10, duration: 100, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 0, duration: 100, useNativeDriver: true }),
    ]).start();
  };

  const handleLogin = async () => {
    if (!username.trim() || !password.trim()) {
      Alert.alert(
        t('common.error'),
        isRTL ? 'يرجى إدخال اسم المستخدم وكلمة المرور' : 'Please enter username and password'
      );
      shakeAnimation();
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }

    setIsLoading(true);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);

    try {
      const success = await login(username, password);
      
      if (success) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        navigation.replace('Dashboard');
      } else {
        shakeAnimation();
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
        Alert.alert(
          t('common.error'),
          isRTL ? 'اسم المستخدم أو كلمة المرور غير صحيحة' : 'Invalid username or password'
        );
      }
    } catch (error) {
      Alert.alert(t('common.error'), t('common.error'));
    } finally {
      setIsLoading(false);
    }
  };

  const handleBiometricLogin = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    
    try {
      const success = await loginWithBiometrics();
      
      if (success) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        navigation.replace('Dashboard');
      } else {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      }
    } catch (error) {
      console.error('Biometric login failed:', error);
    }
  };

  return (
    <KeyboardAvoidingView 
      style={styles.container} 
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <StatusBar barStyle="light-content" backgroundColor={BrainSAITColors.midnightBlue} />
      
      <LinearGradient
        colors={[
          BrainSAITColors.midnightBlue,
          BrainSAITColors.medicalBlue,
          BrainSAITColors.signalTeal,
        ]}
        style={styles.gradient}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
      >
        {/* Header Section */}
        <Animated.View
          style={[
            styles.header,
            {
              opacity: fadeAnim,
              transform: [{ translateY: slideAnim }],
            },
          ]}
        >
          <View style={styles.logoContainer}>
            <View style={styles.brainIcon}>
              <View style={styles.brainLeft} />
              <View style={styles.brainRight} />
              <View style={styles.brainCenter} />
            </View>
          </View>
          
          <Text style={styles.welcomeTitle}>
            {t('auth.welcome')}
          </Text>
          <Text style={styles.welcomeSubtitle}>
            {t('auth.subtitle')}
          </Text>
        </Animated.View>

        {/* Login Form */}
        <Animated.View
          style={[
            styles.formContainer,
            {
              opacity: fadeAnim,
              transform: [{ translateY: slideAnim }, { translateX: shakeAnim }],
            },
          ]}
        >
          <View style={styles.form}>
            {/* Username Input */}
            <View style={styles.inputContainer}>
              <Ionicons 
                name="person-outline" 
                size={20} 
                color="rgba(255, 255, 255, 0.7)" 
                style={[styles.inputIcon, isRTL && styles.inputIconRTL]} 
              />
              <TextInput
                style={[styles.input, isRTL && styles.inputRTL]}
                placeholder={t('auth.username')}
                placeholderTextColor="rgba(255, 255, 255, 0.6)"
                value={username}
                onChangeText={setUsername}
                autoCapitalize="none"
                autoCorrect={false}
                textAlign={isRTL ? 'right' : 'left'}
              />
            </View>

            {/* Password Input */}
            <View style={styles.inputContainer}>
              <Ionicons 
                name="lock-closed-outline" 
                size={20} 
                color="rgba(255, 255, 255, 0.7)" 
                style={[styles.inputIcon, isRTL && styles.inputIconRTL]} 
              />
              <TextInput
                style={[styles.input, isRTL && styles.inputRTL]}
                placeholder={t('auth.password')}
                placeholderTextColor="rgba(255, 255, 255, 0.6)"
                value={password}
                onChangeText={setPassword}
                secureTextEntry={!showPassword}
                textAlign={isRTL ? 'right' : 'left'}
              />
              <TouchableOpacity
                style={[styles.eyeIcon, isRTL && styles.eyeIconRTL]}
                onPress={() => setShowPassword(!showPassword)}
              >
                <Ionicons 
                  name={showPassword ? "eye-outline" : "eye-off-outline"} 
                  size={20} 
                  color="rgba(255, 255, 255, 0.7)" 
                />
              </TouchableOpacity>
            </View>

            {/* Login Button */}
            <TouchableOpacity
              style={[styles.loginButton, isLoading && styles.loginButtonDisabled]}
              onPress={handleLogin}
              disabled={isLoading}
            >
              <LinearGradient
                colors={[BrainSAITColors.signalTeal, BrainSAITColors.medicalBlue]}
                style={styles.loginButtonGradient}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 0 }}
              >
                {isLoading ? (
                  <View style={styles.loadingContainer}>
                    <Text style={styles.loginButtonText}>
                      {t('common.loading')}
                    </Text>
                  </View>
                ) : (
                  <Text style={styles.loginButtonText}>
                    {t('auth.login')}
                  </Text>
                )}
              </LinearGradient>
            </TouchableOpacity>

            {/* Biometric Login */}
            {biometricsAvailable && (
              <TouchableOpacity
                style={styles.biometricButton}
                onPress={handleBiometricLogin}
              >
                <Ionicons 
                  name={biometricType === 'Face ID' ? "scan-outline" : "finger-print-outline"} 
                  size={24} 
                  color="rgba(255, 255, 255, 0.8)" 
                />
                <Text style={styles.biometricText}>
                  {t('auth.biometric')}
                </Text>
              </TouchableOpacity>
            )}

            {/* Demo Credentials */}
            <View style={styles.demoContainer}>
              <Text style={styles.demoTitle}>
                {isRTL ? 'حسابات تجريبية:' : 'Demo Accounts:'}
              </Text>
              <Text style={styles.demoCredentials}>
                admin / admin123{'\n'}
                dr.sarah / demo123{'\n'}
                eng.mohammed / demo123{'\n'}
                hr.fatima / demo123
              </Text>
            </View>
          </View>
        </Animated.View>

        {/* Footer */}
        <Animated.View
          style={[
            styles.footer,
            {
              opacity: fadeAnim,
            },
          ]}
        >
          <Text style={styles.footerText}>
            {isRTL ? 'محمي بأعلى معايير الأمان الطبي' : 'Protected by Medical-Grade Security'}
          </Text>
          <View style={styles.securityBadges}>
            <View style={styles.badge}>
              <Text style={styles.badgeText}>HIPAA</Text>
            </View>
            <View style={styles.badge}>
              <Text style={styles.badgeText}>NPHIES</Text>
            </View>
            <View style={styles.badge}>
              <Text style={styles.badgeText}>GDPR</Text>
            </View>
          </View>
        </Animated.View>
      </LinearGradient>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    flex: 1,
    justifyContent: 'space-between',
    paddingHorizontal: 30,
    paddingVertical: 50,
  },
  header: {
    alignItems: 'center',
    paddingTop: 40,
  },
  logoContainer: {
    marginBottom: 30,
  },
  brainIcon: {
    width: 80,
    height: 80,
    position: 'relative',
  },
  brainLeft: {
    position: 'absolute',
    left: 0,
    top: 15,
    width: 35,
    height: 40,
    borderRadius: 20,
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.9)',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  brainRight: {
    position: 'absolute',
    right: 0,
    top: 15,
    width: 35,
    height: 40,
    borderRadius: 20,
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.9)',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  brainCenter: {
    position: 'absolute',
    left: 25,
    top: 25,
    width: 30,
    height: 20,
    borderRadius: 10,
    backgroundColor: BrainSAITColors.signalTeal,
    opacity: 0.8,
  },
  welcomeTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 8,
    textAlign: 'center',
  },
  welcomeSubtitle: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
    textAlign: 'center',
    lineHeight: 22,
  },
  formContainer: {
    flex: 1,
    justifyContent: 'center',
    paddingVertical: 40,
  },
  form: {
    width: '100%',
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 12,
    marginBottom: 20,
    paddingHorizontal: 16,
    height: 56,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  inputIcon: {
    marginRight: 12,
  },
  inputIconRTL: {
    marginRight: 0,
    marginLeft: 12,
  },
  input: {
    flex: 1,
    fontSize: 16,
    color: 'white',
    paddingVertical: 0,
  },
  inputRTL: {
    textAlign: 'right',
  },
  eyeIcon: {
    padding: 4,
  },
  eyeIconRTL: {
    marginLeft: 0,
    marginRight: 8,
  },
  loginButton: {
    borderRadius: 12,
    marginBottom: 20,
    overflow: 'hidden',
  },
  loginButtonDisabled: {
    opacity: 0.7,
  },
  loginButtonGradient: {
    paddingVertical: 16,
    alignItems: 'center',
  },
  loginButtonText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: 'white',
  },
  loadingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  biometricButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 12,
    paddingVertical: 16,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  biometricText: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
    marginLeft: 8,
  },
  demoContainer: {
    backgroundColor: 'rgba(0, 0, 0, 0.2)',
    borderRadius: 12,
    padding: 16,
    marginTop: 20,
  },
  demoTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: 'rgba(255, 255, 255, 0.9)',
    marginBottom: 8,
  },
  demoCredentials: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    fontFamily: 'monospace',
    lineHeight: 18,
  },
  footer: {
    alignItems: 'center',
    paddingBottom: 20,
  },
  footerText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 12,
    textAlign: 'center',
  },
  securityBadges: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 12,
  },
  badge: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 6,
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  badgeText: {
    fontSize: 10,
    color: 'rgba(255, 255, 255, 0.8)',
    fontWeight: 'bold',
  },
});

export default LoginScreen;