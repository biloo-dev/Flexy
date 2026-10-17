import { apiClient, extractData, isMockMode, mockRequest } from '../apiClient';
import { mockLicenses } from '../mock/mockData';
import type { License, PaginatedResponse, PaginationParams } from '@/types';

let licensesStore = [...mockLicenses];

export const licenseService = {
  async getAll(
    params?: PaginationParams & { operator?: string; status?: string; customerId?: string }
  ): Promise<PaginatedResponse<License>> {
    if (isMockMode) {
      let filtered = [...licensesStore];
      if (params?.operator && params.operator !== 'all') {
        filtered = filtered.filter((l) => l.operator === params.operator);
      }
      if (params?.status && params.status !== 'all') {
        filtered = filtered.filter((l) => l.status === params.status);
      }
      if (params?.customerId) {
        filtered = filtered.filter((l) => l.customerId === params.customerId);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        filtered = filtered.filter(
          (l) =>
            l.id.toLowerCase().includes(q) ||
            l.serialNumber.toLowerCase().includes(q) ||
            l.customerName.toLowerCase().includes(q) ||
            l.simPhone.toLowerCase().includes(q)
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
      if (params?.customerId) queryParams.customerId = params.customerId;

      const res = await apiClient.get('/admin/licenses', { params: queryParams });
      const raw = extractData<any[]>(res) || [];

      let items: License[] = raw.map((l) => {
        const serial = l.serialNumber || l.licenseSerial || l.serial || '';
        return {
          id: l.id || l.licenseId,
          serialNumber: serial,
          maskedSerial: serial ? `${serial.slice(0, 10)}...${serial.slice(-6)}` : 'FX1.••••••',
          customerId: l.customerId || '',
          customerName: l.customerName || l.customerId || 'Customer',
          operator: (l.operator || 'MOBILIS') as any,
          simId: l.simCardId || '',
          simPhone: l.simPhone || l.phoneNumber || 'N/A',
          deviceId: l.deviceId || '*',
          deviceName: l.deviceName || (l.deviceId === '*' ? 'All Customer Devices (*)' : l.deviceId || 'Any Device'),
          keyId: l.keyId || '2026-01',
          keyVersion: l.keyId || '2026-01',
          algorithm: 'Ed25519',
          status: l.status || 'active',
          paymentStatus: 'paid',
          paymentId: l.paymentId || 'PAY-DIRECT',
          price: l.price || 0,
          issuedAt: l.issuedAt?.toDate ? l.issuedAt.toDate().toISOString() : l.issuedAt || new Date().toISOString(),
          expiresAt: l.expiresAt?.toDate ? l.expiresAt.toDate().toISOString() : l.expiresAt || new Date().toISOString(),
          revokedAt: l.revokedAt?.toDate ? l.revokedAt.toDate().toISOString() : l.revokedAt || undefined,
          revocationReason: l.revocationReason || undefined,
          createdAt: l.createdAt?.toDate ? l.createdAt.toDate().toISOString() : l.createdAt || new Date().toISOString(),
        };
      });

      if (params?.operator && params.operator !== 'all') {
        items = items.filter((l) => l.operator === params.operator);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        items = items.filter(
          (l) =>
            l.id.toLowerCase().includes(q) ||
            l.serialNumber.toLowerCase().includes(q) ||
            l.customerName.toLowerCase().includes(q) ||
            l.simPhone.toLowerCase().includes(q)
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
      console.warn('Real API /admin/licenses call failed', err);
      return {
        data: [],
        total: 0,
        page: 1,
        limit: 10,
        totalPages: 0,
      };
    }
  },

  async getById(id: string): Promise<License> {
    if (isMockMode) {
      const l = licensesStore.find((item) => item.id === id);
      if (!l) throw new Error(`License with ID ${id} not found`);
      return mockRequest(l);
    }

    try {
      const res = await apiClient.get(`/admin/licenses/${id}`);
      const l = extractData<any>(res);
      const serial = l.serialNumber || l.licenseSerial || l.serial || '';
      return {
        id: l.id || l.licenseId,
        serialNumber: serial,
        maskedSerial: serial ? `${serial.slice(0, 10)}...${serial.slice(-6)}` : 'FX1.••••••',
        customerId: l.customerId || '',
        customerName: l.customerName || l.customerId || 'Customer',
        operator: (l.operator || 'MOBILIS') as any,
        simId: l.simCardId || '',
        simPhone: l.simPhone || l.phoneNumber || 'N/A',
        deviceId: l.deviceId || '*',
        deviceName: l.deviceName || (l.deviceId === '*' ? 'All Customer Devices (*)' : l.deviceId || 'Any Device'),
        keyId: l.keyId || '2026-01',
        keyVersion: l.keyId || '2026-01',
        algorithm: 'Ed25519',
        status: l.status || 'active',
        paymentStatus: 'paid',
        paymentId: l.paymentId || 'PAY-DIRECT',
        price: l.price || 0,
        issuedAt: l.issuedAt?.toDate ? l.issuedAt.toDate().toISOString() : l.issuedAt || new Date().toISOString(),
        expiresAt: l.expiresAt?.toDate ? l.expiresAt.toDate().toISOString() : l.expiresAt || new Date().toISOString(),
        revokedAt: l.revokedAt?.toDate ? l.revokedAt.toDate().toISOString() : l.revokedAt || undefined,
        revocationReason: l.revocationReason || undefined,
        createdAt: l.createdAt?.toDate ? l.createdAt.toDate().toISOString() : l.createdAt || new Date().toISOString(),
      };
    } catch (err) {
      throw err;
    }
  },

  async create(data: Partial<License>): Promise<License> {
    if (isMockMode) {
      const newLic: License = {
        id: `LIC-${300 + licensesStore.length + 1}`,
        serialNumber: `FX1.${Array.from({ length: 64 }, () => Math.floor(Math.random() * 16).toString(16)).join('')}`,
        maskedSerial: 'FX1.a8f9c2...e81a',
        customerId: data.customerId || 'CUST-1001',
        customerName: 'Customer Name',
        operator: data.operator || 'DJEZZY',
        simId: data.simId || 'SIM-101',
        simPhone: data.simPhone || '+213 770 12 34 56',
        deviceId: data.deviceId || 'DVC-001',
        deviceName: 'Gateway Node',
        keyId: '2026-01',
        keyVersion: 'v1.4',
        algorithm: 'Ed25519',
        status: 'active',
        paymentStatus: 'paid',
        price: data.price || 35000,
        issuedAt: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 365 * 24 * 3600 * 1000).toISOString(),
        createdAt: new Date().toISOString(),
      };
      licensesStore.unshift(newLic);
      return mockRequest(newLic);
    }

    const res = await apiClient.post('/admin/licenses', {
      customerId: data.customerId,
      simCardId: data.simId,
      deviceId: data.deviceId,
      validityDays: 365,
    });
    const raw = extractData<any>(res);
    return {
      id: raw.id || raw.licenseId,
      serialNumber: raw.licenseSerial || raw.serialNumber || '',
      maskedSerial: raw.licenseSerial ? `${raw.licenseSerial.slice(0, 8)}...${raw.licenseSerial.slice(-6)}` : 'FX1.••••••',
      customerId: raw.customerId || data.customerId || '',
      customerName: data.customerName || 'Customer',
      operator: data.operator || 'DJEZZY',
      simId: raw.simCardId || data.simId || '',
      simPhone: data.simPhone || '',
      deviceId: raw.deviceId || data.deviceId || '',
      deviceName: 'Device',
      keyId: raw.keyId || '2026-01',
      keyVersion: 'v1.0',
      algorithm: 'Ed25519',
      status: raw.status || 'active',
      paymentStatus: 'paid',
      price: data.price || 12000,
      issuedAt: new Date().toISOString(),
      expiresAt: raw.expiresAt ? (raw.expiresAt.toDate ? raw.expiresAt.toDate().toISOString() : raw.expiresAt) : new Date().toISOString(),
      createdAt: new Date().toISOString(),
    };
  },

  async revoke(id: string, reason: string): Promise<License> {
    if (isMockMode) {
      const idx = licensesStore.findIndex((l) => l.id === id);
      if (idx !== -1) {
        licensesStore[idx].status = 'revoked';
        licensesStore[idx].revokedAt = new Date().toISOString();
        licensesStore[idx].revocationReason = reason;
        return mockRequest(licensesStore[idx]);
      }
      throw new Error('License not found');
    }

    const res = await apiClient.post(`/admin/licenses/${id}/revoke`, { reason });
    return extractData<License>(res);
  },

  async suspend(id: string): Promise<License> {
    if (isMockMode) {
      const idx = licensesStore.findIndex((l) => l.id === id);
      if (idx !== -1) {
        licensesStore[idx].status = 'suspended';
        return mockRequest(licensesStore[idx]);
      }
      throw new Error('License not found');
    }

    const res = await apiClient.post(`/admin/licenses/${id}/suspend`);
    return extractData<License>(res);
  },

  async activate(id: string): Promise<License> {
    if (isMockMode) {
      const idx = licensesStore.findIndex((l) => l.id === id);
      if (idx !== -1) {
        licensesStore[idx].status = 'active';
        return mockRequest(licensesStore[idx]);
      }
      throw new Error('License not found');
    }

    const res = await apiClient.post(`/admin/licenses/${id}/reactivate`);
    return extractData<License>(res);
  },

  async renew(id: string, months: number = 12): Promise<License> {
    if (isMockMode) {
      const idx = licensesStore.findIndex((l) => l.id === id);
      if (idx !== -1) {
        const currentExp = new Date(licensesStore[idx].expiresAt).getTime();
        const base = currentExp > Date.now() ? currentExp : Date.now();
        licensesStore[idx].expiresAt = new Date(base + months * 30 * 24 * 3600 * 1000).toISOString();
        licensesStore[idx].status = 'active';
        return mockRequest(licensesStore[idx]);
      }
      throw new Error('License not found');
    }

    const res = await apiClient.post(`/admin/licenses/${id}/renew`, { additionalDays: months * 30 });
    return extractData<License>(res);
  },

  async regenerateSerial(id: string, validityDays: number = 365): Promise<License> {
    if (isMockMode) {
      const idx = licensesStore.findIndex((l) => l.id === id);
      if (idx !== -1) {
        licensesStore[idx].serialNumber = `FX1.${Array.from({ length: 64 }, () => Math.floor(Math.random() * 16).toString(16)).join('')}`;
        licensesStore[idx].status = 'active';
        return mockRequest(licensesStore[idx]);
      }
      throw new Error('License not found');
    }

    const res = await apiClient.post(`/admin/licenses/${id}/regenerate-serial`, { validityDays });
    const l = extractData<any>(res);
    const serial = l.licenseSerial || l.serialNumber || '';
    return {
      id: l.id || l.licenseId,
      serialNumber: serial,
      maskedSerial: serial ? `${serial.slice(0, 10)}...${serial.slice(-6)}` : 'FX1.••••••',
      customerId: l.customerId || '',
      customerName: l.customerName || l.customerId || 'Customer',
      operator: (l.operator || 'MOBILIS') as any,
      simId: l.simCardId || l.simId || '',
      simPhone: l.simPhone || 'N/A',
      deviceId: l.deviceId || '*',
      deviceName: l.deviceName || 'Any Device',
      keyId: l.keyId || '2026-01',
      keyVersion: l.keyId || '2026-01',
      algorithm: 'Ed25519',
      status: l.status || 'active',
      paymentStatus: 'paid',
      paymentId: 'PAY-DIRECT',
      price: l.price || 0,
      issuedAt: l.issuedAt,
      expiresAt: l.expiresAt,
      createdAt: l.createdAt,
    };
  },

  async delete(id: string): Promise<void> {
    if (isMockMode) {
      const idx = licensesStore.findIndex((l) => l.id === id);
      if (idx !== -1) {
        licensesStore.splice(idx, 1);
        return mockRequest(undefined);
      }
      throw new Error('License not found');
    }

    await apiClient.delete(`/admin/licenses/${id}`);
  },

  async getExpiring(): Promise<{
    expired: License[];
    today: License[];
    in3Days: License[];
    in7Days: License[];
    in30Days: License[];
  }> {
    const all = await this.getAll({ page: 1, limit: 100 });
    const now = Date.now();
    const dayMs = 24 * 3600 * 1000;

    const expired: License[] = [];
    const today: License[] = [];
    const in3Days: License[] = [];
    const in7Days: License[] = [];
    const in30Days: License[] = [];

    all.data.forEach((l) => {
      const diff = new Date(l.expiresAt).getTime() - now;
      if (l.status === 'expired' || diff < 0) {
        expired.push(l);
      } else if (diff <= dayMs) {
        today.push(l);
      } else if (diff <= 3 * dayMs) {
        in3Days.push(l);
      } else if (diff <= 7 * dayMs) {
        in7Days.push(l);
      } else if (diff <= 30 * dayMs) {
        in30Days.push(l);
      }
    });

    return { expired, today, in3Days, in7Days, in30Days };
  },

  getLicenses(params?: any) {
    return this.getAll(params);
  },

  getLicenseById(id: string) {
    return this.getById(id);
  },

  getExpiringLicenses() {
    return this.getExpiring();
  },

  revokeLicense(id: string, reason: string) {
    return this.revoke(id, reason);
  },

  activateLicense(id: string) {
    return this.activate(id);
  },

  suspendLicense(id: string) {
    return this.suspend(id);
  },

  renewLicense(id: string, months: number = 12) {
    return this.renew(id, months);
  },

  createLicense(data: Partial<License>) {
    return this.create(data);
  },

  deleteLicense(id: string) {
    return this.delete(id);
  },
};
