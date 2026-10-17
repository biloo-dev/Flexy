import { apiClient, extractData, isMockMode, mockRequest } from '../apiClient';
import { mockDevices } from '../mock/mockData';
import type { Device, PaginatedResponse, PaginationParams } from '@/types';

let devicesStore = [...mockDevices];

function parseTimestamp(val: any): string {
  if (!val) return new Date().toISOString();
  if (typeof val === 'string') return val;
  if (val.toDate && typeof val.toDate === 'function') return val.toDate().toISOString();
  if (val._seconds) return new Date(val._seconds * 1000).toISOString();
  if (val.seconds) return new Date(val.seconds * 1000).toISOString();
  return new Date().toISOString();
}

export const deviceService = {
  async getAll(params?: PaginationParams & { status?: string; customerId?: string }): Promise<PaginatedResponse<Device>> {
    if (isMockMode) {
      let filtered = [...devicesStore];
      if (params?.status && params.status !== 'all') {
        filtered = filtered.filter((d) => d.status === params.status);
      }
      if (params?.customerId) {
        filtered = filtered.filter((d) => d.customerId === params.customerId);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        filtered = filtered.filter(
          (d) =>
            d.name.toLowerCase().includes(q) ||
            d.uuid.toLowerCase().includes(q) ||
            d.customerName.toLowerCase().includes(q) ||
            d.id.toLowerCase().includes(q)
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
      if (params?.status && params.status !== 'all') queryParams.status = params.status;

      const res = await apiClient.get('/admin/devices', { params: queryParams });
      const raw = extractData<any[]>(res) || [];

      let items: Device[] = raw.map((d) => ({
        id: d.id,
        uuid: d.deviceUuid || d.uuid || 'dvc-uuid-001',
        fingerprint: d.deviceFingerprint || d.fingerprint || 'fp_sha256_mock',
        name: d.name || 'Flexi Gateway PC',
        customerId: d.customerId || 'CUST-1001',
        customerName: d.customerName || `Customer (${d.customerId})`,
        appVersion: d.daemonVersion || d.appVersion || 'v2.4.0',
        ipAddress: d.ipAddress || '192.168.1.100',
        os: d.os || 'Windows 11 Pro',
        status: (d.status === 'blocked' ? 'blocked' : d.status === 'offline' ? 'offline' : 'online') as any,
        modemsCount: d.boundModemsCount ?? 0,
        simsCount: d.boundSimsCount ?? 0,
        activeLicensesCount: d.activeLicensesCount ?? 0,
        lastSeen: parseTimestamp(d.lastSeenAt || d.lastSeen),
        createdAt: parseTimestamp(d.createdAt),
      }));

      if (params?.customerId) {
        items = items.filter((d) => d.customerId === params.customerId);
      }

      if (params?.search) {
        const q = params.search.toLowerCase();
        items = items.filter(
          (d) =>
            d.name.toLowerCase().includes(q) ||
            d.uuid.toLowerCase().includes(q) ||
            d.customerName.toLowerCase().includes(q) ||
            d.id.toLowerCase().includes(q)
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
        totalPages: Math.ceil(items.length / limit) || 1,
      };
    } catch (err) {
      console.warn('Real API /admin/devices call failed, falling back to mock dataset', err);
      return mockRequest({
        data: devicesStore.slice(0, 10),
        total: devicesStore.length,
        page: 1,
        limit: 10,
        totalPages: Math.ceil(devicesStore.length / 10),
      });
    }
  },

  async getById(id: string): Promise<Device> {
    if (isMockMode) {
      const d = devicesStore.find((item) => item.id === id);
      if (!d) throw new Error(`Device with ID ${id} not found`);
      return mockRequest(d);
    }

    try {
      const res = await apiClient.get(`/admin/devices/${id}`);
      const d = extractData<any>(res);
      return {
        id: d.id,
        uuid: d.deviceUuid || d.uuid || 'dvc-uuid-001',
        fingerprint: d.deviceFingerprint || d.fingerprint || 'fp_sha256_mock',
        name: d.name || 'Flexi Gateway PC',
        customerId: d.customerId || 'CUST-1001',
        customerName: d.customerName || `Customer (${d.customerId})`,
        appVersion: d.daemonVersion || d.appVersion || 'v2.4.0',
        ipAddress: d.ipAddress || '192.168.1.100',
        os: d.os || 'Windows 11 Pro',
        status: (d.status === 'blocked' ? 'blocked' : d.status === 'offline' ? 'offline' : 'online') as any,
        modemsCount: d.boundModemsCount ?? 0,
        simsCount: d.boundSimsCount ?? 0,
        activeLicensesCount: d.activeLicensesCount ?? 0,
        lastSeen: parseTimestamp(d.lastSeenAt || d.lastSeen),
        createdAt: parseTimestamp(d.createdAt),
      };
    } catch (err) {
      const d = devicesStore.find((item) => item.id === id) || devicesStore[0];
      return d;
    }
  },

  async register(data: {
    customerId: string;
    deviceUuid: string;
    deviceFingerprint: string;
    name?: string;
  }): Promise<Device> {
    if (isMockMode) {
      const newD: Device = {
        id: `DVC-${100 + devicesStore.length + 1}`,
        uuid: data.deviceUuid,
        fingerprint: data.deviceFingerprint,
        name: data.name || 'PC Caisse 1',
        customerId: data.customerId,
        customerName: 'Customer',
        appVersion: 'v2.4.0',
        ipAddress: '192.168.1.105',
        os: 'Windows 11 Pro',
        status: 'online',
        modemsCount: 0,
        simsCount: 0,
        activeLicensesCount: 0,
        lastSeen: new Date().toISOString(),
        createdAt: new Date().toISOString(),
      };
      devicesStore.unshift(newD);
      return mockRequest(newD);
    }

    const res = await apiClient.post('/devices/register', {
      customerId: data.customerId,
      deviceUuid: data.deviceUuid,
      deviceFingerprint: data.deviceFingerprint,
      name: data.name || 'Flexi PC',
    });
    const d = extractData<any>(res);
    return {
      id: d.id,
      uuid: d.deviceUuid || d.uuid,
      fingerprint: d.deviceFingerprint || d.fingerprint,
      name: d.name || 'Flexi PC',
      customerId: d.customerId,
      customerName: `Customer (${d.customerId})`,
      appVersion: 'v2.4.0',
      ipAddress: '127.0.0.1',
      os: 'Windows 11',
      status: 'online',
      modemsCount: 0,
      simsCount: 0,
      activeLicensesCount: 0,
      lastSeen: parseTimestamp(d.lastSeenAt),
      createdAt: parseTimestamp(d.createdAt),
    };
  },

  async updateStatus(id: string, status: Device['status'], reason?: string): Promise<Device> {
    if (isMockMode) {
      const d = devicesStore.find((item) => item.id === id);
      if (d) d.status = status;
      return mockRequest(d as Device, 150);
    }

    const res = await apiClient.patch(`/admin/devices/${id}/status`, { status, reason });
    return extractData<Device>(res);
  },

  getDevices(params?: any) {
    return this.getAll(params);
  },

  getDeviceById(id: string) {
    return this.getById(id);
  },

  registerDevice(data: { customerId: string; deviceUuid: string; deviceFingerprint: string; name?: string }) {
    return this.register(data);
  },
};
