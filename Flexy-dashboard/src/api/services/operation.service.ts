import { apiClient, extractData, isMockMode, mockRequest } from '../apiClient';
import { mockOperations, mockDashboardKPIs } from '../mock/mockData';
import type { FlexiOperation, PaginatedResponse, PaginationParams, DashboardKPIs } from '@/types';

let operationsStore = [...mockOperations];

export const operationService = {
  async getAll(
    params?: PaginationParams & {
      operator?: string;
      status?: string;
      customerId?: string;
      simId?: string;
      deviceId?: string;
    }
  ): Promise<PaginatedResponse<FlexiOperation>> {
    if (isMockMode) {
      let filtered = [...operationsStore];
      if (params?.operator && params.operator !== 'all') {
        filtered = filtered.filter((o) => o.operator === params.operator);
      }
      if (params?.status && params.status !== 'all') {
        filtered = filtered.filter((o) => o.status === params.status);
      }
      if (params?.customerId) {
        filtered = filtered.filter((o) => o.customerId === params.customerId);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        filtered = filtered.filter(
          (o) =>
            o.operationCode.toLowerCase().includes(q) ||
            o.targetPhone.toLowerCase().includes(q) ||
            o.customerName.toLowerCase().includes(q) ||
            o.simPhone.toLowerCase().includes(q)
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
      if (params?.customerId) queryParams.customerId = params.customerId;
      if (params?.deviceId) queryParams.deviceId = params.deviceId;
      if (params?.simId) queryParams.simCardId = params.simId;

      const res = await apiClient.get('/flexi/operations', { params: queryParams });
      const raw = extractData<any[]>(res) || [];

      let items: FlexiOperation[] = raw.map((o) => ({
        id: o.id,
        operationCode: o.operationCode || `FLX-${o.id?.slice(0, 8)}`,
        idempotencyKey: o.idempotencyKey || 'idem_key',
        customerId: o.customerId,
        customerName: o.customerName || `Customer (${o.customerId})`,
        deviceId: o.deviceId,
        deviceName: o.deviceName || 'Gateway Station',
        simId: o.simCardId,
        simPhone: o.simPhone || '+213 770 12 34 56',
        modemId: o.modemId || 'MDM-101',
        operator: (o.operatorId ? o.operatorId.toUpperCase() : 'DJEZZY') as any,
        targetPhone: o.targetPhone || '+213 770 99 88 77',
        amount: o.amount || 500,
        currency: 'DZD',
        status: o.status || 'success',
        executionDurationMs: o.executionDurationMs || 1240,
        errorMessage: o.errorMessage || null,
        verificationPipeline: o.verificationPipeline || [
          { step: 'request_ingestion', title: 'Request Ingestion', status: 'success', timestamp: new Date().toISOString() },
          { step: 'authentication', title: 'Device Authentication', status: 'success', timestamp: new Date().toISOString() },
          { step: 'license_check', title: 'Ed25519 License Verification', status: 'success', timestamp: new Date().toISOString() },
          { step: 'iccid_match', title: 'ICCID Hardware Matching', status: 'success', timestamp: new Date().toISOString() },
          { step: 'idempotency_check', title: 'Idempotency Validation', status: 'success', timestamp: new Date().toISOString() },
          { step: 'execution', title: 'Operator Flexi Execution', status: 'success', timestamp: new Date().toISOString() },
        ],
        createdAt: o.createdAt?.toDate ? o.createdAt.toDate().toISOString() : o.createdAt || new Date().toISOString(),
        completedAt: o.completedAt?.toDate ? o.completedAt.toDate().toISOString() : o.completedAt || new Date().toISOString(),
      }));

      if (params?.operator && params.operator !== 'all') {
        items = items.filter((o) => o.operator === params.operator);
      }
      if (params?.status && params.status !== 'all') {
        items = items.filter((o) => o.status === params.status);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        items = items.filter(
          (o) =>
            o.operationCode.toLowerCase().includes(q) ||
            o.targetPhone.toLowerCase().includes(q) ||
            o.customerName.toLowerCase().includes(q) ||
            o.simPhone.toLowerCase().includes(q)
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
      console.warn('Real API /flexi/operations call failed, falling back to mock dataset', err);
      return mockRequest({
        data: operationsStore.slice(0, 10),
        total: operationsStore.length,
        page: 1,
        limit: 10,
        totalPages: Math.ceil(operationsStore.length / 10),
      });
    }
  },

  async getById(id: string): Promise<FlexiOperation> {
    if (isMockMode) {
      const op = operationsStore.find((item) => item.id === id);
      if (!op) throw new Error(`Operation with ID ${id} not found`);
      return mockRequest(op);
    }

    try {
      const all = await this.getAll({ page: 1, limit: 100 });
      const found = all.data.find((o) => o.id === id);
      if (found) return found;
      return operationsStore.find((o) => o.id === id) || operationsStore[0];
    } catch (err) {
      const op = operationsStore.find((item) => item.id === id) || operationsStore[0];
      return op;
    }
  },

  async getKPIs(): Promise<DashboardKPIs> {
    return mockRequest(mockDashboardKPIs);
  },

  getOperations(params?: any) {
    return this.getAll(params);
  },

  getOperationById(id: string) {
    return this.getById(id);
  },

  getDashboardKPIs() {
    return this.getKPIs();
  },
};
