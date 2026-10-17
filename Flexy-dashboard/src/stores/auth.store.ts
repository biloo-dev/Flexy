import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { authService, type LoginCredentials } from '@/api/services/auth.service';
import type { AdminUser } from '@/types';

export const useAuthStore = defineStore('auth', () => {
  const user = ref<AdminUser | null>(
    localStorage.getItem('flexi_auth_user')
      ? JSON.parse(localStorage.getItem('flexi_auth_user')!)
      : null
  );
  const token = ref<string | null>(localStorage.getItem('flexi_auth_token') || null);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  const isAuthenticated = computed(() => !!token.value && !!user.value);
  const currentRole = computed(() => user.value?.role || 'Guest');

  async function login(credentials: LoginCredentials) {
    loading.value = true;
    error.value = null;
    try {
      const response = await authService.login(credentials);
      user.value = response.user;
      token.value = response.token;
      localStorage.setItem('flexi_auth_token', response.token);
      localStorage.setItem('flexi_auth_user', JSON.stringify(response.user));
      return response;
    } catch (err: any) {
      error.value = err.message || 'Authentication failed';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchCurrentUser() {
    if (!token.value) return;
    try {
      const currentUser = await authService.getCurrentUser();
      user.value = currentUser;
      localStorage.setItem('flexi_auth_user', JSON.stringify(currentUser));
    } catch (err) {
      logout();
    }
  }

  function logout() {
    authService.logout();
    user.value = null;
    token.value = null;
  }

  return {
    user,
    token,
    loading,
    error,
    isAuthenticated,
    currentRole,
    login,
    logout,
    fetchCurrentUser,
  };
});
