import { mockRequest } from '../apiClient';
import { mockSystemServices, mockDevices } from '../mock/mockData';
import type { SystemServiceHealth, Heartbeat } from '@/types';

export const monitoringService = {
  async getSystemServices(): Promise<SystemServiceHealth[]> {
    return mockRequest(mockSystemServices, 120);
  },

  async getLiveHeartbeats(): Promise<Heartbeat[]> {
    const heartbeats: Heartbeat[] = mockDevices.map((d, index) => ({
      id: `HB-${d.id}`,
      deviceId: d.id,
      deviceName: d.name,
      modemId: `MDM-${101 + index}`,
      status: d.status === 'online' ? 'online' : 'offline',
      cpuUsage: d.status === 'online' ? Math.floor(15 + Math.random() * 25) : 0,
      memoryUsage: d.status === 'online' ? Math.floor(40 + Math.random() * 20) : 0,
      diskUsage: 35,
      temperature: d.status === 'online' ? Math.floor(42 + Math.random() * 8) : 25,
      signalStrength: d.status === 'online' ? Math.floor(75 + Math.random() * 25) : 0,
      latencyMs: d.status === 'online' ? Math.floor(20 + Math.random() * 15) : 0,
      timestamp: new Date().toISOString(),
    }));

    return mockRequest(heartbeats, 150);
  }
};
