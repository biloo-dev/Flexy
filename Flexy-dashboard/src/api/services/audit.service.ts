import { apiClient, extractData, isMockMode, mockRequest } from '../apiClient';
import { mockAuditLogs } from '../mock/mockData';
import type { AuditLog, PaginatedResponse, PaginationParams } from '@/types';

let auditLogsStore = [...mockAuditLogs];

export const auditService = {
  async getAll(
    params?: PaginationParams & { entityType?: string; result?: string; actorId?: string }
  ): Promise<PaginatedResponse<AuditLog>> {
    if (isMockMode) {
      let filtered = [...auditLogsStore];
      if (params?.entityType && params.entityType !== 'all') {
        filtered = filtered.filter((a) => a.entityType === params.entityType);
      }
      if (params?.result && params.result !== 'all') {
        filtered = filtered.filter((a) => a.result === params.result);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        filtered = filtered.filter(
          (a) =>
            a.action.toLowerCase().includes(q) ||
            a.actorName.toLowerCase().includes(q) ||
            a.entityId.toLowerCase().includes(q) ||
            a.ipAddress.toLowerCase().includes(q)
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
      const res = await apiClient.get('/admin/audit/events', { params: { limit: 100 } });
      const raw = extractData<any[]>(res) || [];

      let items: AuditLog[] = raw.map((a) => ({
        id: a.id,
        actorId: a.actorId || 'admin-root',
        actorName: a.actorName || 'System Administrator',
        actorEmail: a.actorEmail || 'admin@flexi.dz',
        actorRole: 'Super Admin',
        action: a.event || 'LICENSE_EVENT',
        entityType: a.simCardId ? 'SIM' : a.licenseId ? 'License' : a.deviceId ? 'Device' : 'Customer',
        entityId: a.simCardId || a.licenseId || a.deviceId || a.customerId || a.id,
        ipAddress: a.ipAddress || '127.0.0.1',
        result: 'SUCCESS',
        severity: (a.event?.includes('REVOKED') || a.event?.includes('MISMATCH') ? 'critical' : 'info') as any,
        metadata: a.metadata || {},
        timestamp: a.createdAt?.toDate ? a.createdAt.toDate().toISOString() : a.createdAt || new Date().toISOString(),
      }));

      if (items.length === 0) {
        items = auditLogsStore;
      }

      if (params?.search) {
        const q = params.search.toLowerCase();
        items = items.filter(
          (a) =>
            a.action.toLowerCase().includes(q) ||
            a.actorName.toLowerCase().includes(q) ||
            a.entityId.toLowerCase().includes(q) ||
            a.ipAddress.toLowerCase().includes(q)
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
      console.warn('Real API /admin/audit/events call failed, falling back to mock dataset', err);
      return mockRequest({
        data: auditLogsStore.slice(0, 10),
        total: auditLogsStore.length,
        page: 1,
        limit: 10,
        totalPages: Math.ceil(auditLogsStore.length / 10),
      });
    }
  },

  getAuditLogs(params?: any) {
    return this.getAll(params);
  },

  async logAction(action: string, entityType: string, entityId: string, metadata?: Record<string, any>): Promise<void> {
    if (isMockMode) {
      return;
    }
    try {
      await apiClient.post('/admin/audit/events', {
        event: action,
        entityType,
        entityId,
        metadata,
      });
    } catch (e) {
      // ignore
    }
  },
};
