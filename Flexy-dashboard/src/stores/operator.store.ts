import { defineStore } from 'pinia';
import { ref } from 'vue';
import { operatorService } from '@/api/services/operator.service';
import type { Operator } from '@/types';

export const useOperatorStore = defineStore('operator', () => {
  const operators = ref<Operator[]>([]);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  async function fetchOperators() {
    loading.value = true;
    error.value = null;
    try {
      const res = await operatorService.getOperators();
      operators.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch operators';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function toggleStatus(id: string) {
    const updated = await operatorService.toggleStatus(id);
    const index = operators.value.findIndex((o) => o.id === id);
    if (index !== -1) operators.value[index] = updated;
    return updated;
  }

  return {
    operators,
    loading,
    error,
    fetchOperators,
    toggleStatus,
  };
});
