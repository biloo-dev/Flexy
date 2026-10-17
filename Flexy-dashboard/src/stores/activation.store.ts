import { defineStore } from 'pinia';
import { ref } from 'vue';
import { activationService } from '@/api/services/activation.service';
import type { Activation, PaginatedResponse, PaginationParams } from '@/types';

export const useActivationStore = defineStore('activation', () => {
  const activations = ref<Activation[]>([]);
  const total = ref<number>(0);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  async function fetchActivations(params?: PaginationParams & { result?: string; customerId?: string }) {
    loading.value = true;
    error.value = null;
    try {
      const res: PaginatedResponse<Activation> = await activationService.getActivations(params);
      activations.value = res.data;
      total.value = res.total;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch activations';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  return {
    activations,
    total,
    loading,
    error,
    fetchActivations,
  };
});
