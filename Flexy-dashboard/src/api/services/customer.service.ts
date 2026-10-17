import { apiClient, extractData, isMockMode, mockRequest } from '../apiClient';
import { mockCustomers } from '../mock/mockData';
import type { Customer, PaginatedResponse, PaginationParams } from '@/types';

let customersStore = [...mockCustomers];

function parseTimestamp(val: any): string {
  if (!val) return new Date().toISOString();
  if (typeof val === 'string') return val;
  if (val.toDate && typeof val.toDate === 'function') return val.toDate().toISOString();
  if (val._seconds) return new Date(val._seconds * 1000).toISOString();
  if (val.seconds) return new Date(val.seconds * 1000).toISOString();
  return new Date().toISOString();
}

export const customerService = {
  async getAll(params?: PaginationParams & { status?: string }): Promise<PaginatedResponse<Customer>> {
    if (isMockMode) {
      let filtered = [...customersStore];
      if (params?.status && params.status !== 'all') {
        filtered = filtered.filter((c) => c.status === params.status);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        filtered = filtered.filter(
          (c) =>
            c.name.toLowerCase().includes(q) ||
            c.phone.toLowerCase().includes(q) ||
            c.email.toLowerCase().includes(q) ||
            c.id.toLowerCase().includes(q)
        );
      }
      const page = params?.page || 1;
      const limit = params?.limit || 10;
      const start = (page - 1) * limit;
      return mockRequest({
        data: filtered.slice(start, start + limit),
        total: filtered.length,
        page,
        limit,
        totalPages: Math.ceil(filtered.length / limit),
      });
    }

    try {
      const queryParams: Record<string, any> = {};
      if (params?.status && params.status !== 'all') {
        queryParams.status = params.status;
      }
      const res = await apiClient.get('/admin/customers', { params: queryParams });
      const rawData = extractData<any[]>(res) || [];

      let items: Customer[] = rawData.map((item) => ({
        id: item.id,
        name: item.name,
        email: item.email || '',
        phone: item.phone,
        company: item.company || 'Enterprise Partner',
        address: item.address || 'Algiers, Algeria',
        status: item.status || 'active',
        devicesCount: item.devicesCount ?? 0,
        simsCount: item.simsCount ?? 0,
        licensesCount: item.licensesCount ?? 0,
        operationsCount: item.operationsCount ?? 0,
        totalRevenue: item.totalRevenue ?? 0,
        createdAt: parseTimestamp(item.createdAt),
        updatedAt: parseTimestamp(item.updatedAt),
      }));

      if (params?.search) {
        const q = params.search.toLowerCase();
        items = items.filter(
          (c) =>
            c.name.toLowerCase().includes(q) ||
            c.phone.toLowerCase().includes(q) ||
            c.email.toLowerCase().includes(q) ||
            c.id.toLowerCase().includes(q)
        );
      }

      const page = params?.page || 1;
      const limit = params?.limit || 10;
      const start = (page - 1) * limit;

      return {
        data: items.slice(start, start + limit),
        total: items.length,
        page,
        limit,
        totalPages: Math.ceil(items.length / limit) || 1,
      };
    } catch (err) {
      console.warn('Real API /admin/customers call failed, falling back to mock dataset', err);
      return mockRequest({
        data: customersStore.slice(0, 10),
        total: customersStore.length,
        page: 1,
        limit: 10,
        totalPages: Math.ceil(customersStore.length / 10),
      });
    }
  },

  async getById(id: string): Promise<Customer> {
    if (isMockMode) {
      const c = customersStore.find((item) => item.id === id);
      if (!c) throw new Error(`Customer with ID ${id} not found`);
      return mockRequest(c);
    }

    try {
      const res = await apiClient.get(`/admin/customers/${id}`);
      const raw = extractData<any>(res);
      return {
        id: raw.id,
        name: raw.name,
        email: raw.email || '',
        phone: raw.phone,
        company: raw.company || 'Enterprise Partner',
        address: raw.address || 'Algiers, Algeria',
        status: raw.status || 'active',
        devicesCount: raw.devicesCount ?? 0,
        simsCount: raw.simsCount ?? 0,
        licensesCount: raw.licensesCount ?? 0,
        operationsCount: raw.operationsCount ?? 0,
        totalRevenue: raw.totalRevenue ?? 0,
        createdAt: parseTimestamp(raw.createdAt),
        updatedAt: parseTimestamp(raw.updatedAt),
      };
    } catch (err) {
      const c = customersStore.find((item) => item.id === id) || customersStore[0];
      return c;
    }
  },

  async create(data: Partial<Customer>): Promise<Customer> {
    if (isMockMode) {
      const newCustomer: Customer = {
        id: `CUST-${1000 + customersStore.length + 1}`,
        name: data.name || '',
        email: data.email || '',
        phone: data.phone || '',
        company: data.company || 'Enterprise Partner',
        address: data.address || 'Algiers, Algeria',
        status: data.status || 'active',
        devicesCount: 0,
        simsCount: 0,
        licensesCount: 0,
        operationsCount: 0,
        totalRevenue: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      customersStore.unshift(newCustomer);
      return mockRequest(newCustomer);
    }

    const payload: Record<string, any> = {
      name: data.name,
      phone: data.phone,
      status: data.status || 'active',
    };
    if (data.email && data.email.trim().length > 0) {
      payload.email = data.email.trim();
    }
    if (data.company && data.company.trim().length > 0) {
      payload.company = data.company.trim();
    }
    if (data.address && data.address.trim().length > 0) {
      payload.address = data.address.trim();
    }

    const res = await apiClient.post('/admin/customers', payload);
    const raw = extractData<any>(res);
    return {
      id: raw.id,
      name: raw.name,
      email: raw.email || '',
      phone: raw.phone,
      company: raw.company || 'Enterprise Partner',
      address: raw.address || 'Algiers, Algeria',
      status: raw.status || 'active',
      devicesCount: 0,
      simsCount: 0,
      licensesCount: 0,
      operationsCount: 0,
      totalRevenue: 0,
      createdAt: parseTimestamp(raw.createdAt),
      updatedAt: parseTimestamp(raw.updatedAt),
    };
  },

  async update(id: string, data: Partial<Customer>): Promise<Customer> {
    if (isMockMode) {
      const idx = customersStore.findIndex((c) => c.id === id);
      if (idx !== -1) {
        customersStore[idx] = { ...customersStore[idx], ...data, updatedAt: new Date().toISOString() };
        return mockRequest(customersStore[idx]);
      }
      throw new Error('Customer not found');
    }

    const payload: Record<string, any> = {
      name: data.name,
      phone: data.phone,
      status: data.status,
    };
    if (data.email && data.email.trim().length > 0) payload.email = data.email.trim();
    if (data.company) payload.company = data.company;
    if (data.address) payload.address = data.address;

    const res = await apiClient.put(`/admin/customers/${id}`, payload);
    return extractData<Customer>(res);
  },

  async updateStatus(id: string, status: Customer['status']): Promise<Customer> {
    if (isMockMode) {
      const idx = customersStore.findIndex((c) => c.id === id);
      if (idx !== -1) {
        customersStore[idx].status = status;
        customersStore[idx].updatedAt = new Date().toISOString();
        return mockRequest(customersStore[idx]);
      }
      throw new Error('Customer not found');
    }

    const res = await apiClient.patch(`/admin/customers/${id}/status`, { status });
    return extractData<Customer>(res);
  },

  async delete(id: string): Promise<boolean> {
    if (isMockMode) {
      customersStore = customersStore.filter((c) => c.id !== id);
      return mockRequest(true);
    }
    await apiClient.delete(`/admin/customers/${id}`);
    return true;
  },

  getCustomers(params?: any) {
    return this.getAll(params);
  },

  getCustomerById(id: string) {
    return this.getById(id);
  },

  createCustomer(data: Partial<Customer>) {
    return this.create(data);
  },

  deleteCustomer(id: string) {
    return this.delete(id);
  },
};
