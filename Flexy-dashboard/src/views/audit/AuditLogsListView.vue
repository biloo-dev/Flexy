<template>
  <div class="audit-logs-view">
    <PageHeader
      title="Immutable Audit Logs"
      subtitle="Cryptographically verified administrative trail for compliance, key rotations, and SIM operations."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Audit Logs' }]"
    >
      <template #badge>
        <v-chip color="success" size="small" variant="tonal">
          <v-icon start size="14">mdi-lock-check</v-icon>
          Append-Only Log
        </v-chip>
      </template>
    </PageHeader>

    <!-- Filter Bar -->
    <FilterBar
      @export="handleExport"
      @refresh="loadData"
    >
      <template #search>
        <SearchInput
          v-model="search"
          placeholder="Search by actor, action, entity ID, IP address..."
          style="width: 340px;"
        />
      </template>

      <template #filters>
        <v-select
          v-model="entityFilter"
          :items="entityOptions"
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
      :items="logs"
      :loading="loading"
      :page="page"
      :limit="limit"
      :total="total"
      @update:page="page = $event"
    >
      <!-- Timestamp -->
      <template #item.timestamp="{ item }">
        <span class="text-caption font-family-monospace text-high-emphasis">
          {{ new Date(item.timestamp).toLocaleString() }}
        </span>
      </template>

      <!-- Actor -->
      <template #item.actorName="{ item }">
        <div>
          <div class="font-weight-bold text-body-2 text-high-emphasis">{{ item.actorName }}</div>
          <div class="text-caption text-medium-emphasis">{{ item.actorRole }} ({{ item.actorEmail }})</div>
        </div>
      </template>

      <!-- Action -->
      <template #item.action="{ item }">
        <v-chip
          :color="item.severity === 'critical' ? 'error' : item.severity === 'warning' ? 'warning' : 'primary'"
          size="small"
          variant="tonal"
          class="font-family-monospace font-weight-bold"
        >
          {{ item.action }}
        </v-chip>
      </template>

      <!-- Entity -->
      <template #item.entityType="{ item }">
        <div>
          <span class="text-body-2 font-weight-medium">{{ item.entityType }}</span>
          <div class="text-caption font-family-monospace text-medium-emphasis">{{ item.entityId }}</div>
        </div>
      </template>

      <!-- IP Address -->
      <template #item.ipAddress="{ item }">
        <span class="text-caption font-family-monospace">{{ item.ipAddress }}</span>
      </template>

      <!-- Result -->
      <template #item.result="{ item }">
        <v-chip
          :color="item.result === 'SUCCESS' ? 'success' : 'error'"
          size="x-small"
          variant="tonal"
          class="font-weight-bold"
        >
          {{ item.result }}
        </v-chip>
      </template>
    </BaseDataTable>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import { useAuditStore } from '@/stores/audit.store';
import { useExport } from '@/composables/useExport';
import { useDebounce } from '@/composables/useDebounce';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import FilterBar from '@/components/common/FilterBar.vue';
import SearchInput from '@/components/common/SearchInput.vue';
import BaseDataTable, { type TableHeader } from '@/components/common/BaseDataTable.vue';

const auditStore = useAuditStore();
const { exportToCSV } = useExport();

const { logs, total, loading } = storeToRefs(auditStore);

const search = ref('');
const debouncedSearch = useDebounce(search, 300);
const entityFilter = ref('all');
const page = ref(1);
const limit = ref(10);

const entityOptions = [
  { title: 'All Entities', value: 'all' },
  { title: 'Customer', value: 'Customer' },
  { title: 'SIM Card', value: 'SIM' },
  { title: 'License', value: 'License' },
  { title: 'Security Key', value: 'SecurityKey' },
  { title: 'Payment', value: 'Payment' },
];

const headers: TableHeader[] = [
  { title: 'Timestamp', key: 'timestamp' },
  { title: 'Admin Actor', key: 'actorName' },
  { title: 'Action Executed', key: 'action' },
  { title: 'Target Entity', key: 'entityType' },
  { title: 'Source IP', key: 'ipAddress' },
  { title: 'Result', key: 'result', align: 'center' },
];

const loadData = () => {
  auditStore.fetchAuditLogs({
    page: page.value,
    limit: limit.value,
    search: debouncedSearch.value,
    entityType: entityFilter.value,
  });
};

onMounted(loadData);
watch([debouncedSearch, entityFilter, page], loadData);

const handleExport = () => {
  exportToCSV(
    'audit_compliance_log',
    logs.value,
    [
      { key: 'id', label: 'Log ID' },
      { key: 'timestamp', label: 'Timestamp' },
      { key: 'actorName', label: 'Actor' },
      { key: 'actorRole', label: 'Role' },
      { key: 'action', label: 'Action' },
      { key: 'entityType', label: 'Entity Type' },
      { key: 'entityId', label: 'Entity ID' },
      { key: 'ipAddress', label: 'IP' },
      { key: 'result', label: 'Result' },
    ]
  );
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
