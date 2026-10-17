import { mockRequest } from '../apiClient';
import { mockActivations } from '../mock/mockData';
import type { Activation, PaginatedResponse, PaginationParams } from '@/types';

let activationsStore = [...mockActivations];

export const activationService = {
  async getActivations(params?: PaginationParams & { result?: string; customerId?: string }): Promise<PaginatedResponse<Activation>> {
    let filtered = [...activationsStore];

    if (params?.search) {
      const q = params.search.toLowerCase();
      filtered = filtered.filter(
        (a) =>
          a.licenseSerial.toLowerCase().includes(q) ||
          a.customerName.toLowerCase().includes(q) ||
          a.simPhone.toLowerCase().includes(q) ||
          a.deviceName.toLowerCase().includes(q) ||
          (a.failureReason && a.failureReason.toLowerCase().includes(q))
      );
    }

    if (params?.result && params.result !== 'all') {
      filtered = filtered.filter((a) => a.result === params.result);
    }

    if (params?.customerId) {
      filtered = filtered.filter((a) => a.customerId === params.customerId);
    }

    const page = params?.page || 1;
    const limit = params?.limit || 10;
    const start = (page - 1) * limit;
    const paginatedData = filtered.slice(start, start + limit);

    return mockRequest({
      data: paginatedData,
      total: filtered.length,
      page,
      limit,
      totalPages: Math.ceil(filtered.length / limit),
    }, 140);
  }
};
