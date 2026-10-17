import { defineStore } from 'pinia';
import { ref } from 'vue';
import { deviceService } from '@/api/services/device.service';
import type { Device, PaginatedResponse, PaginationParams } from '@/types';

export const useDeviceStore = defineStore('device', () => {
  const devices = ref<Device[]>([]);
  const currentDevice = ref<Device | null>(null);
  const total = ref<number>(0);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  async function fetchDevices(params?: PaginationParams & { status?: string; customerId?: string }) {
    loading.value = true;
    error.value = null;
    try {
      const res: PaginatedResponse<Device> = await deviceService.getDevices(params);
      devices.value = res.data;
      total.value = res.total;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch devices';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchDeviceById(id: string) {
    loading.value = true;
    error.value = null;
    try {
      const res = await deviceService.getDeviceById(id);
      currentDevice.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch device details';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function registerDevice(data: { customerId: string; deviceUuid: string; deviceFingerprint: string; name?: string }) {
    const created = await deviceService.registerDevice(data);
    devices.value.unshift(created);
    total.value += 1;
    return created;
  }

  return {
    devices,
    currentDevice,
    total,
    loading,
    error,
    fetchDevices,
    fetchDeviceById,
    registerDevice,
  };
});
