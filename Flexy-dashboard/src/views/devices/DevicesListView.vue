<template>
  <div class="devices-view">
    <PageHeader
      title="Devices & Physical Gateways"
      subtitle="Authorized edge hardware gateways running the FLEXI embedded daemon."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Devices' }]"
    >
      <template #actions>
        <v-btn
          color="primary"
          prepend-icon="mdi-plus"
          class="me-2"
          @click="showRegisterModal = true"
        >
          Register Device
        </v-btn>
        <v-btn
          color="secondary"
          variant="tonal"
          prepend-icon="mdi-heart-pulse"
          to="/monitoring"
        >
          Telemetry Monitor
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
          placeholder="Search by device name, UUID, IP, customer..."
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
      :items="devices"
      :loading="loading"
      :page="page"
      :limit="limit"
      :total="total"
      @update:page="page = $event"
      @row-click="goToDetail"
    >
      <!-- Device ID & Name -->
      <template #item.name="{ item }">
        <div class="d-flex align-center ga-3">
          <v-avatar color="info" variant="tonal" size="36">
            <v-icon size="20">mdi-laptop</v-icon>
          </v-avatar>
          <div>
            <div class="font-weight-bold text-body-2 text-high-emphasis">{{ item.name }}</div>
            <div class="text-caption font-family-monospace text-medium-emphasis">{{ item.id }} • {{ item.ipAddress }}</div>
          </div>
        </div>
      </template>

      <!-- Customer -->
      <template #item.customerName="{ item }">
        <router-link
          :to="`/customers/${item.customerId}`"
          class="text-body-2 text-decoration-none font-weight-medium text-primary"
          @click.stop
        >
          {{ item.customerName }}
        </router-link>
      </template>

      <!-- Modems Count -->
      <template #item.modemsCount="{ item }">
        <v-chip size="x-small" variant="tonal" color="secondary">{{ item.modemsCount }} Ports</v-chip>
      </template>

      <!-- SIMs Count -->
      <template #item.simsCount="{ item }">
        <v-chip size="x-small" variant="tonal" color="primary">{{ item.simsCount }} SIMs</v-chip>
      </template>

      <!-- App Version -->
      <template #item.appVersion="{ item }">
        <v-chip size="x-small" variant="outlined" class="font-family-monospace">{{ item.appVersion }}</v-chip>
      </template>

      <!-- Last Heartbeat -->
      <template #item.lastSeen="{ item }">
        <span class="text-caption font-weight-medium" :class="item.status === 'online' ? 'text-success' : 'text-error'">
          {{ item.lastSeen }}
        </span>
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
          <v-tooltip text="View Device Console" location="top">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon
                size="x-small"
                variant="text"
                color="primary"
                :to="`/devices/${item.id}`"
              >
                <v-icon size="18">mdi-eye-outline</v-icon>
              </v-btn>
            </template>
          </v-tooltip>
        </div>
      </template>
    </BaseDataTable>

    <!-- Register Device Dialog -->
    <v-dialog v-model="showRegisterModal" max-width="560">
      <v-card class="pa-4">
        <v-card-title class="d-flex align-center ga-2 px-0 pt-0">
          <v-icon color="primary">mdi-laptop-plus</v-icon>
          <span class="font-weight-bold text-h6">Register Physical Device</span>
        </v-card-title>
        <v-card-subtitle class="px-0 text-caption text-medium-emphasis">
          Registers edge PC UUID and hardware fingerprint linked to an active customer.
        </v-card-subtitle>

        <v-form @submit.prevent="handleRegisterDevice" class="mt-3">
          <!-- Customer Selection -->
          <v-autocomplete
            v-model="newDevice.customerId"
            :items="customerOptions"
            item-title="name"
            item-value="id"
            label="Customer Profile *"
            variant="outlined"
            density="comfortable"
            prepend-inner-icon="mdi-account"
            required
            class="mb-3"
          />

          <!-- Device Name -->
          <v-text-field
            v-model="newDevice.name"
            label="Device Name / Location *"
            placeholder="e.g. PC Caisse 1"
            variant="outlined"
            density="comfortable"
            prepend-inner-icon="mdi-label-outline"
            required
            class="mb-3"
          />

          <!-- Device UUID -->
          <v-text-field
            v-model="newDevice.deviceUuid"
            label="Device UUID *"
            placeholder="550e8400-e29b-41d4-a716-446655440000"
            variant="outlined"
            density="comfortable"
            prepend-inner-icon="mdi-identifier"
            required
            class="mb-3 font-family-monospace"
          >
            <template #append-inner>
              <v-btn size="x-small" variant="text" color="primary" @click="generateRandomUuid">
                Generate
              </v-btn>
            </template>
          </v-text-field>

          <!-- Device Fingerprint -->
          <v-text-field
            v-model="newDevice.deviceFingerprint"
            label="Hardware Fingerprint *"
            placeholder="FP-WIN11-CPU-B48A10C"
            variant="outlined"
            density="comfortable"
            prepend-inner-icon="mdi-fingerprint"
            required
            class="mb-3 font-family-monospace"
          />

          <v-card-actions class="px-0 pt-2 d-flex justify-end ga-2">
            <v-btn variant="outlined" @click="showRegisterModal = false">Cancel</v-btn>
            <v-btn color="primary" type="submit" :loading="registering">Register Device</v-btn>
          </v-card-actions>
        </v-form>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useDeviceStore } from '@/stores/device.store';
import { useCustomerStore } from '@/stores/customer.store';
import { useNotificationStore } from '@/stores/notification.store';
import { useExport } from '@/composables/useExport';
import { useDebounce } from '@/composables/useDebounce';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import FilterBar from '@/components/common/FilterBar.vue';
import SearchInput from '@/components/common/SearchInput.vue';
import BaseDataTable, { type TableHeader } from '@/components/common/BaseDataTable.vue';
import StatusChip from '@/components/common/StatusChip.vue';
import OnlineIndicator from '@/components/common/OnlineIndicator.vue';
import type { Device } from '@/types';

const router = useRouter();
const deviceStore = useDeviceStore();
const customerStore = useCustomerStore();
const notificationStore = useNotificationStore();
const { exportToCSV } = useExport();

const { devices, total, loading } = storeToRefs(deviceStore);

const search = ref('');
const debouncedSearch = useDebounce(search, 300);
const statusFilter = ref('all');
const page = ref(1);
const limit = ref(10);

const showRegisterModal = ref(false);
const registering = ref(false);
const customerOptions = ref<{ id: string; name: string }[]>([]);

const newDevice = ref({
  customerId: '',
  deviceUuid: '550e8400-e29b-41d4-a716-446655440000',
  deviceFingerprint: 'FP-WIN11-CPU-B48A10C',
  name: 'PC Caisse 1',
});

const statusOptions = [
  { title: 'All Statuses', value: 'all' },
  { title: 'Online', value: 'online' },
  { title: 'Offline', value: 'offline' },
  { title: 'Blocked', value: 'blocked' },
];

const headers: TableHeader[] = [
  { title: 'Device Host & ID', key: 'name' },
  { title: 'Customer', key: 'customerName' },
  { title: 'Modems', key: 'modemsCount', align: 'center' },
  { title: 'SIMs Bound', key: 'simsCount', align: 'center' },
  { title: 'Daemon Version', key: 'appVersion', align: 'center' },
  { title: 'Last Seen', key: 'lastSeen' },
  { title: 'Status', key: 'status', align: 'center' },
  { title: 'Actions', key: 'actions', align: 'end' },
];

const generateRandomUuid = () => {
  newDevice.value.deviceUuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
};

const loadData = async () => {
  deviceStore.fetchDevices({
    page: page.value,
    limit: limit.value,
    search: debouncedSearch.value,
    status: statusFilter.value,
  });

  const custList = await customerStore.fetchCustomers({ page: 1, limit: 100 });
  if (custList && custList.data) {
    customerOptions.value = custList.data.map((c) => ({
      id: c.id,
      name: `${c.name} (${c.phone})`,
    }));
    if (customerOptions.value.length > 0 && !newDevice.value.customerId) {
      newDevice.value.customerId = customerOptions.value[0].id;
    }
  }
};

onMounted(loadData);
watch([debouncedSearch, statusFilter, page], loadData);

const handleRegisterDevice = async () => {
  if (!newDevice.value.customerId || !newDevice.value.deviceUuid || !newDevice.value.deviceFingerprint) {
    notificationStore.showMessage('Please fill in all required fields', 'warning');
    return;
  }

  registering.value = true;
  try {
    await deviceStore.registerDevice(newDevice.value);
    notificationStore.showMessage(`Device '${newDevice.value.name}' registered successfully!`, 'success');
    showRegisterModal.value = false;
    loadData();
  } catch (err: any) {
    notificationStore.showMessage(err.response?.data?.error?.message || err.message || 'Failed to register device', 'error');
  } finally {
    registering.value = false;
  }
};

const goToDetail = (item: Device) => {
  router.push(`/devices/${item.id}`);
};

const handleExport = () => {
  exportToCSV(
    'devices_inventory',
    devices.value,
    [
      { key: 'id', label: 'Device ID' },
      { key: 'name', label: 'Device Name' },
      { key: 'uuid', label: 'UUID' },
      { key: 'customerName', label: 'Customer' },
      { key: 'ipAddress', label: 'IP Address' },
      { key: 'appVersion', label: 'App Version' },
      { key: 'status', label: 'Status' },
      { key: 'lastSeen', label: 'Last Seen' },
    ]
  );
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
