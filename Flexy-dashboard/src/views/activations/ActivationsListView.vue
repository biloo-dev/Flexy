<template>
  <div class="activations-view">
    <PageHeader
      title="License Activations Registry"
      subtitle="Cryptographic verification logs, hardware signature checks, and activation diagnostics."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Activations' }]"
    />

    <!-- Filter Bar -->
    <FilterBar
      @export="handleExport"
      @refresh="loadData"
    >
      <template #search>
        <SearchInput
          v-model="search"
          placeholder="Search by license serial, SIM, device, failure reason..."
          style="width: 340px;"
        />
      </template>

      <template #filters>
        <v-select
          v-model="resultFilter"
          :items="resultOptions"
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
      :items="activations"
      :loading="loading"
      :page="page"
      :limit="limit"
      :total="total"
      @update:page="page = $event"
    >
      <!-- License ID & Masked Serial -->
      <template #item.licenseId="{ item }">
        <div>
          <router-link
            :to="`/licenses/${item.licenseId}`"
            class="text-body-2 font-family-monospace font-weight-bold text-decoration-none text-primary"
          >
            {{ item.licenseId }}
          </router-link>
          <div class="text-caption font-family-monospace text-medium-emphasis">{{ item.licenseSerial }}</div>
        </div>
      </template>

      <!-- SIM Phone -->
      <template #item.simPhone="{ item }">
        <router-link
          :to="`/sim-cards/${item.simId}`"
          class="text-body-2 font-family-monospace text-decoration-none font-weight-bold text-info"
        >
          {{ item.simPhone }}
        </router-link>
      </template>

      <!-- Device Host -->
      <template #item.deviceName="{ item }">
        <router-link
          :to="`/devices/${item.deviceId}`"
          class="text-body-2 text-decoration-none text-high-emphasis"
        >
          {{ item.deviceName }}
        </router-link>
      </template>

      <!-- Verification Matrix (ICCID, Operator, Device, Signature) -->
      <template #item.verifications="{ item }">
        <div class="d-flex align-center ga-1">
          <!-- ICCID -->
          <v-tooltip text="ICCID Check" location="top">
            <template #activator="{ props }">
              <v-chip v-bind="props" size="x-small" :color="item.iccidVerified ? 'success' : 'error'" variant="tonal">
                ICCID {{ item.iccidVerified ? '✓' : '✗' }}
              </v-chip>
            </template>
          </v-tooltip>

          <!-- Operator -->
          <v-tooltip text="Operator Check" location="top">
            <template #activator="{ props }">
              <v-chip v-bind="props" size="x-small" :color="item.operatorVerified ? 'success' : 'error'" variant="tonal">
                OP {{ item.operatorVerified ? '✓' : '✗' }}
              </v-chip>
            </template>
          </v-tooltip>

          <!-- Device -->
          <v-tooltip text="Device Fingerprint Check" location="top">
            <template #activator="{ props }">
              <v-chip v-bind="props" size="x-small" :color="item.deviceVerified ? 'success' : 'error'" variant="tonal">
                DVC {{ item.deviceVerified ? '✓' : '✗' }}
              </v-chip>
            </template>
          </v-tooltip>

          <!-- Signature -->
          <v-tooltip text="Ed25519 Signature" location="top">
            <template #activator="{ props }">
              <v-chip v-bind="props" size="x-small" :color="item.signatureVerified ? 'success' : 'error'" variant="tonal">
                SIGN {{ item.signatureVerified ? '✓' : '✗' }}
              </v-chip>
            </template>
          </v-tooltip>
        </div>
      </template>

      <!-- Result & Failure Reason -->
      <template #item.result="{ item }">
        <div>
          <StatusChip :status="item.result" />
          <div v-if="item.failureReason" class="text-caption font-weight-bold text-error mt-1">
            {{ item.failureReason }}
          </div>
        </div>
      </template>

      <!-- Timestamp & Client IP -->
      <template #item.timestamp="{ item }">
        <div class="text-caption">
          <div>{{ new Date(item.timestamp).toLocaleString() }}</div>
          <div class="text-medium-emphasis font-family-monospace">IP: {{ item.clientIp }}</div>
        </div>
      </template>
    </BaseDataTable>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import { useActivationStore } from '@/stores/activation.store';
import { useExport } from '@/composables/useExport';
import { useDebounce } from '@/composables/useDebounce';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import FilterBar from '@/components/common/FilterBar.vue';
import SearchInput from '@/components/common/SearchInput.vue';
import BaseDataTable, { type TableHeader } from '@/components/common/BaseDataTable.vue';
import StatusChip from '@/components/common/StatusChip.vue';

const activationStore = useActivationStore();
const { exportToCSV } = useExport();

const { activations, total, loading } = storeToRefs(activationStore);

const search = ref('');
const debouncedSearch = useDebounce(search, 300);
const resultFilter = ref('all');
const page = ref(1);
const limit = ref(10);

const resultOptions = [
  { title: 'All Results', value: 'all' },
  { title: 'Success', value: 'success' },
  { title: 'Failed', value: 'failed' },
];

const headers: TableHeader[] = [
  { title: 'License & Serial', key: 'licenseId' },
  { title: 'Bound SIM', key: 'simPhone' },
  { title: 'Device Host', key: 'deviceName' },
  { title: 'Verification Matrix', key: 'verifications' },
  { title: 'Result / Diagnostics', key: 'result', align: 'center' },
  { title: 'Timestamp & IP', key: 'timestamp', align: 'end' },
];

const loadData = () => {
  activationStore.fetchActivations({
    page: page.value,
    limit: limit.value,
    search: debouncedSearch.value,
    result: resultFilter.value,
  });
};

onMounted(loadData);
watch([debouncedSearch, resultFilter, page], loadData);

const handleExport = () => {
  exportToCSV(
    'activations_log',
    activations.value,
    [
      { key: 'id', label: 'Activation ID' },
      { key: 'licenseId', label: 'License ID' },
      { key: 'customerName', label: 'Customer' },
      { key: 'simPhone', label: 'SIM' },
      { key: 'deviceName', label: 'Device' },
      { key: 'result', label: 'Result' },
      { key: 'failureReason', label: 'Failure Reason' },
      { key: 'clientIp', label: 'Client IP' },
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
