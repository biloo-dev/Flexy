<template>
  <div class="payments-view">
    <PageHeader
      title="Payments & Invoicing"
      subtitle="Financial transactions, license fees, CIB/Edahabia e-payments, and bank settlements."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Payments' }]"
    />

    <!-- Revenue KPIs -->
    <v-row class="mb-4">
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Total Settled"
          :value="summary.totalRevenue"
          unit="DZD"
          icon="mdi-cash-multiple"
          color="success"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Paid Invoices"
          :value="summary.paidCount"
          icon="mdi-check-circle"
          color="success"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Pending Settlement"
          :value="summary.pendingCount"
          icon="mdi-clock-outline"
          color="warning"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Failed Payments"
          :value="summary.failedCount"
          icon="mdi-alert-circle"
          color="error"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Refunded"
          :value="summary.refundedCount"
          icon="mdi-keyboard-return"
          color="secondary"
        />
      </v-col>
    </v-row>

    <!-- Filter Bar -->
    <FilterBar
      @export="handleExport"
      @refresh="loadData"
    >
      <template #search>
        <SearchInput
          v-model="search"
          placeholder="Search by reference, customer, license ID..."
          style="width: 320px;"
        />
      </template>

      <template #filters>
        <v-select
          v-model="statusFilter"
          :items="statusOptions"
          density="compact"
          variant="outlined"
          hide-details
          style="width: 150px;"
        />
      </template>
    </FilterBar>

    <!-- Base Data Table -->
    <BaseDataTable
      :headers="headers"
      :items="payments"
      :loading="loading"
      :page="page"
      :limit="limit"
      :total="total"
      @update:page="page = $event"
      @row-click="goToDetail"
    >
      <template #item.reference="{ item }">
        <div class="d-flex align-center ga-2">
          <v-avatar color="success" variant="tonal" size="32">
            <v-icon size="16">mdi-receipt-text-outline</v-icon>
          </v-avatar>
          <div>
            <div class="font-weight-bold text-body-2 font-family-monospace text-high-emphasis">
              {{ item.reference }}
            </div>
            <div class="text-caption text-medium-emphasis">{{ item.paymentMethod }}</div>
          </div>
        </div>
      </template>

      <template #item.customerName="{ item }">
        <router-link
          :to="`/customers/${item.customerId}`"
          class="text-body-2 text-decoration-none font-weight-medium text-primary"
          @click.stop
        >
          {{ item.customerName }}
        </router-link>
      </template>

      <template #item.licenseId="{ item }">
        <router-link
          :to="`/licenses/${item.licenseId}`"
          class="text-caption font-family-monospace text-decoration-none font-weight-bold text-info"
          @click.stop
        >
          {{ item.licenseId }}
        </router-link>
      </template>

      <template #item.amount="{ item }">
        <span class="text-body-2 font-weight-black font-family-monospace text-high-emphasis">
          {{ item.amount.toLocaleString() }} {{ item.currency }}
        </span>
      </template>

      <template #item.status="{ item }">
        <StatusChip :status="item.status" />
      </template>

      <template #item.createdAt="{ item }">
        <span class="text-caption text-medium-emphasis">
          {{ new Date(item.createdAt).toLocaleDateString() }}
        </span>
      </template>

      <template #item.actions="{ item }">
        <div class="d-flex align-center justify-end" @click.stop>
          <v-btn
            icon
            size="x-small"
            variant="text"
            color="primary"
            :to="`/payments/${item.id}`"
          >
            <v-icon size="18">mdi-eye-outline</v-icon>
          </v-btn>
        </div>
      </template>
    </BaseDataTable>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { usePaymentStore } from '@/stores/payment.store';
import { useExport } from '@/composables/useExport';
import { useDebounce } from '@/composables/useDebounce';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import MetricCard from '@/components/common/MetricCard.vue';
import FilterBar from '@/components/common/FilterBar.vue';
import SearchInput from '@/components/common/SearchInput.vue';
import BaseDataTable, { type TableHeader } from '@/components/common/BaseDataTable.vue';
import StatusChip from '@/components/common/StatusChip.vue';
import type { Payment } from '@/types';

const router = useRouter();
const paymentStore = usePaymentStore();
const { exportToCSV } = useExport();

const { payments, summary, total, loading } = storeToRefs(paymentStore);

const search = ref('');
const debouncedSearch = useDebounce(search, 300);
const statusFilter = ref('all');
const page = ref(1);
const limit = ref(10);

const statusOptions = [
  { title: 'All Statuses', value: 'all' },
  { title: 'Paid', value: 'paid' },
  { title: 'Pending', value: 'pending' },
  { title: 'Failed', value: 'failed' },
  { title: 'Refunded', value: 'refunded' },
];

const headers: TableHeader[] = [
  { title: 'Payment Reference', key: 'reference' },
  { title: 'Customer', key: 'customerName' },
  { title: 'License', key: 'licenseId' },
  { title: 'Amount', key: 'amount', align: 'end' },
  { title: 'Status', key: 'status', align: 'center' },
  { title: 'Date', key: 'createdAt' },
  { title: 'Actions', key: 'actions', align: 'end' },
];

const loadData = () => {
  paymentStore.fetchPayments({
    page: page.value,
    limit: limit.value,
    search: debouncedSearch.value,
    status: statusFilter.value,
  });
  paymentStore.fetchSummary();
};

onMounted(loadData);
watch([debouncedSearch, statusFilter, page], loadData);

const goToDetail = (item: Payment) => {
  router.push(`/payments/${item.id}`);
};

const handleExport = () => {
  exportToCSV(
    'payments_export',
    payments.value,
    [
      { key: 'id', label: 'Payment ID' },
      { key: 'reference', label: 'Reference' },
      { key: 'customerName', label: 'Customer' },
      { key: 'licenseId', label: 'License ID' },
      { key: 'amount', label: 'Amount' },
      { key: 'currency', label: 'Currency' },
      { key: 'paymentMethod', label: 'Payment Method' },
      { key: 'status', label: 'Status' },
      { key: 'createdAt', label: 'Date' },
    ]
  );
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
