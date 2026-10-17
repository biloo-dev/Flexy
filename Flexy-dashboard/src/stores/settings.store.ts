import { defineStore } from 'pinia';
import { ref } from 'vue';
import { settingsService } from '@/api/services/settings.service';
import type { KeyVersion, AdminUser } from '@/types';

export const useSettingsStore = defineStore('settings', () => {
  const keyVersions = ref<KeyVersion[]>([]);
  const adminUsers = ref<AdminUser[]>([]);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  async function fetchKeyVersions() {
    loading.value = true;
    try {
      const res = await settingsService.getKeyVersions();
      keyVersions.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message;
    } finally {
      loading.value = false;
    }
  }

  async function rotateKey(newKeyId: string) {
    loading.value = true;
    try {
      const newKey = await settingsService.rotateKey(newKeyId);
      await fetchKeyVersions();
      return newKey;
    } catch (err: any) {
      error.value = err.message;
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchAdminUsers() {
    loading.value = true;
    try {
      const res = await settingsService.getAdminUsers();
      adminUsers.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message;
    } finally {
      loading.value = false;
    }
  }

  async function createUser(data: Partial<AdminUser>) {
    const newUser = await settingsService.createUser(data);
    adminUsers.value.push(newUser);
    return newUser;
  }

  async function updateUserRole(id: string, role: AdminUser['role'], permissions: string[]) {
    const updated = await settingsService.updateUserRole(id, role, permissions);
    const index = adminUsers.value.findIndex((u) => u.id === id);
    if (index !== -1) adminUsers.value[index] = updated;
    return updated;
  }

  return {
    keyVersions,
    adminUsers,
    loading,
    error,
    fetchKeyVersions,
    rotateKey,
    fetchAdminUsers,
    createUser,
    updateUserRole,
  };
});
