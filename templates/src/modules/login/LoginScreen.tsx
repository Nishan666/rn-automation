import React, { useState } from 'react';
import { View, TextInput, Button, StyleSheet, Text } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import Config from 'react-native-config';
import { useLoginStore } from './loginStore';

export const LoginScreen: React.FC = () => {
  const navigation = useNavigation();
  const { login, isLoading, error, clearError } = useLoginStore();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const envName = Config.ENV_NAME || 'Production';

  const onSubmit = async () => {
    try {
      await login(email, password);
      navigation.reset({
        index: 0,
        routes: [{ name: 'Home' }],
      });
    } catch (err) {
      // Error is handled by store
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Welcome Back</Text>
      <Text style={styles.envBadge}>{envName}</Text>
      <TextInput
        style={styles.input}
        placeholder="Email"
        value={email}
        autoCapitalize="none"
        keyboardType="email-address"
        onChangeText={(text) => {
          setEmail(text);
          if (error) clearError();
        }}
      />
      <TextInput
        style={styles.input}
        placeholder="Password"
        secureTextEntry
        value={password}
        onChangeText={(text) => {
          setPassword(text);
          if (error) clearError();
        }}
      />
      {error ? <Text style={styles.error}>{error}</Text> : null}
      <Button title={isLoading ? 'Signing in...' : 'Sign In'} onPress={onSubmit} disabled={isLoading} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 24,
  },
  title: {
    fontSize: 24,
    fontWeight: '600',
    marginBottom: 8,
    textAlign: 'center',
  },
  envBadge: {
    fontSize: 14,
    fontWeight: '500',
    color: '#666',
    textAlign: 'center',
    marginBottom: 24,
    textTransform: 'uppercase',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 12,
    marginBottom: 12,
  },
  error: {
    color: 'red',
    marginBottom: 8,
    textAlign: 'center',
  },
});

export default LoginScreen;