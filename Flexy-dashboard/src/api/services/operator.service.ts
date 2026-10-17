import { apiClient, extractData, isMockMode, mockRequest } from '../apiClient';
import { mockOperators } from '../mock/mockData';
import type { Operator } from '@/types';

let operatorsStore = [...mockOperators];

export const operatorService = {
  async getAll(): Promise<Operator[]> {
    if (isMockMode) {
      return mockRequest(operatorsStore);
    }

    try {
      const res = await apiClient.get('/operators');
      const raw = extractData<any[]>(res) || [];
      if (raw.length === 0) return operatorsStore;

      return raw.map((op) => {
        const mockFallback = operatorsStore.find((m) => m.code === op.code || m.id.toLowerCase() === op.id.toLowerCase());
        return {
          id: op.id,
          name: op.name,
          code: (op.code || 'DJEZZY') as any,
          logo: mockFallback?.logo || '',
          status: (op.status === 'active' ? 'active' : 'suspended') as any,
          simsCount: mockFallback?.simsCount || 10,
          activeSimsCount: mockFallback?.activeSimsCount || 8,
          operationsCount: mockFallback?.operationsCount || 1000,
          successRate: mockFallback?.successRate || 99.1,
          balance: mockFallback?.balance || 50000,
          currency: 'DZD',
          color: mockFallback?.color || '#0066CC',
          createdAt: op.createdAt?.toDate ? op.createdAt.toDate().toISOString() : op.createdAt || new Date().toISOString(),
        };
      });
    } catch (err) {
      console.warn('Real API /operators call failed, falling back to mock dataset', err);
      return mockRequest(operatorsStore);
    }
  },

  async getById(id: string): Promise<Operator> {
    if (isMockMode) {
      const op = operatorsStore.find((item) => item.id === id);
      if (!op) throw new Error(`Operator with ID ${id} not found`);
      return mockRequest(op);
    }

    try {
      const res = await apiClient.get(`/operators/${id}`);
      const raw = extractData<any>(res);
      const mockFallback = operatorsStore.find((m) => m.code === raw.code || m.id === raw.id);
      return {
        id: raw.id,
        name: raw.name,
        code: (raw.code || 'DJEZZY') as any,
        logo: mockFallback?.logo || '',
        status: (raw.status === 'active' ? 'active' : 'suspended') as any,
        simsCount: mockFallback?.simsCount || 10,
        activeSimsCount: mockFallback?.activeSimsCount || 8,
        operationsCount: mockFallback?.operationsCount || 1000,
        successRate: mockFallback?.successRate || 99.1,
        balance: mockFallback?.balance || 50000,
        currency: 'DZD',
        color: mockFallback?.color || '#0066CC',
        createdAt: raw.createdAt?.toDate ? raw.createdAt.toDate().toISOString() : raw.createdAt || new Date().toISOString(),
      };
    } catch (err) {
      const op = operatorsStore.find((item) => item.id === id) || operatorsStore[0];
      return op;
    }
  },

  getOperators() {
    return this.getAll();
  },

  getOperatorById(id: string) {
    return this.getById(id);
  },

  async toggleStatus(id: string): Promise<Operator> {
    const op = await this.getById(id);
    const updatedStatus = op.status === 'active' ? 'suspended' : 'active';
    const idx = operatorsStore.findIndex((o) => o.id === id);
    if (idx !== -1) {
      operatorsStore[idx].status = updatedStatus;
      return mockRequest(operatorsStore[idx]);
    }
    return op;
  },
};
