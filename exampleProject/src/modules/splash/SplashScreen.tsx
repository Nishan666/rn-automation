import React, { useEffect } from 'react';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useSplashStore } from './splashStore';

export const SplashScreen: React.FC = () => {
  const navigation = useNavigation();
  const { checkSession, session, isLoading, error } = useSplashStore();

  useEffect(() => {
    checkSession();
  }, [checkSession]);

  useEffect(() => {
    if (!isLoading && session !== null) {
      if (session.isAuthenticated) {
          navigation.reset({
            index: 0,
            routes: [{ name: 'Home' }],
          });
        } else {
          navigation.reset({
            index: 0,
            routes: [{ name: 'Login' }],
          });
        }
    }
  }, [isLoading, session, navigation]);

  useEffect(() => {
    if (error) {
        navigation.reset({
          index: 0,
          routes: [{ name: 'Login' }],
        });
      }
  }, [error, navigation]);

  return (
    <View style={styles.container}>
      <ActivityIndicator size="large" />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

export default SplashScreen;