import React, { useState, useRef, useMemo, useCallback } from 'react';
import { StyleSheet, View, SafeAreaView, StatusBar, Dimensions } from 'react-native';
import MapView, { Marker, Polyline, PROVIDER_GOOGLE } from 'react-native-maps';
import { StatusCard } from '../components/StatusCard';
import { ActionPanel } from '../components/ActionPanel';
import { useRouteSync } from '../hooks/useRouteSync';
import { optimizeRoute } from '../services/api';
import { COLOMBO_CENTER } from '../constants/config';
import { darkMapStyle } from '../constants/mapStyle';
import { COLORS } from '../theme/colors';

const { width, height } = Dimensions.get('window');

export const MapScreen = () => {
  const [optimizationState, setOptimizationState] = useState('idle');
  const [statusMessage, setStatusMessage] = useState('Select start and end for optimization');
  const [stats, setStats] = useState({ fuel: '', time: '' });
  const [totalSteps, setTotalSteps] = useState(0);

  const mapRef = useRef(null);
  const { connectionStatus, routePoints, requestSync, error, setRoutePoints } = useRouteSync();

  // Phase 4: Memoization for performance
  const memoizedMarkers = useMemo(() => {
    return routePoints.map((point, index) => (
      <Marker
        key={`step-${index}`}
        coordinate={point}
        pinColor={index === 0 ? COLORS.success : COLORS.accent}
        title={index === 0 ? 'Origin' : `Waypoint ${index}`}
      />
    ));
  }, [routePoints]);

  const memoizedPolyline = useMemo(() => {
    if (routePoints.length < 2) return null;
    return (
      <Polyline
        coordinates={routePoints}
        strokeColor={COLORS.primary}
        strokeWidth={4}
        lineDashPattern={[5, 5]}
      />
    );
  }, [routePoints]);

  const handleStartOptimization = async () => {
    setOptimizationState('analyzing');
    setStatusMessage('Analyzing Colombo traffic patterns...');
    setRoutePoints([]); // Clear UI via hook
    setStats({ fuel: '', time: '' });

    try {
      const data = await optimizeRoute('Colombo Fort', 'Kollupitiya');
      
      if (data.status === 'success') {
        setOptimizationState('streaming');
        setStats({ fuel: data.fuel_saved, time: data.estimated_time });
        setTotalSteps(data.optimized_route.length);
        setStatusMessage('Route identified. Syncing coordinates...');
        
        // Phase 3: Trigger socket sync
        requestSync('colombo_opt_001');
      }
    } catch (err) {
      setOptimizationState('error');
      setStatusMessage('Network timeout. Check backend connection.');
    }
  };

  const handleReset = () => {
    setOptimizationState('idle');
    setStatusMessage('Select start and end for optimization');
    setRoutePoints([]);
    setStats({ fuel: '', time: '' });
    mapRef.current?.animateToRegion(COLOMBO_CENTER, 1000);
  };

  // Auto-follow logic
  useMemo(() => {
    if (optimizationState === 'streaming' && routePoints.length > 0) {
      const lastPoint = routePoints[routePoints.length - 1];
      mapRef.current?.animateToRegion({
        ...lastPoint,
        latitudeDelta: 0.02,
        longitudeDelta: 0.02,
      }, 500);
    }
  }, [routePoints.length, optimizationState]);

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      
      <MapView
        ref={mapRef}
        style={styles.map}
        provider={PROVIDER_GOOGLE}
        initialRegion={COLOMBO_CENTER}
        customMapStyle={darkMapStyle}
        showsUserLocation={true}
      >
        {memoizedPolyline}
        {memoizedMarkers}
      </MapView>

      <SafeAreaView style={styles.overlay}>
        <View style={styles.topSection}>
          <StatusCard 
            state={optimizationState}
            message={error || statusMessage}
            fuelSaved={stats.fuel}
            estimatedTime={stats.time}
          />
        </View>

        <View style={styles.bottomSection}>
          <ActionPanel 
            state={optimizationState}
            onAction={optimizationState === 'completed' ? handleReset : handleStartOptimization}
            progress={totalSteps > 0 ? routePoints.length / totalSteps : 0}
          />
        </View>
      </SafeAreaView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.surface,
  },
  map: {
    width: width,
    height: height,
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'space-between',
    padding: 16,
  },
  topSection: {
    marginTop: 10,
  },
  bottomSection: {
    marginBottom: 20,
  },
});
