<template>
  <div class="operations-view">
    <PageHeader
      title="Flexi Operations Engine"
      subtitle="High-speed transaction pipeline, carrier USSD execution logs, and idempotency checks."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Operations' }]"
    />

    <!-- Top KPIs -->
    <v-row class="mb-4">
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Total Transactions"
          :value="kpis?.totalOperations || 142930"
          icon="mdi-swap-horizontal-bold"
          color="primary"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Successful"
          :value="kpis?.successfulOperations || 141215"
          icon="mdi-check-circle"
          color="success"
          subtitle="98.8% Success Rate"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Failed Requests"
          :value="kpis?.failedOperations || 1265"
          icon="mdi-close-circle"
          color="error"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Security Blocked"
          :value="kpis?.blockedOperations || 450"
          icon="mdi-shield-lock"
          color="error"
          subtitle="ICCID / Mismatch"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Average Latency"
          value="1,380"
          unit="ms"
          icon="mdi-timer-outline"
          color="info"
          subtitle="USSD execution time"
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
          placeholder="Search by operation code, recipient phone, idempotency key..."
          style="width: 340px;"
        />
      </template>

      <template #filters>
        <!-- Operator Filter -->
        <v-select
          v-model="operatorFilter"
          :items="operatorOptions"
          density="compact"
          variant="outlined"
          hide-details
          style="width: 150px;"
        />

        <!-- Status Filter -->
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
      :items="operations"
      :loading="loading"
      :page="page"
      :limit="limit"
      :total="total"
      @update:page="page = $event"
      @row-click="goToDetail"
    >
      <!-- Operation Code -->
      <template #item.operationCode="{ item }">
        <div class="d-flex align-center ga-2">
          <v-avatar :color="item.status === 'success' ? 'success' : 'error'" variant="tonal" size="32">
            <v-icon size="16">mdi-swap-horizontal-bold</v-icon>
          </v-avatar>
          <div>
            <div class="font-weight-bold text-body-2 font-family-monospace text-high-emphasis">
              {{ item.operationCode }}
            </div>
            <div class="text-caption font-family-monospace text-medium-emphasis">{{ item.idempotencyKey }}</div>
          </div>
        </div>
      </template>

      <!-- Customer -->
      <template #item.customerName="{ item }">
        <router-link
          :to="`/customers/${item.customerId}`"
          class="text-body-2 text-decoration-none font-weight-medium text-high-emphasis"
          @click.stop
        >
          {{ item.customerName }}
        </router-link>
      </template>

      <!-- Target Phone & Operator -->
      <template #item.targetPhone="{ item }">
        <div>
          <div class="text-body-2 font-family-monospace font-weight-bold">{{ item.targetPhone }}</div>
          <v-chip
            size="x-small"
            :color="item.operator === 'MOBILIS' ? 'success' : item.operator === 'DJEZZY' ? 'error' : 'accent'"
            variant="tonal"
            class="font-weight-bold"
          >
            {{ item.operator }}
          </v-chip>
        </div>
      </template>

      <!-- SIM Card Source -->
      <template #item.simPhone="{ item }">
        <router-link
          :to="`/sim-cards/${item.simId}`"
          class="text-body-2 font-family-monospace text-decoration-none text-info"
          @click.stop
        >
          {{ item.simPhone }}
        </router-link>
      </template>

      <!-- Amount -->
      <template #item.amount="{ item }">
        <span class="text-body-2 font-weight-black font-family-monospace text-high-emphasis">
          {{ item.amount.toLocaleString() }} {{ item.currency }}
        </span>
      </template>

      <!-- Status -->
      <template #item.status="{ item }">
        <OperationStatusChip :status="item.status" />
      </template>

      <!-- Execution Duration -->
      <template #item.executionDurationMs="{ item }">
        <span class="text-caption font-family-monospace font-weight-medium">
          {{ item.executionDurationMs }}ms
        </span>
      </template>

      <!-- Timestamp -->
      <template #item.createdAt="{ item }">
        <span class="text-caption text-medium-emphasis">
          {{ new Date(item.createdAt).toLocaleTimeString() }}
        </span>
      </template>

      <!-- Actions -->
      <template #item.actions="{ item }">
        <div class="d-flex align-center justify-end" @click.stop>
          <v-btn
            icon
            size="x-small"
            variant="text"
            color="primary"
            :to="`/operations/${item.id}`"
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
import { useOperationStore } from '@/stores/operation.store';
import { useExport } from '@/composables/useExport';
import { useDebounce } from '@/composables/useDebounce';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import MetricCard from '@/components/common/MetricCard.vue';
import FilterBar from '@/components/common/FilterBar.vue';
import SearchInput from '@/components/common/SearchInput.vue';
import BaseDataTable, { type TableHeader } from '@/components/common/BaseDataTable.vue';
import OperationStatusChip from '@/components/common/OperationStatusChip.vue';
import type { FlexiOperation } from '@/types';

const router = useRouter();
const operationStore = useOperationStore();
const { exportToCSV } = useExport();

const { operations, kpis, total, loading } = storeToRefs(operationStore);

const search = ref('');
const debouncedSearch = useDebounce(search, 300);
const operatorFilter = ref('all');
const statusFilter = ref('all');
const page = ref(1);
const limit = ref(10);

const operatorOptions = [
  { title: 'All Operators', value: 'all' },
  { title: 'Djezzy', value: 'DJEZZY' },
  { title: 'Mobilis', value: 'MOBILIS' },
  { title: 'Ooredoo', value: 'OOREDOO' },
];

const statusOptions = [
  { title: 'All Statuses', value: 'all' },
  { title: 'Successful', value: 'success' },
  { title: 'Failed', value: 'failed' },
  { title: 'Blocked', value: 'blocked' },
  { title: 'Pending', value: 'pending' },
];

const headers: TableHeader[] = [
  { title: 'Operation ID / Code', key: 'operationCode' },
  { title: 'Customer', key: 'customerName' },
  { title: 'Recipient Phone', key: 'targetPhone' },
  { title: 'Source SIM', key: 'simPhone' },
  { title: 'Amount', key: 'amount', align: 'end' },
  { title: 'Status', key: 'status', align: 'center' },
  { title: 'Duration', key: 'executionDurationMs', align: 'center' },
  { title: 'Time', key: 'createdAt' },
  { title: 'Actions', key: 'actions', align: 'end' },
];

const loadData = () => {
  operationStore.fetchOperations({
    page: page.value,
    limit: limit.value,
    search: debouncedSearch.value,
    operator: operatorFilter.value,
    status: statusFilter.value,
  });
  operationStore.fetchKPIs();
};

onMounted(loadData);
watch([debouncedSearch, operatorFilter, statusFilter, page], loadData);

const goToDetail = (item: FlexiOperation) => {
  router.push(`/operations/${item.id}`);
};

const handleExport = () => {
  exportToCSV(
    'flexi_operations_log',
    operations.value,
    [
      { key: 'id', label: 'Operation ID' },
      { key: 'operationCode', label: 'Operation Code' },
      { key: 'customerName', label: 'Customer' },
      { key: 'targetPhone', label: 'Target Phone' },
      { key: 'operator', label: 'Carrier' },
      { key: 'simPhone', label: 'SIM Phone' },
      { key: 'amount', label: 'Amount (DZD)' },
      { key: 'status', label: 'Status' },
      { key: 'executionDurationMs', label: 'Duration (ms)' },
      { key: 'createdAt', label: 'Timestamp' },
    ]
  );
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
