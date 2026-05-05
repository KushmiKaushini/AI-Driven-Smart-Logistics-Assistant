import React from 'react';
import { StyleSheet, View, Text } from 'react-native';
import { BlurView } from 'expo-blur';
import { Navigation, Radar, CheckCircle2, AlertTriangle, Fuel, Timer } from 'lucide-react-native';
import { COLORS } from '../theme/colors';

export const StatusCard = ({ state, message, fuelSaved, estimatedTime }) => {
  return (
    <BlurView intensity={85} tint="dark" style={styles.card}>
      <View style={styles.header}>
        <View style={styles.iconContainer}>
          <Navigation size={20} color={COLORS.primary} />
        </View>
        <Text style={styles.title}>Smart Logistics Assistant</Text>
      </View>

      <View style={styles.statusRow}>
        <StatusIcon state={state} />
        <Text style={styles.statusText} numberOfLines={2}>{message}</Text>
      </View>

      {(fuelSaved || estimatedTime) && (
        <View style={styles.statsRow}>
          {fuelSaved && <StatChip icon={<Fuel size={14} color={COLORS.success} />} text={`Fuel: +${fuelSaved}`} color={COLORS.success} />}
          {estimatedTime && <StatChip icon={<Timer size={14} color={COLORS.accent} />} text={estimatedTime} color={COLORS.accent} />}
        </View>
      )}
    </BlurView>
  );
};

const StatusIcon = ({ state }) => {
  const color = state === 'completed' ? COLORS.success : 
                state === 'error' ? COLORS.error : 
                state === 'analyzing' ? COLORS.warning : 
                state === 'streaming' ? COLORS.accent : COLORS.textSecondary;
  
  if (state === 'analyzing' || state === 'streaming') return <Radar size={16} color={color} />;
  return <CheckCircle2 size={16} color={color} />;
};

const StatChip = ({ icon, text, color }) => (
  <View style={[styles.chip, { borderColor: `${color}4D`, backgroundColor: `${color}1F` }]}>
    {icon}
    <Text style={[styles.chipText, { color }]}>{text}</Text>
  </View>
);

const styles = StyleSheet.create({
  card: {
    padding: 20,
    borderRadius: 24,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: COLORS.glassBorder,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  iconContainer: {
    padding: 8,
    backgroundColor: `${COLORS.primary}33`,
    borderRadius: 12,
    marginRight: 12,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statusText: {
    color: COLORS.textSecondary,
    fontSize: 14,
    marginLeft: 10,
    flex: 1,
  },
  statsRow: {
    flexDirection: 'row',
    marginTop: 16,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    borderWidth: 1,
    marginRight: 10,
  },
  chipText: {
    fontSize: 12,
    fontWeight: '600',
    marginLeft: 6,
  },
});
