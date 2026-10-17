import { apiClient, extractData, isMockMode, mockRequest } from '../apiClient';
import { mockSimCards } from '../mock/mockData';
import type { SimCard, PaginatedResponse, PaginationParams } from '@/types';

let simsStore = [...mockSimCards];

export const simService = {
  async getAll(
    params?: PaginationParams & { operator?: string; status?: string; customerId?: string }
  ): Promise<PaginatedResponse<SimCard>> {
    if (isMockMode) {
      let filtered = [...simsStore];
      if (params?.operator && params.operator !== 'all') {
        filtered = filtered.filter((s) => s.operator === params.operator);
      }
      if (params?.status && params.status !== 'all') {
        filtered = filtered.filter((s) => s.status === params.status);
      }
      if (params?.customerId) {
        filtered = filtered.filter((s) => s.customerId === params.customerId);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        filtered = filtered.filter(
          (s) =>
            s.phoneNumber.toLowerCase().includes(q) ||
            s.iccid.toLowerCase().includes(q) ||
            s.customerName.toLowerCase().includes(q) ||
            s.id.toLowerCase().includes(q)
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

      const res = await apiClient.get('/admin/sims', { params: queryParams });
      const raw = extractData<any[]>(res) || [];

      let items: SimCard[] = raw.map((s) => ({
        id: s.id,
        phoneNumber: s.phoneNumber || 'N/A',
        iccid: s.iccid || (s.iccidLast4 ? `•••• •••• •••• ${s.iccidLast4}` : 'N/A'),
        iccidHash: s.iccidHash || '',
        operator: (s.operatorId ? s.operatorId.toUpperCase() : 'MOBILIS') as any,
        status: s.status || 'pending',
        customerId: s.customerId || '',
        customerName: s.customerName || s.customerId || 'N/A',
        boundModemId: s.modemId || undefined,
        boundModemImei: s.modemImei || undefined,
        boundDeviceId: s.deviceId || undefined,
        boundDeviceName: s.deviceName || undefined,
        licenseId: s.licenseId || undefined,
        currentBalance: s.balanceDzd ?? 0,
        activatedAt: s.activatedAt?.toDate ? s.activatedAt.toDate().toISOString() : s.activatedAt || undefined,
        expiresAt: s.expiresAt?.toDate ? s.expiresAt.toDate().toISOString() : s.expiresAt || undefined,
        lastUsedAt: s.updatedAt?.toDate ? s.updatedAt.toDate().toISOString() : s.updatedAt || undefined,
        createdAt: s.createdAt?.toDate ? s.createdAt.toDate().toISOString() : s.createdAt || new Date().toISOString(),
      }));

      if (params?.operator && params.operator !== 'all') {
        items = items.filter((s) => s.operator === params.operator);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        items = items.filter(
          (s) =>
            s.phoneNumber.toLowerCase().includes(q) ||
            s.iccid.toLowerCase().includes(q) ||
            s.customerName.toLowerCase().includes(q) ||
            s.id.toLowerCase().includes(q)
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
      console.warn('Real API /admin/sims call failed', err);
      return {
        data: [],
        total: 0,
        page: 1,
        limit: 10,
        totalPages: 0,
      };
    }
  },

  async getById(id: string): Promise<SimCard> {
    if (isMockMode) {
      const s = simsStore.find((item) => item.id === id);
      if (!s) throw new Error(`SIM card with ID ${id} not found`);
      return mockRequest(s);
    }

    try {
      const res = await apiClient.get(`/admin/sims/${id}`);
      const s = extractData<any>(res);
      return {
        id: s.id,
        phoneNumber: s.phoneNumber || 'N/A',
        iccid: s.iccid || (s.iccidLast4 ? `•••• •••• •••• ${s.iccidLast4}` : 'N/A'),
        iccidHash: s.iccidHash || '',
        operator: (s.operatorId ? s.operatorId.toUpperCase() : 'MOBILIS') as any,
        status: s.status || 'pending',
        customerId: s.customerId || '',
        customerName: s.customerName || s.customerId || 'N/A',
        boundModemId: s.modemId || undefined,
        boundModemImei: s.modemImei || undefined,
        boundDeviceId: s.deviceId || undefined,
        boundDeviceName: s.deviceName || undefined,
        licenseId: s.licenseId || undefined,
        currentBalance: s.balanceDzd ?? 0,
        activatedAt: s.activatedAt?.toDate ? s.activatedAt.toDate().toISOString() : s.activatedAt || undefined,
        expiresAt: s.expiresAt?.toDate ? s.expiresAt.toDate().toISOString() : s.expiresAt || undefined,
        lastUsedAt: s.updatedAt?.toDate ? s.updatedAt.toDate().toISOString() : s.updatedAt || undefined,
        createdAt: s.createdAt?.toDate ? s.createdAt.toDate().toISOString() : s.createdAt || new Date().toISOString(),
      };
    } catch (err) {
      throw err;
    }
  },

  async create(data: {
    customerId: string;
    operatorId: string;
    iccid: string;
    phoneNumber?: string;
    requiredForAccess?: boolean;
  }): Promise<SimCard> {
    if (isMockMode) {
      const newSim: SimCard = {
        id: `SIM-${100 + simsStore.length + 1}`,
        phoneNumber: data.phoneNumber || '+213 770 00 00 00',
        iccid: data.iccid,
        iccidHash: 'sha256_mock_hash',
        operator: data.operatorId.toUpperCase() as any,
        status: 'pending',
        customerId: data.customerId,
        customerName: 'Customer Profile',
        boundModemId: 'MDM-101',
        boundModemImei: '864201041234567',
        boundDeviceId: 'DVC-001',
        boundDeviceName: 'Main Gateway',
        currentBalance: 0,
        activatedAt: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 365 * 24 * 3600 * 1000).toISOString(),
        lastUsedAt: new Date().toISOString(),
        createdAt: new Date().toISOString(),
      };
      simsStore.unshift(newSim);
      return mockRequest(newSim);
    }

    const res = await apiClient.post('/admin/sims', {
      customerId: data.customerId,
      operatorId: data.operatorId.toLowerCase(),
      iccid: data.iccid,
      phoneNumber: data.phoneNumber,
      requiredForAccess: data.requiredForAccess ?? true,
    });
    return extractData<SimCard>(res);
  },

  async update(id: string, data: Partial<SimCard>): Promise<SimCard> {
    if (isMockMode) {
      const idx = simsStore.findIndex((s) => s.id === id);
      if (idx !== -1) {
        simsStore[idx] = { ...simsStore[idx], ...data, lastUsedAt: new Date().toISOString() };
        return mockRequest(simsStore[idx]);
      }
      throw new Error('SIM not found');
    }

    const payload: Record<string, any> = {};
    if (data.phoneNumber !== undefined) payload.phoneNumber = data.phoneNumber;
    if (data.operator !== undefined) payload.operatorId = data.operator.toLowerCase();
    if (data.status !== undefined) payload.status = data.status;
    if (data.iccid !== undefined && data.iccid.length >= 10) payload.iccid = data.iccid;

    const res = await apiClient.put(`/admin/sims/${id}`, payload);
    return extractData<SimCard>(res);
  },

  async bindModem(simId: string, modemId: string, slot: number = 1): Promise<boolean> {
    if (isMockMode) {
      const sim = simsStore.find((s) => s.id === simId);
      if (sim) {
        sim.boundModemId = modemId;
      }
      return mockRequest(true);
    }

    await apiClient.post(`/admin/sims/${simId}/bind-modem`, { modemId, slot });
    return true;
  },

  async updateStatus(id: string, status: SimCard['status'], reason?: string): Promise<SimCard> {
    if (isMockMode) {
      const idx = simsStore.findIndex((s) => s.id === id);
      if (idx !== -1) {
        simsStore[idx].status = status;
        simsStore[idx].lastUsedAt = new Date().toISOString();
        return mockRequest(simsStore[idx]);
      }
      throw new Error('SIM not found');
    }

    const res = await apiClient.patch(`/admin/sims/${id}/status`, { status, reason });
    return extractData<SimCard>(res);
  },

  getSimCards(params?: any) {
    return this.getAll(params);
  },

  getSimById(id: string) {
    return this.getById(id);
  },

  blockSim(id: string, reason?: string) {
    return this.updateStatus(id, 'blocked', reason);
  },

  activateSim(id: string) {
    return this.updateStatus(id, 'active');
  },

  async transferOwnership(id: string, newCustomerId: string): Promise<SimCard> {
    if (isMockMode) {
      const idx = simsStore.findIndex((s) => s.id === id);
      if (idx !== -1) {
        simsStore[idx].customerId = newCustomerId;
        simsStore[idx].status = 'pending';
        return mockRequest(simsStore[idx]);
      }
      throw new Error('SIM not found');
    }

    const res = await apiClient.post(`/admin/sims/${id}/transfer-owner`, { newCustomerId });
    return extractData<SimCard>(res);
  },

  async deleteSim(id: string): Promise<boolean> {
    if (isMockMode) {
      simsStore = simsStore.filter((s) => s.id !== id);
      return mockRequest(true);
    }

    await apiClient.delete(`/admin/sims/${id}`);
    return true;
  },
};
