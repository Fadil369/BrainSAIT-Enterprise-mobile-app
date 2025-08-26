import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Dimensions,
  StatusBar,
  RefreshControl,
  Animated,
  SafeAreaView,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import * as Haptics from 'expo-haptics';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../contexts/AuthContext';
import { useLanguage } from '../contexts/LanguageContext';
import { useTheme } from '../contexts/ThemeContext';
import { BrainSAITColors, HealthcareColors } from '../theme/BrainSAITTheme';

const { width, height } = Dimensions.get('window');

// Enterprise Modules Configuration
const enterpriseModules = [
  {
    id: 'hr',
    name: 'الموارد البشرية',
    name_en: 'Human Resources',
    icon: 'people-outline',
    color: HealthcareColors.hr,
    gradient: [HealthcareColors.hr, '#059669'],
    category: 'core_business',
    status: 'active',
    metrics: { employees: 1247, newHires: 23, retention: 94.2 },
    description: 'إدارة شاملة للموارد البشرية مع نظام إدارة دورة حياة الموظف',
    description_en: 'Comprehensive HR management with employee lifecycle system'
  },
  {
    id: 'finance',
    name: 'المالية',
    name_en: 'Finance',
    icon: 'card-outline',
    color: HealthcareColors.finance,
    gradient: [HealthcareColors.finance, '#f59e0b'],
    category: 'core_business',
    status: 'active',
    metrics: { budget: 850000, expenses: 1523, automation: 87.3 },
    description: 'النظام المالي المتكامل مع إدارة الرواتب والميزانيات',
    description_en: 'Integrated financial system with payroll and budget management'
  },
  {
    id: 'scheduling',
    name: 'الجدولة والمناوبات',
    name_en: 'Scheduling & Shifts',
    icon: 'calendar-outline',
    color: HealthcareColors.scheduling,
    gradient: [HealthcareColors.scheduling, '#a855f7'],
    category: 'core_business',
    status: 'active',
    metrics: { shifts: 156, coverage: 99.2, swaps: 43 },
    description: 'إدارة المناوبات والجداول الطبية المعقدة',
    description_en: 'Complex medical shift and schedule management'
  },
  {
    id: 'research',
    name: 'البحث والتطوير',
    name_en: 'Research & Development',
    icon: 'flask-outline',
    color: HealthcareColors.research,
    gradient: [HealthcareColors.research, '#0891b2'],
    category: 'innovation',
    status: 'active',
    metrics: { projects: 34, studies: 127, publications: 89 },
    description: 'مختبرات البحث الطبي والتطوير التقني',
    description_en: 'Medical research labs and technical development'
  },
  {
    id: 'innovation',
    name: 'مختبرات الابتكار',
    name_en: 'Innovation Labs',
    icon: 'bulb-outline',
    color: HealthcareColors.innovation,
    gradient: [HealthcareColors.innovation, '#fbbf24'],
    category: 'innovation',
    status: 'active',
    metrics: { innovations: 18, patents: 12, prototypes: 45 },
    description: 'مختبرات الابتكار في الذكاء الاصطناعي الطبي',
    description_en: 'Medical AI innovation laboratories'
  },
  {
    id: 'performance',
    name: 'الأداء ومؤشرات KPI',
    name_en: 'Performance & KPIs',
    icon: 'trending-up-outline',
    color: HealthcareColors.performance,
    gradient: [HealthcareColors.performance, '#10b981'],
    category: 'performance',
    status: 'active',
    metrics: { kpis: 87, score: 92.1, goals: 85.6 },
    description: 'مراقبة الأداء الشاملة مع مؤشرات الأداء الرئيسية',
    description_en: 'Comprehensive performance tracking with key indicators'
  },
  {
    id: 'publications',
    name: 'المنشورات',
    name_en: 'Publications',
    icon: 'book-outline',
    color: HealthcareColors.publications,
    gradient: [HealthcareColors.publications, '#8b5cf6'],
    category: 'innovation',
    status: 'active',
    metrics: { papers: 156, citations: 2847, hIndex: 34 },
    description: 'إدارة المنشورات العلمية والبحثية',
    description_en: 'Scientific and research publication management'
  },
  {
    id: 'communications',
    name: 'الاتصالات',
    name_en: 'Communications',
    icon: 'chatbubble-ellipses-outline',
    color: HealthcareColors.communications,
    gradient: [HealthcareColors.communications, '#f472b6'],
    category: 'performance',
    status: 'active',
    metrics: { messages: 15670, response: 94.2, satisfaction: 4.6 },
    description: 'قنوات الاتصال الداخلية والخارجية',
    description_en: 'Internal and external communication channels'
  },
  {
    id: 'cpd',
    name: 'التطوير المهني المستمر',
    name_en: 'Continuous Professional Development',
    icon: 'medal-outline',
    color: HealthcareColors.cpd,
    gradient: [HealthcareColors.cpd, '#06b6d4'],
    category: 'performance',
    status: 'active',
    metrics: { learners: 1156, courses: 3423, certs: 287 },
    description: 'برامج التطوير المهني والتعليم المستمر',
    description_en: 'Professional development and continuing education programs'
  },
  {
    id: 'onboarding',
    name: 'نظام التأهيل',
    name_en: 'Onboarding System',
    icon: 'person-add-outline',
    color: HealthcareColors.onboarding,
    gradient: [HealthcareColors.onboarding, '#60a5fa'],
    category: 'healthcare',
    status: 'active',
    metrics: { sessions: 156, completion: 97.3, satisfaction: 4.8 },
    description: 'منصة تأهيل الموظفين الجدد مع المحتوى الطبي',
    description_en: 'New employee onboarding platform with medical content'
  },
];

const MainDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const { t, isRTL, language } = useLanguage();
  const { colors } = useTheme();
  
  const [refreshing, setRefreshing] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('all');
  
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const slideAnim = useRef(new Animated.Value(30)).current;

  useEffect(() => {
    startAnimations();
  }, []);

  const startAnimations = () => {
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 800,
      useNativeDriver: true,
    }).start();

    Animated.timing(slideAnim, {
      toValue: 0,
      duration: 600,
      useNativeDriver: true,
    }).start();
  };

  const onRefresh = React.useCallback(() => {
    setRefreshing(true);
    // Simulate refresh
    setTimeout(() => {
      setRefreshing(false);
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }, 1000);
  }, []);

  const handleModulePress = (module: any) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    // Navigate to module detail screen
    console.log(`Navigate to ${module.id} module`);
  };

  const categories = [
    { id: 'all', name: 'الكل', name_en: 'All' },
    { id: 'core_business', name: 'العمليات الأساسية', name_en: 'Core Business' },
    { id: 'innovation', name: 'الابتكار والبحث', name_en: 'Innovation' },
    { id: 'performance', name: 'الأداء والنمو', name_en: 'Performance' },
    { id: 'healthcare', name: 'الرعاية الصحية', name_en: 'Healthcare' },
  ];

  const filteredModules = selectedCategory === 'all' 
    ? enterpriseModules 
    : enterpriseModules.filter(module => module.category === selectedCategory);

  const renderHeader = () => (
    <Animated.View
      style={[
        styles.header,
        {
          opacity: fadeAnim,
          transform: [{ translateY: slideAnim }],
        },
      ]}
    >
      <LinearGradient
        colors={[BrainSAITColors.midnightBlue, BrainSAITColors.medicalBlue]}
        style={styles.headerGradient}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
      >
        <SafeAreaView>
          <View style={styles.headerContent}>
            <View style={styles.userSection}>
              <View style={styles.avatar}>
                <Ionicons name="person" size={24} color="white" />
              </View>
              <View style={styles.userInfo}>
                <Text style={[styles.welcomeText, { textAlign: isRTL ? 'right' : 'left' }]}>
                  {t('dashboard.welcome')}
                </Text>
                <Text style={[styles.userName, { textAlign: isRTL ? 'right' : 'left' }]}>
                  {language === 'ar' ? user?.name_ar || user?.name : user?.name}
                </Text>
                <Text style={[styles.userRole, { textAlign: isRTL ? 'right' : 'left' }]}>
                  {user?.role} • {user?.department}
                </Text>
              </View>
            </View>
            
            <View style={styles.headerActions}>
              <TouchableOpacity style={styles.notificationButton}>
                <Ionicons name="notifications-outline" size={24} color="white" />
                <View style={styles.notificationBadge} />
              </TouchableOpacity>
              
              <TouchableOpacity style={styles.settingsButton} onPress={logout}>
                <Ionicons name="log-out-outline" size={24} color="white" />
              </TouchableOpacity>
            </View>
          </View>
        </SafeAreaView>
      </LinearGradient>
    </Animated.View>
  );

  const renderCategoryFilter = () => (
    <Animated.View
      style={[
        styles.categoryFilter,
        {
          opacity: fadeAnim,
          transform: [{ translateY: slideAnim }],
        },
      ]}
    >
      <ScrollView 
        horizontal 
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.categoryScrollContent}
      >
        {categories.map((category) => (
          <TouchableOpacity
            key={category.id}
            style={[
              styles.categoryButton,
              selectedCategory === category.id && styles.categoryButtonActive,
            ]}
            onPress={() => {
              setSelectedCategory(category.id);
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            }}
          >
            <Text
              style={[
                styles.categoryButtonText,
                selectedCategory === category.id && styles.categoryButtonTextActive,
              ]}
            >
              {language === 'ar' ? category.name : category.name_en}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </Animated.View>
  );

  const renderModuleCard = (module: any, index: number) => (
    <Animated.View
      key={module.id}
      style={[
        styles.moduleCard,
        {
          opacity: fadeAnim,
          transform: [
            { translateY: slideAnim },
            {
              translateX: fadeAnim.interpolate({
                inputRange: [0, 1],
                outputRange: [index % 2 === 0 ? -50 : 50, 0],
              }),
            },
          ],
        },
      ]}
    >
      <TouchableOpacity
        style={styles.moduleCardContent}
        onPress={() => handleModulePress(module)}
        activeOpacity={0.8}
      >
        <LinearGradient
          colors={module.gradient}
          style={styles.moduleCardGradient}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          <BlurView intensity={20} tint="dark" style={styles.moduleCardOverlay}>
            <View style={styles.moduleCardHeader}>
              <View style={styles.moduleIcon}>
                <Ionicons name={module.icon as any} size={28} color="white" />
              </View>
              <View style={[styles.moduleStatus, { 
                backgroundColor: module.status === 'active' ? HealthcareColors.compliant : HealthcareColors.pending 
              }]} />
            </View>
            
            <View style={styles.moduleCardBody}>
              <Text style={[styles.moduleName, { textAlign: isRTL ? 'right' : 'left' }]}>
                {language === 'ar' ? module.name : module.name_en}
              </Text>
              <Text style={[styles.moduleDescription, { textAlign: isRTL ? 'right' : 'left' }]}>
                {language === 'ar' ? module.description : module.description_en}
              </Text>
            </View>
            
            <View style={styles.moduleMetrics}>
              {Object.entries(module.metrics).slice(0, 2).map(([key, value]) => (
                <View key={key} style={styles.metric}>
                  <Text style={styles.metricValue}>
                    {typeof value === 'number' 
                      ? (value > 1000 ? `${(value/1000).toFixed(1)}K` : value.toString())
                      : String(value)
                    }
                  </Text>
                  <Text style={styles.metricLabel}>
                    {key.replace('_', ' ').toUpperCase()}
                  </Text>
                </View>
              ))}
            </View>
            
            <View style={styles.moduleCardFooter}>
              <Text style={styles.categoryTag}>
                {categories.find(c => c.id === module.category)?.[language === 'ar' ? 'name' : 'name_en']}
              </Text>
              <Ionicons 
                name={isRTL ? "chevron-back-outline" : "chevron-forward-outline"} 
                size={20} 
                color="rgba(255, 255, 255, 0.7)" 
              />
            </View>
          </BlurView>
        </LinearGradient>
      </TouchableOpacity>
    </Animated.View>
  );

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={BrainSAITColors.midnightBlue} />
      
      {renderHeader()}
      
      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            colors={[BrainSAITColors.signalTeal]}
            tintColor={BrainSAITColors.signalTeal}
          />
        }
        showsVerticalScrollIndicator={false}
      >
        {renderCategoryFilter()}
        
        <View style={styles.modulesGrid}>
          {filteredModules.map((module, index) => renderModuleCard(module, index))}
        </View>
        
        <View style={styles.bottomSpacing} />
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: BrainSAITColors.background,
  },
  header: {
    zIndex: 10,
  },
  headerGradient: {
    paddingBottom: 20,
  },
  headerContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingHorizontal: 20,
    paddingTop: 20,
  },
  userSection: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  avatar: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 15,
  },
  userInfo: {
    flex: 1,
  },
  welcomeText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: 4,
  },
  userName: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 2,
  },
  userRole: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  notificationButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
    position: 'relative',
  },
  notificationBadge: {
    position: 'absolute',
    top: 8,
    right: 8,
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: BrainSAITColors.error,
  },
  settingsButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    flex: 1,
  },
  categoryFilter: {
    paddingVertical: 20,
  },
  categoryScrollContent: {
    paddingHorizontal: 20,
  },
  categoryButton: {
    paddingHorizontal: 20,
    paddingVertical: 10,
    marginRight: 12,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  categoryButtonActive: {
    backgroundColor: BrainSAITColors.signalTeal,
    borderColor: BrainSAITColors.signalTeal,
  },
  categoryButtonText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    fontWeight: '500',
  },
  categoryButtonTextActive: {
    color: 'white',
    fontWeight: 'bold',
  },
  modulesGrid: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  moduleCard: {
    marginBottom: 16,
    borderRadius: 16,
    overflow: 'hidden',
  },
  moduleCardContent: {
    borderRadius: 16,
  },
  moduleCardGradient: {
    borderRadius: 16,
  },
  moduleCardOverlay: {
    padding: 20,
    borderRadius: 16,
  },
  moduleCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  moduleIcon: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  moduleStatus: {
    width: 12,
    height: 12,
    borderRadius: 6,
  },
  moduleCardBody: {
    marginBottom: 20,
  },
  moduleName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 8,
  },
  moduleDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    lineHeight: 20,
  },
  moduleMetrics: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  metric: {
    alignItems: 'center',
  },
  metricValue: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'white',
  },
  metricLabel: {
    fontSize: 10,
    color: 'rgba(255, 255, 255, 0.7)',
    marginTop: 2,
  },
  moduleCardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  categoryTag: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  bottomSpacing: {
    height: 100,
  },
});

export default MainDashboard;