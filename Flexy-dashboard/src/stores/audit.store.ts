import { defineStore } from 'pinia';
import { ref } from 'vue';
import { auditService } from '@/api/services/audit.service';
import type { AuditLog, PaginatedResponse, PaginationParams } from '@/types';

export const useAuditStore = defineStore('audit', () => {
  const logs = ref<AuditLog[]>([]);
  const total = ref<number>(0);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  async function fetchAuditLogs(params?: PaginationParams & { entityType?: string; severity?: string }) {
    loading.value = true;
    error.value = null;
    try {
      const res: PaginatedResponse<AuditLog> = await auditService.getAuditLogs(params);
      logs.value = res.data;
      total.value = res.total;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch audit logs';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function logAction(action: string, entityType: AuditLog['entityType'], entityId: string, details?: any) {
    await auditService.logAction(action, entityType, entityId, details);
  }

  return {
    logs,
    total,
    loading,
    error,
    fetchAuditLogs,
    logAction,
  };
});
