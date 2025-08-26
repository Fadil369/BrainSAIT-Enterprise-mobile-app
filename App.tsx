import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { Provider as PaperProvider } from 'react-native-paper';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AuthProvider } from './src/contexts/AuthContext';
import { LanguageProvider } from './src/contexts/LanguageContext';
import { ThemeProvider } from './src/contexts/ThemeContext';

// Import Screens
import SplashScreen from './src/screens/SplashScreen';
import LoginScreen from './src/screens/LoginScreen';
import MainDashboard from './src/screens/MainDashboard';
import { BrainSAITTheme, BrainSAITNavigationTheme } from './src/theme/BrainSAITTheme';

const Stack = createStackNavigator();

export default function App() {
  return (
    <SafeAreaProvider>
      <ThemeProvider>
        <LanguageProvider>
          <AuthProvider>
            <PaperProvider theme={BrainSAITTheme}>
              <NavigationContainer theme={BrainSAITNavigationTheme}>
                <Stack.Navigator 
                  initialRouteName="Splash"
                  screenOptions={{
                    headerShown: false,
                    gestureEnabled: true,
                    cardStyleInterpolator: ({ current, layouts }) => {
                      return {
                        cardStyle: {
                          transform: [
                            {
                              translateX: current.progress.interpolate({
                                inputRange: [0, 1],
                                outputRange: [layouts.screen.width, 0],
                              }),
                            },
                          ],
                        },
                      };
                    },
                  }}
                >
                  <Stack.Screen name="Splash" component={SplashScreen} />
                  <Stack.Screen name="Login" component={LoginScreen} />
                  <Stack.Screen name="Dashboard" component={MainDashboard} />
                </Stack.Navigator>
                <StatusBar style="light" backgroundColor="#1a365d" />
              </NavigationContainer>
            </PaperProvider>
          </AuthProvider>
        </LanguageProvider>
      </ThemeProvider>
    </SafeAreaProvider>
  );
}
