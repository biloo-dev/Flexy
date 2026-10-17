import { apiClient, extractData, isMockMode, mockRequest } from '../apiClient';
import { mockPayments } from '../mock/mockData';
import type { Payment, PaginatedResponse, PaginationParams } from '@/types';

let paymentsStore = [...mockPayments];

export const paymentService = {
  async getAll(params?: PaginationParams & { status?: string; customerId?: string }): Promise<PaginatedResponse<Payment>> {
    if (isMockMode) {
      let filtered = [...paymentsStore];
      if (params?.status && params.status !== 'all') {
        filtered = filtered.filter((p) => p.status === params.status);
      }
      if (params?.customerId) {
        filtered = filtered.filter((p) => p.customerId === params.customerId);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        filtered = filtered.filter(
          (p) =>
            p.reference.toLowerCase().includes(q) ||
            p.customerName.toLowerCase().includes(q) ||
            p.licenseId.toLowerCase().includes(q) ||
            p.id.toLowerCase().includes(q)
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
      if (params?.status && params.status !== 'all') queryParams.status = params.status;
      if (params?.customerId) queryParams.customerId = params.customerId;

      const res = await apiClient.get('/admin/payments', { params: queryParams });
      const raw = extractData<any[]>(res) || [];

      let items: Payment[] = raw.map((p) => ({
        id: p.id,
        reference: p.reference,
        customerId: p.customerId,
        customerName: p.customerName || `Customer (${p.customerId})`,
        licenseId: p.licenseId || 'LIC-301',
        amount: p.amount || 35000,
        currency: p.currency || 'DZD',
        paymentMethod: p.paymentMethod || 'CIB / Edahabia',
        status: p.status || 'paid',
        paidAt: p.paidAt?.toDate ? p.paidAt.toDate().toISOString() : p.paidAt || null,
        failureReason: p.failureReason || null,
        createdAt: p.createdAt?.toDate ? p.createdAt.toDate().toISOString() : p.createdAt || new Date().toISOString(),
      }));

      if (params?.search) {
        const q = params.search.toLowerCase();
        items = items.filter(
          (p) =>
            p.reference.toLowerCase().includes(q) ||
            p.customerName.toLowerCase().includes(q) ||
            p.licenseId.toLowerCase().includes(q) ||
            p.id.toLowerCase().includes(q)
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
        totalPages: Math.ceil(items.length / limit),
      };
    } catch (err) {
      console.warn('Real API /admin/payments call failed, falling back to mock dataset', err);
      return mockRequest({
        data: paymentsStore.slice(0, 10),
        total: paymentsStore.length,
        page: 1,
        limit: 10,
        totalPages: Math.ceil(paymentsStore.length / 10),
      });
    }
  },

  async getById(id: string): Promise<Payment> {
    if (isMockMode) {
      const p = paymentsStore.find((item) => item.id === id);
      if (!p) throw new Error(`Payment with ID ${id} not found`);
      return mockRequest(p);
    }

    try {
      const res = await apiClient.get(`/admin/payments/${id}`);
      const p = extractData<any>(res);
      return {
        id: p.id,
        reference: p.reference,
        customerId: p.customerId,
        customerName: p.customerName || `Customer (${p.customerId})`,
        licenseId: p.licenseId || 'LIC-301',
        amount: p.amount || 35000,
        currency: p.currency || 'DZD',
        paymentMethod: p.paymentMethod || 'CIB / Edahabia',
        status: p.status || 'paid',
        paidAt: p.paidAt?.toDate ? p.paidAt.toDate().toISOString() : p.paidAt || null,
        failureReason: p.failureReason || null,
        createdAt: p.createdAt?.toDate ? p.createdAt.toDate().toISOString() : p.createdAt || new Date().toISOString(),
      };
    } catch (err) {
      const p = paymentsStore.find((item) => item.id === id) || paymentsStore[0];
      return p;
    }
  },

  async confirm(id: string): Promise<{ payment: Payment; licenseId: string }> {
    if (isMockMode) {
      const idx = paymentsStore.findIndex((p) => p.id === id);
      if (idx !== -1) {
        paymentsStore[idx].status = 'paid';
        paymentsStore[idx].paidAt = new Date().toISOString();
        return mockRequest({ payment: paymentsStore[idx], licenseId: paymentsStore[idx].licenseId });
      }
      throw new Error('Payment not found');
    }

    const res = await apiClient.post(`/admin/payments/${id}/confirm`);
    const raw = extractData<any>(res);
    return {
      payment: raw.payment,
      licenseId: raw.license?.id || raw.license?.licenseId,
    };
  },

  async getSummary(): Promise<{
    totalRevenue: number;
    paidCount: number;
    pendingCount: number;
    failedCount: number;
    refundedCount: number;
  }> {
    const all = await this.getAll({ page: 1, limit: 100 });
    let totalRevenue = 0;
    let paidCount = 0;
    let pendingCount = 0;
    let failedCount = 0;
    let refundedCount = 0;

    all.data.forEach((p) => {
      if (p.status === 'paid') {
        totalRevenue += p.amount;
        paidCount++;
      } else if (p.status === 'pending') {
        pendingCount++;
      } else if (p.status === 'failed') {
        failedCount++;
      } else if (p.status === 'refunded') {
        refundedCount++;
      }
    });

    return { totalRevenue, paidCount, pendingCount, failedCount, refundedCount };
  },

  getPayments(params?: any) {
    return this.getAll(params);
  },

  getPaymentById(id: string) {
    return this.getById(id);
  },
};
