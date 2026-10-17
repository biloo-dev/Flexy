import { defineStore } from 'pinia';
import { ref } from 'vue';
import { modemService } from '@/api/services/modem.service';
import type { Modem, PaginatedResponse, PaginationParams } from '@/types';

export const useModemStore = defineStore('modem', () => {
  const modems = ref<Modem[]>([]);
  const currentModem = ref<Modem | null>(null);
  const total = ref<number>(0);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  async function fetchModems(params?: PaginationParams & { status?: string; deviceId?: string }) {
    loading.value = true;
    error.value = null;
    try {
      const res: PaginatedResponse<Modem> = await modemService.getModems(params);
      modems.value = res.data;
      total.value = res.total;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch modems';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchModemById(id: string) {
    loading.value = true;
    error.value = null;
    try {
      const res = await modemService.getModemById(id);
      currentModem.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch modem details';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  return {
    modems,
    currentModem,
    total,
    loading,
    error,
    fetchModems,
    fetchModemById,
  };
});
