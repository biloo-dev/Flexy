import { defineStore } from 'pinia';
import { ref } from 'vue';
import { monitoringService } from '@/api/services/monitoring.service';
import type { SystemServiceHealth, Heartbeat } from '@/types';

export const useMonitoringStore = defineStore('monitoring', () => {
  const services = ref<SystemServiceHealth[]>([]);
  const heartbeats = ref<Heartbeat[]>([]);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  async function fetchServices() {
    loading.value = true;
    try {
      const res = await monitoringService.getSystemServices();
      services.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message;
    } finally {
      loading.value = false;
    }
  }

  async function fetchHeartbeats() {
    try {
      const res = await monitoringService.getLiveHeartbeats();
      heartbeats.value = res;
      return res;
    } catch (err: any) {
      console.error(err);
    }
  }

  return {
    services,
    heartbeats,
    loading,
    error,
    fetchServices,
    fetchHeartbeats,
  };
});
