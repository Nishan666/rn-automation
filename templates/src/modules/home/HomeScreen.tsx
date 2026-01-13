import React from 'react';
import { View, Text, Button, StyleSheet } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import Config from 'react-native-config';
import { useLoginStore } from '../login/loginStore';

export const HomeScreen: React.FC = () => {
  const navigation = useNavigation();
  const { user, logout } = useLoginStore();
  const envName = Config.ENV_NAME || 'Production';

  const handleLogout = () => {
    logout();
    navigation.reset({
      index: 0,
      routes: [{ name: 'Login' }],
    });
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Home</Text>
      <Text style={styles.envBadge}>{envName}</Text>
      <Text style={styles.subtitle}>You are signed in.</Text>
      {user && <Text style={styles.email}>Email: {user.email}</Text>}
      <Button title="Sign Out" onPress={handleLogout} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 12,
  },
  envBadge: {
    fontSize: 12,
    fontWeight: '600',
    color: '#666',
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  subtitle: {
    fontSize: 16,
    marginBottom: 8,
  },
  email: {
    fontSize: 14,
    marginBottom: 16,
    color: '#666',
  },
});

export default HomeScreen;