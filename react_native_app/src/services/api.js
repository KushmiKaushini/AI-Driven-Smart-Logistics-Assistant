import axios from 'axios';
import { io } from 'socket.io-client';
import { BACKEND_URL } from '../constants/config';

// HTTP Client for route optimization
export const apiClient = axios.create({
  baseURL: BACKEND_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const optimizeRoute = async (origin, destination) => {
  try {
    const response = await apiClient.post('/api/optimize', { origin, destination });
    return response.data;
  } catch (error) {
    console.error('[API] Optimization failed:', error);
    throw error;
  }
};

// WebSocket Service
export const createSocket = () => {
  return io(BACKEND_URL, {
    transports: ['websocket'],
    reconnectionAttempts: 5,
    reconnectionDelay: 2000,
  });
};
