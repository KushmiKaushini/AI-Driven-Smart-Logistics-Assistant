import { useState, useEffect, useRef, useCallback } from 'react';
import { createSocket } from '../services/api';

export const useRouteSync = () => {
  const [connectionStatus, setConnectionStatus] = useState('disconnected');
  const [routePoints, setRoutePoints] = useState([]);
  const [error, setError] = useState(null);
  const socketRef = useRef(null);

  useEffect(() => {
    const socket = createSocket();

    socket.on('connect', () => {
      setConnectionStatus('connected');
      setError(null);
    });

    socket.on('disconnect', () => {
      setConnectionStatus('disconnected');
      // Potential "Offline" detection - logic could cache last state
    });

    socket.on('connect_error', (err) => {
      setConnectionStatus('error');
      setError('Connection failed. Retrying...');
    });

    socket.on('route_update', (data) => {
      const point = { latitude: parseFloat(data.lat), longitude: parseFloat(data.lng) };
      setRoutePoints((prev) => [...prev, point]);
    });

    socketRef.current = socket;

    return () => {
      if (socketRef.current) socketRef.current.disconnect();
    };
  }, []);

  const requestSync = useCallback((routeId) => {
    if (socketRef.current?.connected) {
      setRoutePoints([]); // Clear previous
      socketRef.current.emit('request_route_sync', { route_id: routeId });
    }
  }, []);

  return { connectionStatus, routePoints, requestSync, error, setRoutePoints };
};
