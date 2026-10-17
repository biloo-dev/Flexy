import { defineStore } from 'pinia';
import { ref } from 'vue';
import { simService } from '@/api/services/sim.service';
import type { SimCard, PaginatedResponse, PaginationParams } from '@/types';

export const useSimStore = defineStore('sim', () => {
  const simCards = ref<SimCard[]>([]);
  const currentSim = ref<SimCard | null>(null);
  const total = ref<number>(0);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  async function fetchSimCards(params?: PaginationParams & { operator?: string; status?: string; customerId?: string }) {
    loading.value = true;
    error.value = null;
    try {
      const res: PaginatedResponse<SimCard> = await simService.getSimCards(params);
      simCards.value = res.data;
      total.value = res.total;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch SIM cards';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchSimById(id: string) {
    loading.value = true;
    error.value = null;
    try {
      const res = await simService.getSimById(id);
      currentSim.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch SIM details';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function blockSim(id: string) {
    const updated = await simService.blockSim(id);
    const index = simCards.value.findIndex((s) => s.id === id);
    if (index !== -1) simCards.value[index] = updated;
    if (currentSim.value?.id === id) currentSim.value = updated;
    return updated;
  }

  async function activateSim(id: string) {
    const updated = await simService.activateSim(id);
    const index = simCards.value.findIndex((s) => s.id === id);
    if (index !== -1) simCards.value[index] = updated;
    if (currentSim.value?.id === id) currentSim.value = updated;
    return updated;
  }

  async function createSim(data: {
    customerId: string;
    operatorId: string;
    iccid: string;
    phoneNumber?: string;
    requiredForAccess?: boolean;
  }) {
    loading.value = true;
    error.value = null;
    try {
      const newSim = await simService.create(data);
      simCards.value.unshift(newSim);
      total.value += 1;
      return newSim;
    } catch (err: any) {
      error.value = err.message || 'Failed to create SIM card';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function transferOwnership(id: string, newCustomerId: string) {
    loading.value = true;
    error.value = null;
    try {
      const updated = await simService.transferOwnership(id, newCustomerId);
      const index = simCards.value.findIndex((s) => s.id === id);
      if (index !== -1) simCards.value[index] = updated;
      if (currentSim.value?.id === id) currentSim.value = updated;
      return updated;
    } catch (err: any) {
      error.value = err.message || 'Failed to transfer SIM ownership';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function deleteSim(id: string) {
    loading.value = true;
    error.value = null;
    try {
      await simService.deleteSim(id);
      simCards.value = simCards.value.filter((s) => s.id !== id);
      total.value = Math.max(0, total.value - 1);
      if (currentSim.value?.id === id) currentSim.value = null;
      return true;
    } catch (err: any) {
      error.value = err.message || 'Failed to delete SIM card';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function updateSim(id: string, data: Partial<SimCard>) {
    loading.value = true;
    error.value = null;
    try {
      const updated = await simService.update(id, data);
      const index = simCards.value.findIndex((s) => s.id === id);
      if (index !== -1) simCards.value[index] = updated;
      if (currentSim.value?.id === id) currentSim.value = updated;
      return updated;
    } catch (err: any) {
      error.value = err.message || 'Failed to update SIM card';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  return {
    simCards,
    currentSim,
    total,
    loading,
    error,
    fetchSimCards,
    fetchSimById,
    createSim,
    updateSim,
    blockSim,
    activateSim,
    transferOwnership,
    deleteSim,
  };
});
