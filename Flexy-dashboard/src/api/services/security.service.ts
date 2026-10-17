import { mockRequest } from '../apiClient';
import { mockSecurityEvents } from '../mock/mockData';
import type { SecurityEvent, PaginatedResponse, PaginationParams } from '@/types';

let securityEventsStore = [...mockSecurityEvents];

export const securityService = {
  async getSecurityEvents(params?: PaginationParams & { severity?: string; resolved?: string }): Promise<PaginatedResponse<SecurityEvent>> {
    let filtered = [...securityEventsStore];

    if (params?.search) {
      const q = params.search.toLowerCase();
      filtered = filtered.filter(
        (e) =>
          e.title.toLowerCase().includes(q) ||
          e.description.toLowerCase().includes(q) ||
          e.type.toLowerCase().includes(q) ||
          (e.customerName && e.customerName.toLowerCase().includes(q)) ||
          e.ipAddress.includes(q)
      );
    }

    if (params?.severity && params.severity !== 'all') {
      filtered = filtered.filter((e) => e.severity === params.severity);
    }

    if (params?.resolved !== undefined && params.resolved !== 'all') {
      const isResolved = params.resolved === 'true';
      filtered = filtered.filter((e) => e.resolved === isResolved);
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
  },

  async resolveEvent(id: string): Promise<SecurityEvent> {
    const ev = securityEventsStore.find((e) => e.id === id);
    if (!ev) throw new Error('Security event not found');
    ev.resolved = true;
    return mockRequest({ ...ev }, 180);
  },

  async getSecurityStats(): Promise<{
    iccidMismatches: number;
    deviceMismatches: number;
    invalidSignatures: number;
    blockedOperations: number;
    revokedLicenses: number;
    unresolvedCount: number;
  }> {
    return mockRequest({
      iccidMismatches: 14,
      deviceMismatches: 8,
      invalidSignatures: 3,
      blockedOperations: 450,
      revokedLicenses: 2,
      unresolvedCount: securityEventsStore.filter((e) => !e.resolved).length,
    }, 120);
  }
};
