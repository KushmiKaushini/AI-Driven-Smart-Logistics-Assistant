import React from 'react';
import { StyleSheet, View, Text, TouchableOpacity, ActivityIndicator } from 'react-native';
import { Zap, RefreshCw } from 'lucide-react-native';
import { COLORS } from '../theme/colors';

export const ActionPanel = ({ state, onAction, progress }) => {
  const isWorking = state === 'analyzing' || state === 'streaming';
  
  return (
    <View style={styles.container}>
      {state === 'streaming' && progress > 0 && (
        <View style={styles.progressTrack}>
          <View style={[styles.progressBar, { width: `${progress * 100}%` }]} />
        </View>
      )}

      <TouchableOpacity 
        style={[
          styles.button,
          state === 'completed' && { backgroundColor: COLORS.success },
          state === 'error' && { backgroundColor: COLORS.error },
          isWorking && { backgroundColor: COLORS.surfaceLight }
        ]}
        onPress={isWorking ? null : onAction}
        activeOpacity={0.8}
      >
        {isWorking ? (
          <ActivityIndicator color="#FFF" size="small" />
        ) : (
          state === 'completed' ? <RefreshCw size={20} color="#000" /> : <Zap size={20} color="#FFF" />
        )}
        <Text style={[styles.buttonText, state === 'completed' && { color: '#000' }]}>
          {state === 'completed' ? 'NEW ROUTE' : 
           state === 'error' ? 'RETRY' : 
           isWorking ? 'PROCESSING...' : 'OPTIMIZE ROUTE'}
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  progressTrack: {
    height: 4,
    backgroundColor: 'rgba(26, 26, 46, 0.8)',
    borderRadius: 2,
    marginBottom: 12,
    overflow: 'hidden',
  },
  progressBar: {
    height: '100%',
    backgroundColor: COLORS.primary,
  },
  button: {
    height: 60,
    borderRadius: 18,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: COLORS.primary,
    shadowColor: COLORS.primary,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.3,
    shadowRadius: 12,
    elevation: 8,
  },
  buttonText: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 1.2,
    marginLeft: 10,
  },
});
