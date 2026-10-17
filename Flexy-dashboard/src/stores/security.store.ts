import { defineStore } from 'pinia';
import { ref } from 'vue';
import { securityService } from '@/api/services/security.service';
import type { SecurityEvent, PaginatedResponse, PaginationParams } from '@/types';

export const useSecurityStore = defineStore('security', () => {
  const events = ref<SecurityEvent[]>([]);
  const total = ref<number>(0);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  const stats = ref({
    iccidMismatches: 0,
    deviceMismatches: 0,
    invalidSignatures: 0,
    blockedOperations: 0,
    revokedLicenses: 0,
    unresolvedCount: 0,
  });

  async function fetchSecurityEvents(params?: PaginationParams & { severity?: string; resolved?: string }) {
    loading.value = true;
    error.value = null;
    try {
      const res: PaginatedResponse<SecurityEvent> = await securityService.getSecurityEvents(params);
      events.value = res.data;
      total.value = res.total;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch security events';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function resolveEvent(id: string) {
    const updated = await securityService.resolveEvent(id);
    const index = events.value.findIndex((e) => e.id === id);
    if (index !== -1) events.value[index] = updated;
    await fetchStats();
    return updated;
  }

  async function fetchStats() {
    try {
      const res = await securityService.getSecurityStats();
      stats.value = res;
      return res;
    } catch (err: any) {
      console.error(err);
    }
  }

  return {
    events,
    stats,
    total,
    loading,
    error,
    fetchSecurityEvents,
    resolveEvent,
    fetchStats,
  };
});
