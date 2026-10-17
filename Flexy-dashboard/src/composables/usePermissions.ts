import { computed } from 'vue';
import { useAuthStore } from '@/stores/auth.store';

export function usePermissions() {
  const authStore = useAuthStore();

  const hasPermission = (permission: string): boolean => {
    if (!authStore.user) return false;
    if (authStore.user.role === 'Super Admin') return true;
    return authStore.user.permissions.includes(permission) || authStore.user.permissions.includes('*');
  };

  const hasAnyPermission = (permissions: string[]): boolean => {
    if (!authStore.user) return false;
    if (authStore.user.role === 'Super Admin') return true;
    return permissions.some(p => hasPermission(p));
  };

  const hasAllPermissions = (permissions: string[]): boolean => {
    if (!authStore.user) return false;
    if (authStore.user.role === 'Super Admin') return true;
    return permissions.every(p => hasPermission(p));
  };

  const isSuperAdmin = computed(() => authStore.user?.role === 'Super Admin');
  const isAdmin = computed(() => authStore.user?.role === 'Super Admin' || authStore.user?.role === 'Admin');

  return {
    hasPermission,
    hasAnyPermission,
    hasAllPermissions,
    isSuperAdmin,
    isAdmin,
  };
}
