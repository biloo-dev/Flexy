import { defineStore } from 'pinia';
import { ref } from 'vue';
import { operationService } from '@/api/services/operation.service';
import type { FlexiOperation, PaginatedResponse, PaginationParams, DashboardKPIs } from '@/types';

export const useOperationStore = defineStore('operation', () => {
  const operations = ref<FlexiOperation[]>([]);
  const currentOperation = ref<FlexiOperation | null>(null);
  const total = ref<number>(0);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  const kpis = ref<DashboardKPIs | null>(null);

  async function fetchOperations(params?: PaginationParams & { status?: string; operator?: string; customerId?: string }) {
    loading.value = true;
    error.value = null;
    try {
      const res: PaginatedResponse<FlexiOperation> = await operationService.getOperations(params);
      operations.value = res.data;
      total.value = res.total;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch operations';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchOperationById(id: string) {
    loading.value = true;
    error.value = null;
    try {
      const res = await operationService.getOperationById(id);
      currentOperation.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch operation details';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchKPIs() {
    try {
      const res = await operationService.getDashboardKPIs();
      kpis.value = res;
      return res;
    } catch (err: any) {
      console.error(err);
    }
  }

  return {
    operations,
    currentOperation,
    kpis,
    total,
    loading,
    error,
    fetchOperations,
    fetchOperationById,
    fetchKPIs,
  };
});
