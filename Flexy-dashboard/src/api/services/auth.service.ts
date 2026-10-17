import { apiClient, extractData, isMockMode, mockRequest } from '../apiClient';
import type { AdminUser } from '@/types';

export interface LoginCredentials {
  email: string;
  password?: string;
}

export interface LoginResponse {
  token: string;
  user: AdminUser;
}

export const authService = {
  async login(credentials: LoginCredentials): Promise<LoginResponse> {
    if (isMockMode) {
      const mockUser: AdminUser = {
        id: 'admin-root',
        name: 'System Administrator',
        email: credentials.email,
        role: 'Super Admin',
        status: 'active',
        permissions: ['*'],
        lastLoginAt: new Date().toISOString(),
        createdAt: new Date().toISOString(),
      };
      return mockRequest({
        token: 'mock_jwt_token_admin_2026',
        user: mockUser,
      });
    }

    const res = await apiClient.post('/auth/admin/login', {
      email: credentials.email,
      password: credentials.password || 'AdminFlexi2026!',
    });
    const data = extractData<{ accessToken: string; role: string; expiresIn: string }>(res);

    const user: AdminUser = {
      id: 'admin-root',
      name: 'System Administrator',
      email: credentials.email,
      role: 'Super Admin',
      status: 'active',
      permissions: ['*'],
      lastLoginAt: new Date().toISOString(),
      createdAt: new Date().toISOString(),
    };

    return {
      token: data.accessToken,
      user,
    };
  },

  async getCurrentUser(): Promise<AdminUser> {
    const cachedUser = localStorage.getItem('flexi_auth_user');
    if (cachedUser) {
      try {
        return JSON.parse(cachedUser);
      } catch (e) {
        // continue
      }
    }

    return {
      id: 'admin-root',
      name: 'System Administrator',
      email: 'admin@flexi.dz',
      role: 'Super Admin',
      status: 'active',
      permissions: ['*'],
      lastLoginAt: new Date().toISOString(),
      createdAt: new Date().toISOString(),
    };
  },

  logout(): void {
    localStorage.removeItem('flexi_auth_token');
    localStorage.removeItem('flexi_auth_user');
  },
};
