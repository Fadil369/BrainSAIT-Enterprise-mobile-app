import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import * as Localization from 'expo-localization';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { I18nManager } from 'react-native';

export type Language = 'ar' | 'en';

interface LanguageContextType {
  language: Language;
  setLanguage: (lang: Language) => Promise<void>;
  isRTL: boolean;
  t: (key: string, params?: Record<string, string>) => string;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

// Translation strings
const translations = {
  ar: {
    // App Navigation
    'nav.dashboard': 'لوحة التحكم',
    'nav.modules': 'الوحدات',
    'nav.profile': 'الملف الشخصي',
    'nav.settings': 'الإعدادات',
    
    // Authentication
    'auth.login': 'تسجيل الدخول',
    'auth.logout': 'تسجيل الخروج',
    'auth.welcome': 'مرحباً بك في BrainSAIT',
    'auth.subtitle': 'منصة المؤسسة للذكاء الاصطناعي الطبي',
    'auth.biometric': 'استخدم البصمة أو Face ID',
    'auth.username': 'اسم المستخدم',
    'auth.password': 'كلمة المرور',
    
    // Dashboard
    'dashboard.title': 'لوحة التحكم الرئيسية',
    'dashboard.welcome': 'مرحباً بك',
    'dashboard.modules': 'وحدات المؤسسة',
    'dashboard.recent': 'النشاطات الحديثة',
    'dashboard.notifications': 'الإشعارات',
    
    // Modules
    'modules.hr': 'الموارد البشرية',
    'modules.finance': 'المالية',
    'modules.scheduling': 'الجدولة والمناوبات',
    'modules.rd': 'البحث والتطوير',
    'modules.innovation': 'مختبرات الابتكار',
    'modules.performance': 'الأداء ومؤشرات KPI',
    'modules.publications': 'المنشورات',
    'modules.communications': 'الاتصالات',
    'modules.cpd': 'التطوير المهني المستمر',
    'modules.onboarding': 'نظام التأهيل',
    
    // Status
    'status.active': 'نشط',
    'status.inactive': 'غير نشط',
    'status.pending': 'في الانتظار',
    'status.completed': 'مكتمل',
    
    // Common
    'common.loading': 'جاري التحميل...',
    'common.error': 'حدث خطأ',
    'common.success': 'تم بنجاح',
    'common.cancel': 'إلغاء',
    'common.confirm': 'تأكيد',
    'common.save': 'حفظ',
    'common.edit': 'تعديل',
    'common.delete': 'حذف',
    'common.search': 'بحث',
    'common.filter': 'تصفية',
    'common.refresh': 'تحديث',
    'common.more': 'المزيد',
    'common.less': 'أقل',
    
    // Healthcare Specific
    'healthcare.patient': 'مريض',
    'healthcare.doctor': 'طبيب',
    'healthcare.nurse': 'ممرض',
    'healthcare.appointment': 'موعد',
    'healthcare.diagnosis': 'تشخيص',
    'healthcare.treatment': 'علاج',
    'healthcare.medication': 'دواء',
    'healthcare.lab': 'مختبر',
    'healthcare.radiology': 'أشعة',
    'healthcare.emergency': 'طوارئ',
    
    // Compliance
    'compliance.hipaa': 'معايير HIPAA',
    'compliance.nphies': 'معايير NPHIES',
    'compliance.audit': 'مراجعة',
    'compliance.secure': 'آمن',
    'compliance.encrypted': 'مشفر',
  },
  
  en: {
    // App Navigation
    'nav.dashboard': 'Dashboard',
    'nav.modules': 'Modules',
    'nav.profile': 'Profile',
    'nav.settings': 'Settings',
    
    // Authentication
    'auth.login': 'Login',
    'auth.logout': 'Logout',
    'auth.welcome': 'Welcome to BrainSAIT',
    'auth.subtitle': 'Enterprise Platform for Medical AI',
    'auth.biometric': 'Use Touch ID or Face ID',
    'auth.username': 'Username',
    'auth.password': 'Password',
    
    // Dashboard
    'dashboard.title': 'Main Dashboard',
    'dashboard.welcome': 'Welcome',
    'dashboard.modules': 'Enterprise Modules',
    'dashboard.recent': 'Recent Activity',
    'dashboard.notifications': 'Notifications',
    
    // Modules
    'modules.hr': 'Human Resources',
    'modules.finance': 'Finance',
    'modules.scheduling': 'Scheduling & Shifts',
    'modules.rd': 'Research & Development',
    'modules.innovation': 'Innovation Labs',
    'modules.performance': 'Performance & KPIs',
    'modules.publications': 'Publications',
    'modules.communications': 'Communications',
    'modules.cpd': 'Continuous Professional Development',
    'modules.onboarding': 'Onboarding System',
    
    // Status
    'status.active': 'Active',
    'status.inactive': 'Inactive',
    'status.pending': 'Pending',
    'status.completed': 'Completed',
    
    // Common
    'common.loading': 'Loading...',
    'common.error': 'An error occurred',
    'common.success': 'Success',
    'common.cancel': 'Cancel',
    'common.confirm': 'Confirm',
    'common.save': 'Save',
    'common.edit': 'Edit',
    'common.delete': 'Delete',
    'common.search': 'Search',
    'common.filter': 'Filter',
    'common.refresh': 'Refresh',
    'common.more': 'More',
    'common.less': 'Less',
    
    // Healthcare Specific
    'healthcare.patient': 'Patient',
    'healthcare.doctor': 'Doctor',
    'healthcare.nurse': 'Nurse',
    'healthcare.appointment': 'Appointment',
    'healthcare.diagnosis': 'Diagnosis',
    'healthcare.treatment': 'Treatment',
    'healthcare.medication': 'Medication',
    'healthcare.lab': 'Laboratory',
    'healthcare.radiology': 'Radiology',
    'healthcare.emergency': 'Emergency',
    
    // Compliance
    'compliance.hipaa': 'HIPAA Standards',
    'compliance.nphies': 'NPHIES Standards',
    'compliance.audit': 'Audit',
    'compliance.secure': 'Secure',
    'compliance.encrypted': 'Encrypted',
  },
};

interface LanguageProviderProps {
  children: ReactNode;
}

export const LanguageProvider: React.FC<LanguageProviderProps> = ({ children }) => {
  const [language, setLanguageState] = useState<Language>('ar');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadLanguage();
  }, []);

  const loadLanguage = async () => {
    try {
      const storedLanguage = await AsyncStorage.getItem('language');
      if (storedLanguage && (storedLanguage === 'ar' || storedLanguage === 'en')) {
        setLanguageState(storedLanguage as Language);
        await updateRTL(storedLanguage as Language);
      } else {
        // Default to Arabic for BRAINSAIT (Saudi healthcare context)
        const deviceLanguage = Localization.getLocales()[0]?.languageCode?.startsWith('ar') ? 'ar' : 'en';
        setLanguageState(deviceLanguage as Language);
        await updateRTL(deviceLanguage as Language);
      }
    } catch (error) {
      console.error('Error loading language:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const updateRTL = async (lang: Language) => {
    const isRTLLayout = lang === 'ar';
    if (I18nManager.isRTL !== isRTLLayout) {
      I18nManager.allowRTL(isRTLLayout);
      I18nManager.forceRTL(isRTLLayout);
    }
  };

  const setLanguage = async (lang: Language) => {
    try {
      setLanguageState(lang);
      await AsyncStorage.setItem('language', lang);
      await updateRTL(lang);
      
      // Haptic feedback for language switch
      // HapticFeedback.trigger(HapticFeedbackType.impactLight);
    } catch (error) {
      console.error('Error saving language:', error);
    }
  };

  const t = (key: string, params?: Record<string, string>): string => {
    let translation = translations[language][key as keyof typeof translations[typeof language]] || key;
    
    // Replace parameters in translation
    if (params) {
      Object.entries(params).forEach(([param, value]) => {
        translation = translation.replace(new RegExp(`{{${param}}}`, 'g'), value);
      });
    }
    
    return translation;
  };

  const isRTL = language === 'ar';

  if (isLoading) {
    return null; // Or a loading component
  }

  const contextValue: LanguageContextType = {
    language,
    setLanguage,
    isRTL,
    t,
  };

  return (
    <LanguageContext.Provider value={contextValue}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useLanguage = (): LanguageContextType => {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
};

export default LanguageContext;