<template>
  <div class="security-events-view">
    <PageHeader
      title="Security Threat Events Stream"
      subtitle="Comprehensive audit stream of security anomalies, unauthorized SIM swaps, and signature failures."
      :breadcrumbs="[
        { title: 'Dashboard', to: '/dashboard' },
        { title: 'Security Center', to: '/security' },
        { title: 'Security Events' }
      ]"
    />

    <!-- Filter Bar -->
    <FilterBar
      @export="handleExport"
      @refresh="loadData"
    >
      <template #search>
        <SearchInput
          v-model="search"
          placeholder="Search by event type, description, customer, IP..."
          style="width: 340px;"
        />
      </template>

      <template #filters>
        <v-select
          v-model="severityFilter"
          :items="severityOptions"
          density="compact"
          variant="outlined"
          hide-details
          style="width: 150px;"
        />

        <v-select
          v-model="resolvedFilter"
          :items="resolvedOptions"
          density="compact"
          variant="outlined"
          hide-details
          style="width: 160px;"
        />
      </template>
    </FilterBar>

    <!-- Base Data Table -->
    <BaseDataTable
      :headers="headers"
      :items="events"
      :loading="loading"
      :page="page"
      :limit="limit"
      :total="total"
      @update:page="page = $event"
    >
      <!-- Severity Badge -->
      <template #item.severity="{ item }">
        <v-chip
          :color="item.severity === 'critical' ? 'error' : item.severity === 'warning' ? 'warning' : 'info'"
          size="x-small"
          variant="tonal"
          class="font-weight-bold text-uppercase"
        >
          {{ item.severity }}
        </v-chip>
      </template>

      <!-- Event Type & Title -->
      <template #item.title="{ item }">
        <div>
          <div class="font-weight-bold text-body-2 text-high-emphasis">{{ item.title }}</div>
          <div class="text-caption font-family-monospace text-medium-emphasis">{{ item.type }}</div>
        </div>
      </template>

      <!-- Description -->
      <template #item.description="{ item }">
        <div class="text-caption text-medium-emphasis py-1" style="max-width: 420px;">
          {{ item.description }}
        </div>
      </template>

      <!-- Customer -->
      <template #item.customerName="{ item }">
        <router-link
          v-if="item.customerId"
          :to="`/customers/${item.customerId}`"
          class="text-body-2 text-decoration-none font-weight-medium text-primary"
        >
          {{ item.customerName }}
        </router-link>
        <span v-else class="text-caption text-medium-emphasis">System</span>
      </template>

      <!-- IP Address -->
      <template #item.ipAddress="{ item }">
        <span class="text-caption font-family-monospace">{{ item.ipAddress }}</span>
      </template>

      <!-- Status & Resolve Action -->
      <template #item.resolved="{ item }">
        <div class="d-flex align-center justify-end ga-2">
          <v-chip v-if="item.resolved" size="x-small" color="success" variant="tonal">Resolved</v-chip>
          <v-btn
            v-else
            size="x-small"
            variant="tonal"
            color="error"
            prepend-icon="mdi-check"
            @click="handleResolve(item.id)"
          >
            Acknowledge
          </v-btn>
        </div>
      </template>
    </BaseDataTable>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import { useSecurityStore } from '@/stores/security.store';
import { useNotificationStore } from '@/stores/notification.store';
import { useExport } from '@/composables/useExport';
import { useDebounce } from '@/composables/useDebounce';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import FilterBar from '@/components/common/FilterBar.vue';
import SearchInput from '@/components/common/SearchInput.vue';
import BaseDataTable, { type TableHeader } from '@/components/common/BaseDataTable.vue';

const securityStore = useSecurityStore();
const notificationStore = useNotificationStore();
const { exportToCSV } = useExport();

const { events, total, loading } = storeToRefs(securityStore);

const search = ref('');
const debouncedSearch = useDebounce(search, 300);
const severityFilter = ref('all');
const resolvedFilter = ref('all');
const page = ref(1);
const limit = ref(10);

const severityOptions = [
  { title: 'All Severities', value: 'all' },
  { title: 'Critical', value: 'critical' },
  { title: 'Warning', value: 'warning' },
  { title: 'Info', value: 'info' },
];

const resolvedOptions = [
  { title: 'All Statuses', value: 'all' },
  { title: 'Unresolved', value: 'false' },
  { title: 'Resolved', value: 'true' },
];

const headers: TableHeader[] = [
  { title: 'Severity', key: 'severity', width: '90px' },
  { title: 'Threat Type & Title', key: 'title' },
  { title: 'Diagnostic Description', key: 'description' },
  { title: 'Target Customer', key: 'customerName' },
  { title: 'Source IP', key: 'ipAddress' },
  { title: 'Status & Resolution', key: 'resolved', align: 'end' },
];

const loadData = () => {
  securityStore.fetchSecurityEvents({
    page: page.value,
    limit: limit.value,
    search: debouncedSearch.value,
    severity: severityFilter.value,
    resolved: resolvedFilter.value,
  });
};

onMounted(loadData);
watch([debouncedSearch, severityFilter, resolvedFilter, page], loadData);

const handleResolve = async (id: string) => {
  await securityStore.resolveEvent(id);
  notificationStore.showMessage('Security event acknowledged and marked resolved', 'success');
};

const handleExport = () => {
  exportToCSV(
    'security_events_report',
    events.value,
    [
      { key: 'id', label: 'Event ID' },
      { key: 'type', label: 'Threat Type' },
      { key: 'title', label: 'Title' },
      { key: 'description', label: 'Description' },
      { key: 'severity', label: 'Severity' },
      { key: 'customerName', label: 'Customer' },
      { key: 'ipAddress', label: 'IP Address' },
      { key: 'resolved', label: 'Resolved' },
      { key: 'timestamp', label: 'Timestamp' },
    ]
  );
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
