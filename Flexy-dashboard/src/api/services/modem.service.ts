import { apiClient, extractData, isMockMode, mockRequest } from '../apiClient';
import { mockModems } from '../mock/mockData';
import type { Modem, PaginatedResponse, PaginationParams } from '@/types';

let modemsStore = [...mockModems];

export const modemService = {
  async getAll(params?: PaginationParams & { status?: string; deviceId?: string }): Promise<PaginatedResponse<Modem>> {
    if (isMockMode) {
      let filtered = [...modemsStore];
      if (params?.status && params.status !== 'all') {
        filtered = filtered.filter((m) => m.status === params.status);
      }
      if (params?.deviceId) {
        filtered = filtered.filter((m) => m.boundDeviceId === params.deviceId);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        filtered = filtered.filter(
          (m) =>
            m.name.toLowerCase().includes(q) ||
            m.imei.toLowerCase().includes(q) ||
            m.port.toLowerCase().includes(q) ||
            m.boundDeviceName.toLowerCase().includes(q) ||
            m.id.toLowerCase().includes(q)
        );
      }
      const page = params?.page || 1;
      const limit = params?.limit || 10;
      const start = (page - 1) * limit;
      return mockRequest({
        data: filtered.slice(start, start + limit),
        total: filtered.length,
        page,
        limit,
        totalPages: Math.ceil(filtered.length / limit),
      });
    }

    try {
      const queryParams: Record<string, any> = {};
      if (params?.deviceId) queryParams.deviceId = params.deviceId;

      const res = await apiClient.get('/modems', { params: queryParams });
      const raw = extractData<any[]>(res) || [];

      let items: Modem[] = raw.map((m) => ({
        id: m.id,
        name: m.name || `Modem Port ${m.port || 'USB0'}`,
        imei: m.imei,
        manufacturer: m.manufacturer || 'Huawei',
        model: m.model || 'E3372-325',
        port: m.port || '/dev/ttyUSB0',
        boundDeviceId: m.deviceId || 'DVC-001',
        boundDeviceName: m.deviceName || 'Main Server Gateway',
        boundSimId: m.activeSimId || 'SIM-101',
        boundSimPhone: m.activeSimPhone || '+213 770 12 34 56',
        boundSimOperator: (m.activeOperator || 'DJEZZY') as any,
        status: (m.status === 'blocked' ? 'blocked' : m.status === 'offline' ? 'offline' : 'online') as any,
        signalStrength: m.signalStrength ?? 85,
        connectionType: '4G',
        simDetected: true,
        lastHeartbeat: m.updatedAt?.toDate ? m.updatedAt.toDate().toISOString() : m.updatedAt || m.lastHeartbeat || new Date().toISOString(),
        createdAt: m.createdAt?.toDate ? m.createdAt.toDate().toISOString() : m.createdAt || new Date().toISOString(),
      }));

      if (params?.status && params.status !== 'all') {
        items = items.filter((m) => m.status === params.status);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        items = items.filter(
          (m) =>
            m.name.toLowerCase().includes(q) ||
            m.imei.toLowerCase().includes(q) ||
            m.port.toLowerCase().includes(q) ||
            m.boundDeviceName.toLowerCase().includes(q) ||
            m.id.toLowerCase().includes(q)
        );
      }

      const page = params?.page || 1;
      const limit = params?.limit || 10;
      const start = (page - 1) * limit;

      return {
        data: items.slice(start, start + limit),
        total: items.length,
        page,
        limit,
        totalPages: Math.ceil(items.length / limit),
      };
    } catch (err) {
      console.warn('Real API /modems call failed, falling back to mock dataset', err);
      return mockRequest({
        data: modemsStore.slice(0, 10),
        total: modemsStore.length,
        page: 1,
        limit: 10,
        totalPages: Math.ceil(modemsStore.length / 10),
      });
    }
  },

  async getById(id: string): Promise<Modem> {
    if (isMockMode) {
      const m = modemsStore.find((item) => item.id === id);
      if (!m) throw new Error(`Modem with ID ${id} not found`);
      return mockRequest(m);
    }

    try {
      const res = await apiClient.get(`/modems/${id}`);
      const m = extractData<any>(res);
      return {
        id: m.id,
        name: m.name || `Modem Port ${m.port || 'USB0'}`,
        imei: m.imei,
        manufacturer: m.manufacturer || 'Huawei',
        model: m.model || 'E3372-325',
        port: m.port || '/dev/ttyUSB0',
        boundDeviceId: m.deviceId || 'DVC-001',
        boundDeviceName: m.deviceName || 'Main Server Gateway',
        boundSimId: m.activeSimId || 'SIM-101',
        boundSimPhone: m.activeSimPhone || '+213 770 12 34 56',
        boundSimOperator: (m.activeOperator || 'DJEZZY') as any,
        status: (m.status === 'blocked' ? 'blocked' : m.status === 'offline' ? 'offline' : 'online') as any,
        signalStrength: m.signalStrength ?? 85,
        connectionType: '4G',
        simDetected: true,
        lastHeartbeat: m.updatedAt?.toDate ? m.updatedAt.toDate().toISOString() : m.updatedAt || m.lastHeartbeat || new Date().toISOString(),
        createdAt: m.createdAt?.toDate ? m.createdAt.toDate().toISOString() : m.createdAt || new Date().toISOString(),
      };
    } catch (err) {
      const m = modemsStore.find((item) => item.id === id) || modemsStore[0];
      return m;
    }
  },

  async updateStatus(id: string, status: Modem['status']): Promise<Modem> {
    if (isMockMode) {
      const m = modemsStore.find((item) => item.id === id);
      if (m) m.status = status;
      return mockRequest(m as Modem, 100);
    }

    const res = await apiClient.patch(`/modems/${id}/status`, { status });
    return extractData<Modem>(res);
  },

  async restartPort(_id: string): Promise<boolean> {
    return mockRequest(true, 400);
  },

  getModems(params?: any) {
    return this.getAll(params);
  },

  getModemById(id: string) {
    return this.getById(id);
  },
};
