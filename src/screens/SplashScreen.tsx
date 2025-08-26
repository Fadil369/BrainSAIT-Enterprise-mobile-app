import React, { useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Animated,
  Dimensions,
  StatusBar,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { useLanguage } from '../contexts/LanguageContext';
import { BrainSAITColors } from '../theme/BrainSAITTheme';

const { width, height } = Dimensions.get('window');

const SplashScreen: React.FC = () => {
  const navigation = useNavigation<any>();
  const { isAuthenticated, isLoading } = useAuth();
  const { colors } = useTheme();
  const { t, isRTL } = useLanguage();
  
  // Animation values
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const scaleAnim = useRef(new Animated.Value(0.5)).current;
  const slideAnim = useRef(new Animated.Value(50)).current;
  const rotateAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    // Start animations
    startAnimations();
    
    // Navigate after splash
    const timer = setTimeout(() => {
      if (isAuthenticated) {
        navigation.replace('Dashboard');
      } else {
        navigation.replace('Login');
      }
    }, 3000);

    return () => clearTimeout(timer);
  }, [isAuthenticated, isLoading]);

  const startAnimations = () => {
    // Fade in animation
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 1000,
      useNativeDriver: true,
    }).start();

    // Scale animation
    Animated.spring(scaleAnim, {
      toValue: 1,
      tension: 50,
      friction: 7,
      useNativeDriver: true,
    }).start();

    // Slide animation
    Animated.timing(slideAnim, {
      toValue: 0,
      duration: 800,
      delay: 300,
      useNativeDriver: true,
    }).start();

    // Rotation animation for logo
    Animated.loop(
      Animated.timing(rotateAnim, {
        toValue: 1,
        duration: 3000,
        useNativeDriver: true,
      })
    ).start();
  };

  const rotateInterpolate = rotateAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ['0deg', '360deg'],
  });

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={BrainSAITColors.midnightBlue} />
      
      {/* Background Gradient */}
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
        {/* Neural Network Pattern */}
        <View style={styles.patternContainer}>
          <View style={[styles.neuralDot, { top: 100, left: 50 }]} />
          <View style={[styles.neuralDot, { top: 150, right: 80 }]} />
          <View style={[styles.neuralDot, { bottom: 200, left: 100 }]} />
          <View style={[styles.neuralDot, { bottom: 150, right: 120 }]} />
          
          {/* Connection Lines */}
          <View style={[styles.connectionLine, { top: 120, left: 60, transform: [{ rotate: '45deg' }] }]} />
          <View style={[styles.connectionLine, { bottom: 180, right: 90, transform: [{ rotate: '-30deg' }] }]} />
        </View>

        {/* Main Content */}
        <View style={styles.content}>
          {/* Logo Section */}
          <Animated.View
            style={[
              styles.logoContainer,
              {
                opacity: fadeAnim,
                transform: [
                  { scale: scaleAnim },
                  { rotate: rotateInterpolate },
                ],
              },
            ]}
          >
            {/* Brain Icon */}
            <View style={styles.brainIcon}>
              <View style={styles.brainLeft} />
              <View style={styles.brainRight} />
              <View style={styles.brainCenter} />
            </View>
          </Animated.View>

          {/* Title Section */}
          <Animated.View
            style={[
              styles.titleContainer,
              {
                opacity: fadeAnim,
                transform: [{ translateY: slideAnim }],
              },
            ]}
          >
            <Text style={[styles.title, { textAlign: isRTL ? 'right' : 'left' }]}>
              BrainSAIT
            </Text>
            <Text style={[styles.subtitle, { textAlign: isRTL ? 'right' : 'left' }]}>
              {isRTL ? 'برينسايت' : 'Enterprise'}
            </Text>
            <Text style={[styles.description, { textAlign: isRTL ? 'right' : 'left' }]}>
              {t('auth.subtitle')}
            </Text>
          </Animated.View>

          {/* Loading Indicator */}
          <Animated.View
            style={[
              styles.loadingContainer,
              {
                opacity: fadeAnim,
                transform: [{ translateY: slideAnim }],
              },
            ]}
          >
            <View style={styles.loadingBar}>
              <Animated.View
                style={[
                  styles.loadingProgress,
                  {
                    transform: [{ scaleX: scaleAnim }],
                  },
                ]}
              />
            </View>
            <Text style={styles.loadingText}>
              {t('common.loading')}
            </Text>
          </Animated.View>
        </View>

        {/* Bottom Branding */}
        <Animated.View
          style={[
            styles.brandingContainer,
            {
              opacity: fadeAnim,
            },
          ]}
        >
          <Text style={styles.brandingText}>
            {isRTL ? 'الذكاء الاصطناعي الطبي' : 'Medical AI Innovation'}
          </Text>
          <View style={styles.brandingLine} />
          <Text style={styles.versionText}>v1.0.0</Text>
        </Animated.View>
      </LinearGradient>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  patternContainer: {
    position: 'absolute',
    width: width,
    height: height,
  },
  neuralDot: {
    position: 'absolute',
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
  },
  connectionLine: {
    position: 'absolute',
    width: 60,
    height: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40,
  },
  logoContainer: {
    marginBottom: 40,
  },
  brainIcon: {
    width: 120,
    height: 120,
    position: 'relative',
  },
  brainLeft: {
    position: 'absolute',
    left: 0,
    top: 20,
    width: 50,
    height: 60,
    borderRadius: 25,
    borderWidth: 3,
    borderColor: 'rgba(255, 255, 255, 0.9)',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  brainRight: {
    position: 'absolute',
    right: 0,
    top: 20,
    width: 50,
    height: 60,
    borderRadius: 25,
    borderWidth: 3,
    borderColor: 'rgba(255, 255, 255, 0.9)',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  brainCenter: {
    position: 'absolute',
    left: 35,
    top: 40,
    width: 50,
    height: 30,
    borderRadius: 15,
    backgroundColor: BrainSAITColors.signalTeal,
    opacity: 0.8,
  },
  titleContainer: {
    alignItems: 'center',
    marginBottom: 60,
  },
  title: {
    fontSize: 48,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 8,
    letterSpacing: 2,
  },
  subtitle: {
    fontSize: 24,
    color: 'rgba(255, 255, 255, 0.9)',
    marginBottom: 16,
    letterSpacing: 1,
  },
  description: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
    textAlign: 'center',
    lineHeight: 24,
  },
  loadingContainer: {
    alignItems: 'center',
    width: '100%',
  },
  loadingBar: {
    width: 200,
    height: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 2,
    marginBottom: 16,
    overflow: 'hidden',
  },
  loadingProgress: {
    height: '100%',
    backgroundColor: BrainSAITColors.signalTeal,
    borderRadius: 2,
  },
  loadingText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    letterSpacing: 0.5,
  },
  brandingContainer: {
    position: 'absolute',
    bottom: 50,
    alignItems: 'center',
  },
  brandingText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 8,
  },
  brandingLine: {
    width: 60,
    height: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.5)',
    marginBottom: 8,
  },
  versionText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
  },
});

export default SplashScreen;