import { mockRequest } from '../apiClient';
import { mockKeyVersions, mockAdminUsers } from '../mock/mockData';
import type { KeyVersion, AdminUser } from '@/types';

let keysStore = [...mockKeyVersions];
let usersStore = [...mockAdminUsers];

export const settingsService = {
  async getKeyVersions(): Promise<KeyVersion[]> {
    return mockRequest(keysStore, 120);
  },

  async rotateKey(newKeyId: string): Promise<KeyVersion> {
    // Retire current active key
    const currentActive = keysStore.find((k) => k.status === 'active');
    if (currentActive) {
      currentActive.status = 'retired';
      currentActive.rotationDate = new Date().toISOString();
    }

    const randomFingerprint = 'SHA256:' + Array.from({ length: 64 }, () => Math.floor(Math.random() * 16).toString(16)).join('');

    const newKey: KeyVersion = {
      id: `KEY-${newKeyId}`,
      keyId: newKeyId,
      algorithm: 'Ed25519',
      publicKeyFingerprint: randomFingerprint,
      status: 'active',
      activeLicensesCount: 0,
      totalLicensesIssued: 0,
      createdAt: new Date().toISOString(),
    };

    keysStore.unshift(newKey);
    return mockRequest(newKey, 300);
  },

  async getAdminUsers(): Promise<AdminUser[]> {
    return mockRequest(usersStore, 120);
  },

  async createUser(data: Partial<AdminUser>): Promise<AdminUser> {
    const newUser: AdminUser = {
      id: `USR-0${usersStore.length + 1}`,
      name: data.name || 'New Admin',
      email: data.email || 'admin@flexi-platform.dz',
      role: data.role || 'Support',
      status: 'active',
      permissions: data.permissions || ['customers.read', 'licenses.read'],
      createdAt: new Date().toISOString(),
    };
    usersStore.push(newUser);
    return mockRequest(newUser, 200);
  },

  async updateUserRole(id: string, role: AdminUser['role'], permissions: string[]): Promise<AdminUser> {
    const user = usersStore.find((u) => u.id === id);
    if (!user) throw new Error('User not found');
    user.role = role;
    user.permissions = permissions;
    return mockRequest({ ...user }, 200);
  }
};
