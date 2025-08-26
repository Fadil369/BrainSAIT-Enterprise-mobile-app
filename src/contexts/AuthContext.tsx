import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import * as LocalAuthentication from 'expo-local-authentication';
import * as SecureStore from 'expo-secure-store';
import AsyncStorage from '@react-native-async-storage/async-storage';

export interface User {
  id: string;
  username: string;
  email: string;
  name: string;
  name_ar: string;
  role: string;
  department: string;
  permissions: string[];
  avatar?: string;
  lastLogin: string;
  isActive: boolean;
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (username: string, password: string) => Promise<boolean>;
  loginWithBiometrics: () => Promise<boolean>;
  logout: () => Promise<void>;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadUserSession();
  }, []);

  const loadUserSession = async () => {
    try {
      const storedUser = await AsyncStorage.getItem('user');
      const authToken = await SecureStore.getItemAsync('authToken');
      
      if (storedUser && authToken) {
        const userData = JSON.parse(storedUser);
        setUser(userData);
      }
    } catch (error) {
      console.error('Error loading user session:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (username: string, password: string): Promise<boolean> => {
    try {
      setIsLoading(true);
      
      // Simulate API call - In real app, this would be an actual API request
      if (username === 'admin' && password === 'admin123') {
        const mockUser: User = {
          id: '1',
          username: 'admin',
          email: 'admin@brainsait.sa',
          name: 'System Administrator',
          name_ar: 'مدير النظام',
          role: 'admin',
          department: 'IT',
          permissions: ['all'],
          avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
          lastLogin: new Date().toISOString(),
          isActive: true,
        };
        
        // Store user data and auth token
        await AsyncStorage.setItem('user', JSON.stringify(mockUser));
        await SecureStore.setItemAsync('authToken', 'mock-jwt-token');
        
        setUser(mockUser);
        return true;
      }
      
      // Demo users for different departments
      const demoUsers: Record<string, User> = {
        'dr.sarah': {
          id: '2',
          username: 'dr.sarah',
          email: 'sarah.ahmed@brainsait.sa',
          name: 'Dr. Sarah Ahmed',
          name_ar: 'د. سارة أحمد',
          role: 'doctor',
          department: 'Clinical AI',
          permissions: ['clinical', 'research', 'publications'],
          avatar: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400',
          lastLogin: new Date().toISOString(),
          isActive: true,
        },
        'eng.mohammed': {
          id: '3',
          username: 'eng.mohammed',
          email: 'mohammed.ali@brainsait.sa',
          name: 'Eng. Mohammed Al-Ali',
          name_ar: 'م. محمد العلي',
          role: 'engineer',
          department: 'Engineering',
          permissions: ['development', 'systems', 'integration'],
          avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
          lastLogin: new Date().toISOString(),
          isActive: true,
        },
        'hr.fatima': {
          id: '4',
          username: 'hr.fatima',
          email: 'fatima.zahrani@brainsait.sa',
          name: 'Fatima Al-Zahrani',
          name_ar: 'فاطمة الزهراني',
          role: 'hr_manager',
          department: 'Human Resources',
          permissions: ['hr', 'compliance', 'onboarding'],
          avatar: 'https://images.unsplash.com/photo-1594824804732-da5dcb665b7d?w=400',
          lastLogin: new Date().toISOString(),
          isActive: true,
        },
      };
      
      if (demoUsers[username] && password === 'demo123') {
        await AsyncStorage.setItem('user', JSON.stringify(demoUsers[username]));
        await SecureStore.setItemAsync('authToken', `mock-jwt-token-${username}`);
        setUser(demoUsers[username]);
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('Login error:', error);
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const loginWithBiometrics = async (): Promise<boolean> => {
    try {
      // Check if biometric authentication is available
      const hasHardware = await LocalAuthentication.hasHardwareAsync();
      const supportedTypes = await LocalAuthentication.supportedAuthenticationTypesAsync();
      const isEnrolled = await LocalAuthentication.isEnrolledAsync();
      
      if (!hasHardware || !isEnrolled) {
        return false;
      }
      
      // Attempt biometric authentication
      const result = await LocalAuthentication.authenticateAsync({
        promptMessage: 'Authenticate to access BrainSAIT Enterprise',
        fallbackLabel: 'Use passcode',
        cancelLabel: 'Cancel',
        disableDeviceFallback: false,
      });
      
      if (result.success) {
        // Get stored credentials
        const storedUser = await AsyncStorage.getItem('user');
        const authToken = await SecureStore.getItemAsync('authToken');
        
        if (storedUser && authToken) {
          const userData = JSON.parse(storedUser);
          // Update last login
          userData.lastLogin = new Date().toISOString();
          await AsyncStorage.setItem('user', JSON.stringify(userData));
          setUser(userData);
          return true;
        }
      }
      
      return false;
    } catch (error) {
      console.error('Biometric login error:', error);
      return false;
    }
  };

  const logout = async (): Promise<void> => {
    try {
      setIsLoading(true);
      
      // Clear stored data
      await AsyncStorage.removeItem('user');
      await SecureStore.deleteItemAsync('authToken');
      
      setUser(null);
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const refreshUser = async (): Promise<void> => {
    try {
      const storedUser = await AsyncStorage.getItem('user');
      if (storedUser) {
        const userData = JSON.parse(storedUser);
        setUser(userData);
      }
    } catch (error) {
      console.error('Error refreshing user:', error);
    }
  };

  const contextValue: AuthContextType = {
    user,
    isAuthenticated: !!user,
    isLoading,
    login,
    loginWithBiometrics,
    logout,
    refreshUser,
  };

  return (
    <AuthContext.Provider value={contextValue}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export default AuthContext;