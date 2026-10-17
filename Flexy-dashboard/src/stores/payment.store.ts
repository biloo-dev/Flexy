import { defineStore } from 'pinia';
import { ref } from 'vue';
import { paymentService } from '@/api/services/payment.service';
import type { Payment, PaginatedResponse, PaginationParams } from '@/types';

export const usePaymentStore = defineStore('payment', () => {
  const payments = ref<Payment[]>([]);
  const currentPayment = ref<Payment | null>(null);
  const total = ref<number>(0);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  const summary = ref({
    totalRevenue: 0,
    pendingCount: 0,
    paidCount: 0,
    failedCount: 0,
    refundedCount: 0,
  });

  async function fetchPayments(params?: PaginationParams & { status?: string; customerId?: string }) {
    loading.value = true;
    error.value = null;
    try {
      const res: PaginatedResponse<Payment> = await paymentService.getPayments(params);
      payments.value = res.data;
      total.value = res.total;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch payments';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchPaymentById(id: string) {
    loading.value = true;
    error.value = null;
    try {
      const res = await paymentService.getPaymentById(id);
      currentPayment.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch payment details';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchSummary() {
    try {
      const res = await paymentService.getSummary();
      summary.value = res;
      return res;
    } catch (err: any) {
      console.error(err);
    }
  }

  return {
    payments,
    currentPayment,
    summary,
    total,
    loading,
    error,
    fetchPayments,
    fetchPaymentById,
    fetchSummary,
  };
});
