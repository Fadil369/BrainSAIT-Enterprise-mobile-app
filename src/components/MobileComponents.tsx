import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Animated,
  Dimensions,
  Platform,
  Alert,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import * as Haptics from 'expo-haptics';
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Ionicons } from '@expo/vector-icons';
import { BrainSAITColors } from '../theme/BrainSAITTheme';

const { width, height } = Dimensions.get('window');

// Configure notifications
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

// Mobile-optimized Card Component
export const MobileCard: React.FC<{
  children: React.ReactNode;
  gradient?: string[];
  onPress?: () => void;
  style?: any;
}> = ({ children, gradient, onPress, style }) => {
  const [pressed, setPressed] = useState(false);

  const cardContent = (
    <BlurView 
      intensity={20} 
      tint="dark" 
      style={[styles.mobileCard, style]}
    >
      {children}
    </BlurView>
  );

  if (onPress) {
    return (
      <TouchableOpacity
        onPress={() => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
          onPress();
        }}
        onPressIn={() => setPressed(true)}
        onPressOut={() => setPressed(false)}
        activeOpacity={0.8}
        style={[styles.cardContainer, pressed && styles.cardPressed]}
      >
        {gradient && gradient.length >= 2 ? (
          <LinearGradient
            colors={gradient as any}
            style={styles.cardGradient}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
          >
            {cardContent}
          </LinearGradient>
        ) : (
          cardContent
        )}
      </TouchableOpacity>
    );
  }

  return gradient && gradient.length >= 2 ? (
    <LinearGradient
      colors={gradient as any}
      style={styles.cardGradient}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
    >
      {cardContent}
    </LinearGradient>
  ) : (
    cardContent
  );
};

// Notification Handler Component
export const NotificationManager: React.FC = () => {
  const [expoPushToken, setExpoPushToken] = useState<string>('');
  const [channels, setChannels] = useState<Notifications.NotificationChannel[]>([]);

  useEffect(() => {
    registerForPushNotificationsAsync().then((token) => {
      if (token) {
        setExpoPushToken(token);
      }
    });

    if (Platform.OS === 'android') {
      Notifications.getNotificationChannelsAsync().then((value) =>
        setChannels(value ?? [])
      );
    }

    const notificationListener = Notifications.addNotificationReceivedListener(
      (notification) => {
        console.log('Notification received:', notification);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      }
    );

    const responseListener = Notifications.addNotificationResponseReceivedListener(
      (response) => {
        console.log('Notification response:', response);
      }
    );

    return () => {
      Notifications.removeNotificationSubscription(notificationListener);
      Notifications.removeNotificationSubscription(responseListener);
    };
  }, []);

  return null; // This component doesn't render anything
};

// Mobile-specific Loading Component
export const MobileLoadingSpinner: React.FC<{
  size?: 'small' | 'large';
  color?: string;
}> = ({ size = 'small', color = BrainSAITColors.signalTeal }) => {
  const spinValue = new Animated.Value(0);

  useEffect(() => {
    const spin = () => {
      spinValue.setValue(0);
      Animated.timing(spinValue, {
        toValue: 1,
        duration: 1000,
        useNativeDriver: true,
      }).start(() => spin());
    };
    spin();
  }, []);

  const spinInterpolate = spinValue.interpolate({
    inputRange: [0, 1],
    outputRange: ['0deg', '360deg'],
  });

  return (
    <Animated.View
      style={[
        styles.spinner,
        size === 'large' && styles.spinnerLarge,
        { transform: [{ rotate: spinInterpolate }] },
      ]}
    >
      <View style={[styles.spinnerInner, { borderTopColor: color }]} />
    </Animated.View>
  );
};

// Mobile Status Indicator
export const MobileStatusIndicator: React.FC<{
  status: 'online' | 'offline' | 'connecting';
  size?: number;
}> = ({ status, size = 12 }) => {
  const [pulseAnim] = useState(new Animated.Value(1));

  useEffect(() => {
    if (status === 'connecting') {
      const pulse = () => {
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 1.3,
            duration: 600,
            useNativeDriver: true,
          }),
          Animated.timing(pulseAnim, {
            toValue: 1,
            duration: 600,
            useNativeDriver: true,
          }),
        ]).start(() => pulse());
      };
      pulse();
    } else {
      pulseAnim.setValue(1);
    }
  }, [status]);

  const getStatusColor = () => {
    switch (status) {
      case 'online':
        return BrainSAITColors.success;
      case 'offline':
        return BrainSAITColors.error;
      case 'connecting':
        return BrainSAITColors.warning;
      default:
        return BrainSAITColors.textMuted;
    }
  };

  return (
    <Animated.View
      style={[
        styles.statusIndicator,
        {
          width: size,
          height: size,
          borderRadius: size / 2,
          backgroundColor: getStatusColor(),
          transform: [{ scale: pulseAnim }],
        },
      ]}
    />
  );
};

// Mobile Bottom Sheet Component
export const MobileBottomSheet: React.FC<{
  visible: boolean;
  onClose: () => void;
  children: React.ReactNode;
  title?: string;
}> = ({ visible, onClose, children, title }) => {
  const [slideAnim] = useState(new Animated.Value(height));

  useEffect(() => {
    if (visible) {
      Animated.spring(slideAnim, {
        toValue: 0,
        useNativeDriver: true,
        tension: 50,
        friction: 8,
      }).start();
    } else {
      Animated.timing(slideAnim, {
        toValue: height,
        duration: 300,
        useNativeDriver: true,
      }).start();
    }
  }, [visible]);

  if (!visible) return null;

  return (
    <View style={styles.bottomSheetOverlay}>
      <TouchableOpacity
        style={styles.bottomSheetBackdrop}
        onPress={onClose}
        activeOpacity={1}
      />
      
      <Animated.View
        style={[
          styles.bottomSheet,
          {
            transform: [{ translateY: slideAnim }],
          },
        ]}
      >
        <View style={styles.bottomSheetHandle} />
        
        {title && (
          <View style={styles.bottomSheetHeader}>
            <Text style={styles.bottomSheetTitle}>{title}</Text>
            <TouchableOpacity onPress={onClose} style={styles.bottomSheetCloseButton}>
              <Ionicons name="close" size={24} color={BrainSAITColors.textSecondary} />
            </TouchableOpacity>
          </View>
        )}
        
        <View style={styles.bottomSheetContent}>
          {children}
        </View>
      </Animated.View>
    </View>
  );
};

// Helper function for push notifications
async function registerForPushNotificationsAsync(): Promise<string | null> {
  let token;

  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('default', {
      name: 'default',
      importance: Notifications.AndroidImportance.MAX,
      vibrationPattern: [0, 250, 250, 250],
      lightColor: BrainSAITColors.signalTeal,
    });
  }

  if (Device.isDevice) {
    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;
    if (existingStatus !== 'granted') {
      const { status } = await Notifications.requestPermissionsAsync();
      finalStatus = status;
    }
    if (finalStatus !== 'granted') {
      Alert.alert(
        'Push Notifications',
        'Failed to get push token for push notification!'
      );
      return null;
    }
    
    // Get the project ID from app.json/app.config.js
    try {
      token = (await Notifications.getExpoPushTokenAsync({
        projectId: 'your-project-id', // Replace with actual project ID
      })).data;
    } catch (error) {
      console.log('Error getting push token:', error);
      return null;
    }
  } else {
    Alert.alert('Must use physical device for Push Notifications');
  }

  return token || null;
}

// Utility function to schedule local notifications
export const scheduleLocalNotification = async (
  title: string,
  body: string,
  data?: any,
  trigger?: Notifications.NotificationTriggerInput
) => {
  await Notifications.scheduleNotificationAsync({
    content: {
      title,
      body,
      data,
      sound: 'default',
    },
    trigger: trigger || null,
  });
};

const styles = StyleSheet.create({
  cardContainer: {
    borderRadius: 16,
    overflow: 'hidden',
    marginVertical: 8,
  },
  cardPressed: {
    transform: [{ scale: 0.98 }],
  },
  cardGradient: {
    borderRadius: 16,
  },
  mobileCard: {
    padding: 16,
    borderRadius: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  spinner: {
    width: 20,
    height: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  spinnerLarge: {
    width: 40,
    height: 40,
  },
  spinnerInner: {
    width: '100%',
    height: '100%',
    borderRadius: 50,
    borderWidth: 2,
    borderColor: 'transparent',
    borderTopColor: BrainSAITColors.signalTeal,
  },
  statusIndicator: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 2,
    elevation: 3,
  },
  bottomSheetOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 1000,
  },
  bottomSheetBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  bottomSheet: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: BrainSAITColors.surface,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    maxHeight: height * 0.9,
  },
  bottomSheetHandle: {
    width: 40,
    height: 4,
    backgroundColor: BrainSAITColors.textMuted,
    borderRadius: 2,
    alignSelf: 'center',
    marginTop: 8,
    marginBottom: 16,
  },
  bottomSheetHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: BrainSAITColors.border,
  },
  bottomSheetTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: BrainSAITColors.textPrimary,
  },
  bottomSheetCloseButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: BrainSAITColors.background,
    justifyContent: 'center',
    alignItems: 'center',
  },
  bottomSheetContent: {
    paddingHorizontal: 20,
    paddingBottom: 32,
  },
});

export default {
  MobileCard,
  NotificationManager,
  MobileLoadingSpinner,
  MobileStatusIndicator,
  MobileBottomSheet,
  scheduleLocalNotification,
};