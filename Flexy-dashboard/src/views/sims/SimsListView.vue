<template>
  <div class="sims-view">
    <PageHeader
      title="SIM Cards Management"
      subtitle="Telecom hardware SIM inventory, modem bindings, and cryptographic license associations."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'SIM Cards' }]"
    >
      <template #actions>
        <v-btn
          color="primary"
          prepend-icon="mdi-sim-alert"
          class="font-weight-bold"
          to="/licenses/expiring"
        >
          Expiring SIMs
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
          placeholder="Search by phone, ICCID last 4, customer, modem IMEI..."
          style="width: 320px;"
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

    <!-- Data Table -->
    <BaseDataTable
      :headers="headers"
      :items="simCards"
      :loading="loading"
      :page="page"
      :limit="limit"
      :total="total"
      @update:page="page = $event"
      @row-click="goToDetail"
    >
      <!-- Operator -->
      <template #item.operator="{ item }">
        <v-chip
          size="x-small"
          :color="item.operator === 'MOBILIS' ? 'success' : item.operator === 'DJEZZY' ? 'error' : 'accent'"
          variant="tonal"
          class="font-weight-bold"
        >
          {{ item.operator }}
        </v-chip>
      </template>

      <!-- Phone Number -->
      <template #item.phoneNumber="{ item }">
        <span class="text-body-2 font-weight-bold font-family-monospace text-high-emphasis">
          {{ item.phoneNumber }}
        </span>
      </template>

      <!-- ICCID (Masked by default with secure toggle) -->
      <template #item.iccid="{ item }">
        <MaskedValue :raw-value="item.iccid" />
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

      <!-- Bound Modem -->
      <template #item.boundModemImei="{ item }">
        <span v-if="item.boundModemId" class="text-caption font-family-monospace">
          {{ item.boundModemImei }}
        </span>
        <span v-else class="text-caption text-medium-emphasis">Unbound</span>
      </template>

      <!-- Bound Device -->
      <template #item.boundDeviceName="{ item }">
        <span v-if="item.boundDeviceId" class="text-body-2">
          {{ item.boundDeviceName }}
        </span>
        <span v-else class="text-caption text-medium-emphasis">Unbound</span>
      </template>

      <!-- License ID -->
      <template #item.licenseId="{ item }">
        <router-link
          v-if="item.licenseId"
          :to="`/licenses/${item.licenseId}`"
          class="text-caption font-family-monospace text-decoration-none font-weight-bold text-info"
          @click.stop
        >
          {{ item.licenseId }}
        </router-link>
        <span v-else class="text-caption text-medium-emphasis">None</span>
      </template>

      <!-- Status -->
      <template #item.status="{ item }">
        <SimStatusChip :status="item.status" />
      </template>

      <!-- Activation / Expiration -->
      <template #item.expiresAt="{ item }">
        <div class="text-caption">
          <span v-if="item.expiresAt" :class="isExpiringSoon(item.expiresAt) ? 'text-warning font-weight-bold' : 'text-medium-emphasis'">
            {{ new Date(item.expiresAt).toLocaleDateString() }}
          </span>
          <span v-else class="text-medium-emphasis">N/A</span>
        </div>
      </template>

      <!-- Actions -->
      <template #item.actions="{ item }">
        <div class="d-flex align-center justify-end ga-1" @click.stop>
          <v-tooltip text="Détails de la SIM" location="top">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon
                size="x-small"
                variant="text"
                color="primary"
                :to="`/sim-cards/${item.id}`"
              >
                <v-icon size="18">mdi-eye-outline</v-icon>
              </v-btn>
            </template>
          </v-tooltip>

          <!-- Transfer Customer Action -->
          <v-tooltip text="Changer de client (Transférer)" location="top">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon
                size="x-small"
                variant="text"
                color="info"
                @click="openTransferModal(item)"
              >
                <v-icon size="18">mdi-account-switch</v-icon>
              </v-btn>
            </template>
          </v-tooltip>

          <!-- Status toggle action -->
          <v-btn
            v-if="item.status === 'blocked'"
            size="x-small"
            variant="tonal"
            color="success"
            @click="handleActivate(item.id)"
          >
            Unblock
          </v-btn>
          <v-btn
            v-else-if="item.status === 'active'"
            size="x-small"
            variant="tonal"
            color="error"
            @click="openBlockModal(item)"
          >
            Block
          </v-btn>

          <!-- Delete Action -->
          <v-tooltip text="Supprimer la SIM" location="top">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon
                size="x-small"
                variant="text"
                color="error"
                @click="openDeleteModal(item)"
              >
                <v-icon size="18">mdi-delete-outline</v-icon>
              </v-btn>
            </template>
          </v-tooltip>
        </div>
      </template>
    </BaseDataTable>

    <!-- Danger Block Confirmation Dialog -->
    <DangerConfirmDialog
      v-model="showBlockModal"
      title="Block SIM Card"
      :message="`Are you sure you want to block SIM ${selectedSim?.phoneNumber} (${selectedSim?.operator})?`"
      warning-text="This SIM will no longer be authorized to execute any Flexi operations or USSD transactions."
      confirm-text="Confirm SIM Block"
      :loading="blocking"
      @confirm="confirmBlock"
    />

    <!-- Danger Delete Confirmation Dialog -->
    <DangerConfirmDialog
      v-model="showDeleteModal"
      title="Supprimer la carte SIM"
      :message="`Êtes-vous sûr de vouloir supprimer définitivement la carte SIM ${selectedSim?.phoneNumber} (${selectedSim?.operator}) ?`"
      warning-text="Cette action supprimera également toutes les licences et liaisons associées à cette puce."
      confirm-text="Confirmer la Suppression"
      :loading="deleting"
      @confirm="confirmDelete"
    />

    <!-- Transfer Customer Dialog -->
    <v-dialog v-model="showTransferModal" max-width="500" persistent>
      <v-card class="border">
        <v-card-item class="border-b py-3 bg-surface-variant">
          <template #prepend>
            <v-avatar color="info" variant="tonal" size="36">
              <v-icon icon="mdi-account-switch" size="20" />
            </v-avatar>
          </template>
          <v-card-title class="text-subtitle-1 font-weight-bold">
            Changer le Client Propriétaire de la SIM
          </v-card-title>
        </v-card-item>

        <v-card-text class="pa-4" v-if="selectedSim">
          <v-alert
            type="warning"
            variant="tonal"
            density="compact"
            class="mb-4"
            icon="mdi-shield-alert-outline"
          >
            <div class="text-caption">
              Transférer la puce <strong>{{ selectedSim.phoneNumber }}</strong> va révoquer ses licences précédentes (client actuel : <strong>{{ selectedSim.customerName }}</strong>) et la rattacher au nouveau client.
            </div>
          </v-alert>

          <div class="text-caption text-medium-emphasis mb-2">Sélectionnez le nouveau client :</div>
          <v-select
            v-model="selectedNewCustomerId"
            :items="customerOptions"
            item-title="title"
            item-value="id"
            label="Nouveau Client *"
            placeholder="Choisir un client..."
            variant="outlined"
            density="comfortable"
            prepend-inner-icon="mdi-account-outline"
            :loading="customerStore.loading"
          />
        </v-card-text>

        <v-card-actions class="border-t pa-3 justify-end">
          <v-btn variant="plain" :disabled="transferring" @click="showTransferModal = false">
            Annuler
          </v-btn>
          <v-btn
            color="info"
            variant="flat"
            prepend-icon="mdi-check-bold"
            :loading="transferring"
            :disabled="!selectedNewCustomerId || selectedNewCustomerId === selectedSim?.customerId"
            @click="confirmTransfer"
          >
            Confirmer le Transfert
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useSimStore } from '@/stores/sim.store';
import { useCustomerStore } from '@/stores/customer.store';
import { useNotificationStore } from '@/stores/notification.store';
import { useExport } from '@/composables/useExport';
import { useDebounce } from '@/composables/useDebounce';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import FilterBar from '@/components/common/FilterBar.vue';
import SearchInput from '@/components/common/SearchInput.vue';
import BaseDataTable, { type TableHeader } from '@/components/common/BaseDataTable.vue';
import SimStatusChip from '@/components/common/SimStatusChip.vue';
import MaskedValue from '@/components/common/MaskedValue.vue';
import DangerConfirmDialog from '@/components/common/DangerConfirmDialog.vue';
import type { SimCard } from '@/types';

const router = useRouter();
const simStore = useSimStore();
const customerStore = useCustomerStore();
const notificationStore = useNotificationStore();
const { exportToCSV } = useExport();

const { simCards, total, loading } = storeToRefs(simStore);

const search = ref('');
const debouncedSearch = useDebounce(search, 300);
const operatorFilter = ref('all');
const statusFilter = ref('all');
const page = ref(1);
const limit = ref(10);

const showBlockModal = ref(false);
const selectedSim = ref<SimCard | null>(null);
const blocking = ref(false);

const showDeleteModal = ref(false);
const deleting = ref(false);

const showTransferModal = ref(false);
const transferring = ref(false);
const selectedNewCustomerId = ref<string | null>(null);

const customerOptions = computed(() => {
  return customerStore.customers.map((c) => ({
    id: c.id,
    title: `${c.name} (${c.company || c.phone || c.id})`,
  }));
});

const operatorOptions = [
  { title: 'All Operators', value: 'all' },
  { title: 'Djezzy', value: 'DJEZZY' },
  { title: 'Mobilis', value: 'MOBILIS' },
  { title: 'Ooredoo', value: 'OOREDOO' },
];

const statusOptions = [
  { title: 'All Statuses', value: 'all' },
  { title: 'Active', value: 'active' },
  { title: 'Blocked', value: 'blocked' },
  { title: 'Suspended', value: 'suspended' },
  { title: 'Expired', value: 'expired' },
  { title: 'Pending', value: 'pending' },
];

const headers: TableHeader[] = [
  { title: 'Operator', key: 'operator', width: '100px' },
  { title: 'Phone Number', key: 'phoneNumber' },
  { title: 'ICCID (Masked)', key: 'iccid' },
  { title: 'Customer', key: 'customerName' },
  { title: 'Bound Modem', key: 'boundModemImei' },
  { title: 'Device', key: 'boundDeviceName' },
  { title: 'License', key: 'licenseId' },
  { title: 'Status', key: 'status', align: 'center' },
  { title: 'Expires', key: 'expiresAt' },
  { title: 'Actions', key: 'actions', align: 'end' },
];

const loadData = () => {
  simStore.fetchSimCards({
    page: page.value,
    limit: limit.value,
    search: debouncedSearch.value,
    operator: operatorFilter.value,
    status: statusFilter.value,
  });
};

onMounted(() => {
  loadData();
  customerStore.fetchCustomers();
});
watch([debouncedSearch, operatorFilter, statusFilter, page], loadData);

const goToDetail = (item: SimCard) => {
  router.push(`/sim-cards/${item.id}`);
};

const isExpiringSoon = (expiresAt: string) => {
  const diffDays = (new Date(expiresAt).getTime() - Date.now()) / (1000 * 3600 * 24);
  return diffDays <= 30 && diffDays > 0;
};

const openBlockModal = (sim: SimCard) => {
  selectedSim.value = sim;
  showBlockModal.value = true;
};

const confirmBlock = async () => {
  if (!selectedSim.value) return;
  blocking.value = true;
  try {
    await simStore.blockSim(selectedSim.value.id);
    notificationStore.showMessage(`SIM ${selectedSim.value.phoneNumber} has been blocked`, 'warning');
    showBlockModal.value = false;
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to block SIM', 'error');
  } finally {
    blocking.value = false;
  }
};

const openDeleteModal = (sim: SimCard) => {
  selectedSim.value = sim;
  showDeleteModal.value = true;
};

const confirmDelete = async () => {
  if (!selectedSim.value) return;
  deleting.value = true;
  try {
    await simStore.deleteSim(selectedSim.value.id);
    notificationStore.showMessage(`Carte SIM ${selectedSim.value.phoneNumber} supprimée avec succès!`, 'success');
    showDeleteModal.value = false;
    loadData();
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Échec de la suppression de la carte SIM', 'error');
  } finally {
    deleting.value = false;
  }
};

const openTransferModal = async (sim: SimCard) => {
  selectedSim.value = sim;
  selectedNewCustomerId.value = null;
  await customerStore.fetchCustomers();
  showTransferModal.value = true;
};

const confirmTransfer = async () => {
  if (!selectedSim.value || !selectedNewCustomerId.value) return;
  transferring.value = true;
  try {
    await simStore.transferOwnership(selectedSim.value.id, selectedNewCustomerId.value);
    notificationStore.showMessage(`SIM ${selectedSim.value.phoneNumber} transférée au nouveau client avec succès!`, 'success');
    showTransferModal.value = false;
    loadData();
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Erreur lors du transfert de la SIM', 'error');
  } finally {
    transferring.value = false;
  }
};

const handleActivate = async (id: string) => {
  await simStore.activateSim(id);
  notificationStore.showMessage('SIM reactivated successfully', 'success');
};

const handleExport = () => {
  exportToCSV(
    'sim_cards_export',
    simCards.value,
    [
      { key: 'id', label: 'SIM ID' },
      { key: 'phoneNumber', label: 'Phone Number' },
      { key: 'operator', label: 'Operator' },
      { key: 'customerId', label: 'Customer ID' },
      { key: 'customerName', label: 'Customer' },
      { key: 'boundModemImei', label: 'Modem IMEI' },
      { key: 'boundDeviceName', label: 'Bound Device' },
      { key: 'licenseId', label: 'License ID' },
      { key: 'status', label: 'Status' },
      { key: 'currentBalance', label: 'Balance (DZD)' },
      { key: 'expiresAt', label: 'Expires At' },
    ]
  );
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
