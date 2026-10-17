<template>
  <div class="modems-view">
    <PageHeader
      title="Modems & Gateway Hardware"
      subtitle="Serial LTE/GSM modems, AT command ports, signal quality, and device bindings."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Modems' }]"
    >
      <template #actions>
        <v-btn
          color="primary"
          variant="tonal"
          prepend-icon="mdi-heart-pulse"
          to="/monitoring"
        >
          Live Heartbeat Monitor
        </v-btn>
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
          placeholder="Search by name, IMEI, model, device host..."
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
          style="width: 160px;"
        />
      </template>
    </FilterBar>

    <!-- Base Data Table -->
    <BaseDataTable
      :headers="headers"
      :items="modems"
      :loading="loading"
      :page="page"
      :limit="limit"
      :total="total"
      @update:page="page = $event"
      @row-click="goToDetail"
    >
      <!-- Name -->
      <template #item.name="{ item }">
        <div class="d-flex align-center ga-3">
          <v-avatar color="secondary" variant="tonal" size="36">
            <v-icon size="20">mdi-router-wireless</v-icon>
          </v-avatar>
          <div>
            <div class="font-weight-bold text-body-2 text-high-emphasis">{{ item.name }}</div>
            <div class="text-caption text-medium-emphasis">{{ item.manufacturer }} • {{ item.model }}</div>
          </div>
        </div>
      </template>

      <!-- IMEI -->
      <template #item.imei="{ item }">
        <div class="d-flex align-center ga-1">
          <span class="text-body-2 font-family-monospace font-weight-medium">{{ item.imei }}</span>
          <CopyButton :text="item.imei" />
        </div>
      </template>

      <!-- Bound Device -->
      <template #item.boundDeviceName="{ item }">
        <router-link
          :to="`/devices/${item.boundDeviceId}`"
          class="text-body-2 text-decoration-none font-weight-medium text-info"
          @click.stop
        >
          {{ item.boundDeviceName }}
        </router-link>
      </template>

      <!-- Bound SIM -->
      <template #item.boundSimPhone="{ item }">
        <router-link
          v-if="item.boundSimId"
          :to="`/sim-cards/${item.boundSimId}`"
          class="text-body-2 font-family-monospace text-decoration-none font-weight-bold"
          :class="item.boundSimOperator === 'MOBILIS' ? 'text-success' : item.boundSimOperator === 'DJEZZY' ? 'text-error' : 'text-primary'"
          @click.stop
        >
          {{ item.boundSimPhone }}
        </router-link>
        <span v-else class="text-caption text-medium-emphasis">No SIM</span>
      </template>

      <!-- Port -->
      <template #item.port="{ item }">
        <v-chip size="x-small" variant="outlined" class="font-family-monospace">
          {{ item.port }}
        </v-chip>
      </template>

      <!-- Signal & Connection -->
      <template #item.signalStrength="{ item }">
        <div class="d-flex align-center ga-2">
          <v-progress-linear
            :model-value="item.signalStrength"
            :color="item.signalStrength > 70 ? 'success' : item.signalStrength > 40 ? 'warning' : 'error'"
            height="6"
            rounded
            style="width: 50px;"
          />
          <span class="text-caption font-weight-bold">{{ item.signalStrength }}%</span>
          <v-chip size="x-small" variant="tonal" color="primary">{{ item.connectionType }}</v-chip>
        </div>
      </template>

      <!-- Status with Online Indicator -->
      <template #item.status="{ item }">
        <div class="d-flex align-center ga-2">
          <OnlineIndicator :status="item.status" />
          <StatusChip :status="item.status" />
        </div>
      </template>

      <!-- Actions -->
      <template #item.actions="{ item }">
        <div class="d-flex align-center justify-end ga-1" @click.stop>
          <v-tooltip text="View Modem Diagnostics" location="top">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon
                size="x-small"
                variant="text"
                color="primary"
                :to="`/modems/${item.id}`"
              >
                <v-icon size="18">mdi-eye-outline</v-icon>
              </v-btn>
            </template>
          </v-tooltip>
        </div>
      </template>
    </BaseDataTable>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useModemStore } from '@/stores/modem.store';
import { useExport } from '@/composables/useExport';
import { useDebounce } from '@/composables/useDebounce';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import FilterBar from '@/components/common/FilterBar.vue';
import SearchInput from '@/components/common/SearchInput.vue';
import BaseDataTable, { type TableHeader } from '@/components/common/BaseDataTable.vue';
import StatusChip from '@/components/common/StatusChip.vue';
import OnlineIndicator from '@/components/common/OnlineIndicator.vue';
import CopyButton from '@/components/common/CopyButton.vue';
import type { Modem } from '@/types';

const router = useRouter();
const modemStore = useModemStore();
const { exportToCSV } = useExport();

const { modems, total, loading } = storeToRefs(modemStore);

const search = ref('');
const debouncedSearch = useDebounce(search, 300);
const statusFilter = ref('all');
const page = ref(1);
const limit = ref(10);

const statusOptions = [
  { title: 'All Statuses', value: 'all' },
  { title: 'Online', value: 'online' },
  { title: 'Offline', value: 'offline' },
  { title: 'Blocked', value: 'blocked' },
];

const headers: TableHeader[] = [
  { title: 'Modem Name', key: 'name' },
  { title: 'IMEI', key: 'imei' },
  { title: 'Host Device', key: 'boundDeviceName' },
  { title: 'Bound SIM', key: 'boundSimPhone' },
  { title: 'Serial Port', key: 'port' },
  { title: 'Signal (LTE)', key: 'signalStrength' },
  { title: 'Status', key: 'status', align: 'center' },
  { title: 'Actions', key: 'actions', align: 'end' },
];

const loadData = () => {
  modemStore.fetchModems({
    page: page.value,
    limit: limit.value,
    search: debouncedSearch.value,
    status: statusFilter.value,
  });
};

onMounted(loadData);
watch([debouncedSearch, statusFilter, page], loadData);

const goToDetail = (item: Modem) => {
  router.push(`/modems/${item.id}`);
};

const handleExport = () => {
  exportToCSV(
    'modems_inventory',
    modems.value,
    [
      { key: 'id', label: 'Modem ID' },
      { key: 'name', label: 'Name' },
      { key: 'imei', label: 'IMEI' },
      { key: 'manufacturer', label: 'Manufacturer' },
      { key: 'model', label: 'Model' },
      { key: 'port', label: 'Port' },
      { key: 'boundDeviceName', label: 'Host Device' },
      { key: 'boundSimPhone', label: 'SIM Phone' },
      { key: 'status', label: 'Status' },
      { key: 'signalStrength', label: 'Signal %' },
    ]
  );
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
