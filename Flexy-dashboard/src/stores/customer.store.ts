import { defineStore } from 'pinia';
import { ref } from 'vue';
import { customerService } from '@/api/services/customer.service';
import type { Customer, PaginatedResponse, PaginationParams } from '@/types';

export const useCustomerStore = defineStore('customer', () => {
  const customers = ref<Customer[]>([]);
  const currentCustomer = ref<Customer | null>(null);
  const total = ref<number>(0);
  const loading = ref<boolean>(false);
  const error = ref<string | null>(null);

  async function fetchCustomers(params?: PaginationParams & { status?: string }) {
    loading.value = true;
    error.value = null;
    try {
      const res: PaginatedResponse<Customer> = await customerService.getCustomers(params);
      customers.value = res.data;
      total.value = res.total;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch customers';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchCustomerById(id: string) {
    loading.value = true;
    error.value = null;
    try {
      const res = await customerService.getCustomerById(id);
      currentCustomer.value = res;
      return res;
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch customer details';
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function updateStatus(id: string, status: 'active' | 'suspended' | 'blocked') {
    const updated = await customerService.updateStatus(id, status);
    const index = customers.value.findIndex((c) => c.id === id);
    if (index !== -1) customers.value[index] = updated;
    if (currentCustomer.value?.id === id) currentCustomer.value = updated;
    return updated;
  }

  async function createCustomer(data: Partial<Customer>) {
    const created = await customerService.createCustomer(data);
    customers.value.unshift(created);
    total.value += 1;
    return created;
  }

  async function deleteCustomer(id: string) {
    const success = await customerService.deleteCustomer(id);
    if (success) {
      customers.value = customers.value.filter((c) => c.id !== id);
      total.value -= 1;
    }
    return success;
  }

  return {
    customers,
    currentCustomer,
    total,
    loading,
    error,
    fetchCustomers,
    fetchCustomerById,
    updateStatus,
    createCustomer,
    deleteCustomer,
  };
});
