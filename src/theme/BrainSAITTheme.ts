import { DefaultTheme } from '@react-navigation/native';
import { MD3DarkTheme } from 'react-native-paper';

// BRAINSAIT: Official brand colors and design system
export const BrainSAITColors = {
  // Primary Colors
  midnightBlue: '#1a365d',
  medicalBlue: '#2b6cb8',
  signalTeal: '#0ea5e9',
  deepOrange: '#ea580c',
  professionalGray: '#64748b',
  
  // Extended Palette
  primary: '#0ea5e9',
  secondary: '#2b6cb8',
  tertiary: '#ea580c',
  background: '#0f172a',
  surface: '#1e293b',
  
  // Semantic Colors
  success: '#10b981',
  warning: '#f59e0b',
  error: '#ef4444',
  info: '#3b82f6',
  
  // Text Colors
  textPrimary: '#f8fafc',
  textSecondary: '#cbd5e1',
  textMuted: '#64748b',
  
  // Border Colors
  border: '#334155',
  borderLight: '#475569',
  
  // Status Colors
  active: '#10b981',
  inactive: '#64748b',
  pending: '#f59e0b',
  
  // Gradient Colors
  gradients: {
    primary: ['#0ea5e9', '#2b6cb8'],
    secondary: ['#1a365d', '#2b6cb8'],
    accent: ['#ea580c', '#f59e0b'],
    surface: ['#1e293b', '#334155'],
  }
};

// Navigation Theme
export const BrainSAITNavigationTheme = {
  ...DefaultTheme,
  dark: true,
  colors: {
    ...DefaultTheme.colors,
    primary: BrainSAITColors.primary,
    background: BrainSAITColors.background,
    card: BrainSAITColors.surface,
    text: BrainSAITColors.textPrimary,
    border: BrainSAITColors.border,
    notification: BrainSAITColors.primary,
  },
};

// Paper Theme
export const BrainSAITTheme = {
  ...MD3DarkTheme,
  colors: {
    ...MD3DarkTheme.colors,
    primary: BrainSAITColors.primary,
    secondary: BrainSAITColors.secondary,
    tertiary: BrainSAITColors.tertiary,
    background: BrainSAITColors.background,
    surface: BrainSAITColors.surface,
    surfaceVariant: BrainSAITColors.surface,
    onSurface: BrainSAITColors.textPrimary,
    onBackground: BrainSAITColors.textPrimary,
    outline: BrainSAITColors.border,
    error: BrainSAITColors.error,
  },
};

// Typography
export const BrainSAITTypography = {
  // Arabic Typography
  arabic: {
    fontFamily: 'Cairo',
    fontSize: {
      xs: 12,
      sm: 14,
      md: 16,
      lg: 18,
      xl: 20,
      xxl: 24,
      xxxl: 32,
    },
    lineHeight: {
      xs: 16,
      sm: 20,
      md: 24,
      lg: 28,
      xl: 32,
      xxl: 36,
      xxxl: 48,
    },
  },
  
  // English Typography
  english: {
    fontFamily: 'Inter',
    fontSize: {
      xs: 12,
      sm: 14,
      md: 16,
      lg: 18,
      xl: 20,
      xxl: 24,
      xxxl: 32,
    },
    lineHeight: {
      xs: 16,
      sm: 20,
      md: 22,
      lg: 26,
      xl: 30,
      xxl: 34,
      xxxl: 44,
    },
  },
};

// Spacing System
export const BrainSAITSpacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
  xxxl: 64,
};

// Border Radius
export const BrainSAITBorderRadius = {
  xs: 4,
  sm: 6,
  md: 8,
  lg: 12,
  xl: 16,
  xxl: 20,
  xxxl: 24,
  round: 9999,
};

// Shadows
export const BrainSAITShadows = {
  sm: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.18,
    shadowRadius: 1.0,
    elevation: 1,
  },
  md: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.23,
    shadowRadius: 2.62,
    elevation: 4,
  },
  lg: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.30,
    shadowRadius: 4.65,
    elevation: 8,
  },
  xl: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.44,
    shadowRadius: 10.32,
    elevation: 16,
  },
};

// Animation Durations
export const BrainSAITAnimations = {
  fast: 200,
  normal: 300,
  slow: 500,
  verySlow: 800,
};

// Healthcare Specific Colors
export const HealthcareColors = {
  // Clinical Colors
  clinical: '#2563eb',
  diagnostic: '#7c3aed',
  emergency: '#dc2626',
  routine: '#059669',
  
  // Compliance Colors
  compliant: '#10b981',
  nonCompliant: '#ef4444',
  pending: '#f59e0b',
  audit: '#6366f1',
  
  // Department Colors
  hr: '#10b981',
  finance: '#f59e0b',
  scheduling: '#8b5cf6',
  research: '#06b6d4',
  innovation: '#f59e0b',
  performance: '#10b981',
  publications: '#6366f1',
  communications: '#ec4899',
  cpd: '#14b8a6',
  onboarding: '#3b82f6',
};

export default {
  colors: BrainSAITColors,
  navigation: BrainSAITNavigationTheme,
  paper: BrainSAITTheme,
  typography: BrainSAITTypography,
  spacing: BrainSAITSpacing,
  borderRadius: BrainSAITBorderRadius,
  shadows: BrainSAITShadows,
  animations: BrainSAITAnimations,
  healthcare: HealthcareColors,
};