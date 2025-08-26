import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Appearance } from 'react-native';
import { BrainSAITColors } from '../theme/BrainSAITTheme';

export type ThemeMode = 'light' | 'dark' | 'auto';

interface ThemeContextType {
  isDark: boolean;
  themeMode: ThemeMode;
  setThemeMode: (mode: ThemeMode) => Promise<void>;
  colors: typeof BrainSAITColors;
  toggleTheme: () => Promise<void>;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

interface ThemeProviderProps {
  children: ReactNode;
}

export const ThemeProvider: React.FC<ThemeProviderProps> = ({ children }) => {
  const [themeMode, setThemeModeState] = useState<ThemeMode>('dark'); // Default to dark for healthcare
  const [isDark, setIsDark] = useState(true);

  useEffect(() => {
    loadTheme();
    
    // Listen to system appearance changes
    const subscription = Appearance.addChangeListener(({ colorScheme }) => {
      if (themeMode === 'auto') {
        setIsDark(colorScheme === 'dark');
      }
    });

    return () => subscription?.remove();
  }, [themeMode]);

  const loadTheme = async () => {
    try {
      const storedTheme = await AsyncStorage.getItem('themeMode');
      if (storedTheme && ['light', 'dark', 'auto'].includes(storedTheme)) {
        const mode = storedTheme as ThemeMode;
        setThemeModeState(mode);
        updateIsDark(mode);
      } else {
        // Default to dark theme for healthcare/enterprise setting
        setThemeModeState('dark');
        setIsDark(true);
      }
    } catch (error) {
      console.error('Error loading theme:', error);
    }
  };

  const updateIsDark = (mode: ThemeMode) => {
    if (mode === 'auto') {
      const systemScheme = Appearance.getColorScheme();
      setIsDark(systemScheme === 'dark');
    } else {
      setIsDark(mode === 'dark');
    }
  };

  const setThemeMode = async (mode: ThemeMode) => {
    try {
      setThemeModeState(mode);
      await AsyncStorage.setItem('themeMode', mode);
      updateIsDark(mode);
    } catch (error) {
      console.error('Error saving theme:', error);
    }
  };

  const toggleTheme = async () => {
    const newMode: ThemeMode = themeMode === 'dark' ? 'light' : 'dark';
    await setThemeMode(newMode);
  };

  // For healthcare/enterprise context, we primarily use dark theme
  // but we can extend colors for light theme if needed
  const colors = {
    ...BrainSAITColors,
    // Adaptive colors based on theme
    ...(isDark ? {
      background: BrainSAITColors.background,
      surface: BrainSAITColors.surface,
      textPrimary: BrainSAITColors.textPrimary,
      textSecondary: BrainSAITColors.textSecondary,
    } : {
      background: '#ffffff',
      surface: '#f8fafc',
      textPrimary: '#1e293b',
      textSecondary: '#475569',
    })
  };

  const contextValue: ThemeContextType = {
    isDark,
    themeMode,
    setThemeMode,
    colors,
    toggleTheme,
  };

  return (
    <ThemeContext.Provider value={contextValue}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = (): ThemeContextType => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};

export default ThemeContext;