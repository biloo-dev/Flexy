import { defineStore } from 'pinia';
import { ref } from 'vue';
import { licenseService } from '@/api/services/license.service';
import type { License, PaginatedResponse, PaginationParams } from '@/types';

export const useLicenseStore = defineStore('license', () => {
  const licenses = ref<License[]>([]);
  const currentLicense = ref<License | null>(null);
  const total = ref<number>(0);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  const expiringLicenses = ref<{
    expired: License[];
    today: License[];
    in3Days: License[];
    in7Days: License[];
    in30Days: License[];
  }>({
    expired: [],
    today: [],
    in3Days: [],
    in7Days: [],
    in30Days: [],
  });

  async function fetchLicenses(params?: PaginationParams & { status?: string; operator?: string; customerId?: string }) {
    loading.value = true;
    error.value = null;
    try {
      const res: PaginatedResponse<License> = await licenseService.getLicenses(params);
      licenses.value = res.data;
      total.value = res.total;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch licenses';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchLicenseById(id: string) {
    loading.value = true;
    error.value = null;
    try {
      const res = await licenseService.getLicenseById(id);
      currentLicense.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch license details';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchExpiringLicenses() {
    loading.value = true;
    error.value = null;
    try {
      const res = await licenseService.getExpiringLicenses();
      expiringLicenses.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch expiring licenses';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function revokeLicense(id: string, reason: string) {
    const updated = await licenseService.revokeLicense(id, reason);
    const index = licenses.value.findIndex((l) => l.id === id);
    if (index !== -1) licenses.value[index] = updated;
    if (currentLicense.value?.id === id) currentLicense.value = updated;
    return updated;
  }

  async function activateLicense(id: string) {
    const updated = await licenseService.activateLicense(id);
    const index = licenses.value.findIndex((l) => l.id === id);
    if (index !== -1) licenses.value[index] = updated;
    if (currentLicense.value?.id === id) currentLicense.value = updated;
    return updated;
  }

  async function suspendLicense(id: string) {
    const updated = await licenseService.suspendLicense(id);
    const index = licenses.value.findIndex((l) => l.id === id);
    if (index !== -1) licenses.value[index] = updated;
    if (currentLicense.value?.id === id) currentLicense.value = updated;
    return updated;
  }

  async function renewLicense(id: string, months: number = 12) {
    const updated = await licenseService.renewLicense(id, months);
    const index = licenses.value.findIndex((l) => l.id === id);
    if (index !== -1) licenses.value[index] = updated;
    if (currentLicense.value?.id === id) currentLicense.value = updated;
    return updated;
  }

  async function createLicense(data: Partial<License>) {
    const created = await licenseService.create(data);
    licenses.value.unshift(created);
    total.value += 1;
    return created;
  }

  async function regenerateSerial(id: string, validityDays: number = 365) {
    const updated = await licenseService.regenerateSerial(id, validityDays);
    const index = licenses.value.findIndex((l) => l.id === id);
    if (index !== -1) licenses.value[index] = updated;
    if (currentLicense.value?.id === id) currentLicense.value = updated;
    return updated;
  }

  async function deleteLicense(id: string) {
    await licenseService.delete(id);
    licenses.value = licenses.value.filter((l) => l.id !== id);
    total.value = Math.max(0, total.value - 1);
    if (currentLicense.value?.id === id) currentLicense.value = null;
  }

  return {
    licenses,
    currentLicense,
    expiringLicenses,
    total,
    loading,
    error,
    fetchLicenses,
    fetchLicenseById,
    fetchExpiringLicenses,
    revokeLicense,
    activateLicense,
    suspendLicense,
    renewLicense,
    createLicense,
    regenerateSerial,
    deleteLicense,
  };
});
