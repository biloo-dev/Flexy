<template>
  <div class="licenses-view">
    <PageHeader
      title="Licenses & Authorizations"
      subtitle="Ed25519 digitally signed licenses, expiration lifecycle, and serial keys."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Licenses' }]"
    >
      <template #actions>
        <v-btn
          color="warning"
          variant="tonal"
          prepend-icon="mdi-clock-alert-outline"
          to="/licenses/expiring"
          class="font-weight-bold"
        >
          Expiration Center
        </v-btn>
        <v-btn
          color="primary"
          prepend-icon="mdi-plus"
          class="font-weight-bold"
          @click="openCreateModal"
        >
          Generate License
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
          placeholder="Search by license ID, serial number, customer, phone..."
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

        <v-select
          v-model="operatorFilter"
          :items="operatorOptions"
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
      :items="licenses"
      :loading="loading"
      :page="page"
      :limit="limit"
      :total="total"
      @update:page="page = $event"
      @row-click="goToDetail"
    >
      <!-- License ID & Serial -->
      <template #item.id="{ item }">
        <div class="d-flex align-center ga-2">
          <div>
            <div class="font-weight-bold text-body-2 font-family-monospace text-primary">{{ item.id }}</div>
            <div class="text-caption font-family-monospace text-medium-emphasis">{{ item.maskedSerial }}</div>
          </div>
          <v-tooltip text="Copy Serial Code" location="top">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon
                size="x-small"
                variant="tonal"
                color="primary"
                @click.stop="copySerial(item.serialNumber)"
              >
                <v-icon size="14">mdi-content-copy</v-icon>
              </v-btn>
            </template>
          </v-tooltip>
        </div>
      </template>

      <!-- Customer -->
      <template #item.customerName="{ item }">
        <router-link
          v-if="item.customerId"
          :to="`/customers/${item.customerId}`"
          class="text-body-2 text-decoration-none font-weight-medium text-high-emphasis"
          @click.stop
        >
          {{ item.customerName || item.customerId }}
        </router-link>
        <span v-else class="text-medium-emphasis">N/A</span>
      </template>

      <!-- Bound SIM & Carrier -->
      <template #item.simPhone="{ item }">
        <div>
          <div class="d-flex align-center ga-1">
            <router-link
              v-if="item.simId && item.simStatus !== 'deleted'"
              :to="`/sim-cards/${item.simId}`"
              class="text-body-2 font-family-monospace text-decoration-none font-weight-bold"
              :class="item.operator === 'MOBILIS' ? 'text-success' : item.operator === 'DJEZZY' ? 'text-error' : 'text-primary'"
              @click.stop
            >
              {{ item.simPhone && item.simPhone !== 'N/A' ? item.simPhone : `SIM (${item.simId.slice(-6)})` }}
            </router-link>
            <span v-else-if="item.simStatus === 'deleted'" class="text-caption font-weight-bold text-error">
              (SIM Supprimée 🚫)
            </span>
            <span v-else class="text-caption text-medium-emphasis">N/A</span>
          </div>
          <div class="d-flex align-center ga-1 mt-1">
            <v-chip
              size="x-small"
              :color="item.operator === 'MOBILIS' ? 'success' : item.operator === 'DJEZZY' ? 'error' : 'primary'"
              variant="tonal"
              class="font-weight-bold"
            >
              {{ item.operator || 'MOBILIS' }}
            </v-chip>
            <v-chip
              v-if="item.simStatus"
              size="x-small"
              :color="item.simStatus === 'active' ? 'success' : item.simStatus === 'deleted' ? 'error' : 'warning'"
              variant="tonal"
            >
              {{ item.simStatus === 'active' ? 'SIM Active' : item.simStatus === 'deleted' ? 'SIM Supprimée' : item.simStatus }}
            </v-chip>
          </div>
        </div>
      </template>

      <!-- Host Device -->
      <template #item.deviceName="{ item }">
        <v-chip v-if="item.deviceId === '*' || !item.deviceId" size="x-small" color="info" variant="tonal">
          All Devices (*)
        </v-chip>
        <router-link
          v-else
          :to="`/devices/${item.deviceId}`"
          class="text-body-2 text-decoration-none text-info font-family-monospace"
          @click.stop
        >
          {{ item.deviceName || item.deviceId }}
        </router-link>
      </template>

      <!-- Status -->
      <template #item.status="{ item }">
        <LicenseStatusChip :status="item.status" />
      </template>

      <!-- Expiration -->
      <template #item.expiresAt="{ item }">
        <div class="text-caption">
          <div :class="isExpiringSoon(item.expiresAt) ? 'text-warning font-weight-bold' : 'text-high-emphasis'">
            {{ formatDate(item.expiresAt) }}
          </div>
          <div class="text-medium-emphasis" style="font-size: 10px;">
            Key: {{ item.keyId || '2026-01' }} ({{ item.algorithm || 'Ed25519' }})
          </div>
        </div>
      </template>

      <!-- Payment -->
      <template #item.paymentStatus>
        <v-chip size="x-small" color="success" variant="tonal" class="font-weight-bold">
          Paid
        </v-chip>
      </template>

      <!-- Actions -->
      <template #item.actions="{ item }">
        <div class="d-flex align-center justify-end ga-1" @click.stop>
          <v-tooltip text="Copy Serial Code" location="top">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon
                size="x-small"
                variant="tonal"
                color="primary"
                @click="copySerial(item.serialNumber)"
              >
                <v-icon size="16">mdi-content-copy</v-icon>
              </v-btn>
            </template>
          </v-tooltip>

          <v-tooltip text="View License Details" location="top">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon
                size="x-small"
                variant="text"
                color="primary"
                :to="`/licenses/${item.id}`"
              >
                <v-icon size="18">mdi-eye-outline</v-icon>
              </v-btn>
            </template>
          </v-tooltip>

          <!-- Quick Context Menu for Lifecycle Management -->
          <v-menu location="bottom end">
            <template #activator="{ props }">
              <v-btn v-bind="props" icon size="x-small" variant="text" color="secondary">
                <v-icon size="18">mdi-dots-vertical</v-icon>
              </v-btn>
            </template>

            <v-list density="compact" nav>
              <v-list-item
                prepend-icon="mdi-refresh-circle"
                title="Regenerate Serial"
                @click="handleRegenerateSerial(item)"
              />
              <v-list-item
                prepend-icon="mdi-autorenew"
                title="Renew 1 Year"
                @click="handleRenew(item.id)"
              />
              <v-list-item
                v-if="item.status === 'suspended'"
                prepend-icon="mdi-play"
                title="Resume License"
                @click="handleActivate(item.id)"
              />
              <v-list-item
                v-if="item.status === 'active'"
                prepend-icon="mdi-pause"
                title="Suspend License"
                @click="handleSuspend(item.id)"
              />
              <v-divider class="my-1" />
              <v-list-item
                v-if="item.status !== 'revoked'"
                prepend-icon="mdi-shield-alert"
                title="Revoke License"
                color="warning"
                @click="openRevokeModal(item)"
              />
              <v-list-item
                prepend-icon="mdi-delete"
                title="Delete License"
                color="error"
                @click="openDeleteModal(item)"
              />
            </v-list>
          </v-menu>
        </div>
      </template>
    </BaseDataTable>

    <!-- Create License Modal -->
    <v-dialog v-model="showCreateModal" max-width="520">
      <v-card class="pa-5">
        <h3 class="text-h6 font-weight-bold mb-4 d-flex align-center ga-2">
          <v-icon color="warning">mdi-key-chain</v-icon>
          <span>Generate / Re-issue License</span>
        </h3>

        <v-alert
          v-if="selectedSimHasActiveLicense"
          type="warning"
          variant="tonal"
          density="compact"
          class="mb-3 text-caption"
          icon="mdi-information"
        >
          هذه الشريحة لديها ترخيص نشط مسبقاً. توليد ترخيص جديد سيقوم بإلغاء القديم وتوليد سيريال جديد مشفر للشريحة.
        </v-alert>

        <v-form @submit.prevent="handleCreateLicense">
          <v-select
            v-model="newLicData.customerId"
            :items="customerOptions"
            label="Customer Account *"
            required
            variant="outlined"
            density="comfortable"
            class="mb-3"
            @update:model-value="onCustomerChanged"
          />
          <v-select
            v-model="newLicData.simCardId"
            :items="availableSimOptions"
            label="Select Bound SIM Card *"
            required
            variant="outlined"
            density="comfortable"
            class="mb-3"
            no-data-text="No SIM cards registered for this customer. Please register a SIM first."
          />
          <v-select
            v-model="newLicData.validityDays"
            :items="[
              { title: '1 Year (365 Days) - Recommended', value: 365 },
              { title: '6 Months (180 Days)', value: 180 },
              { title: '3 Months (90 Days)', value: 90 },
              { title: '1 Month (30 Days)', value: 30 }
            ]"
            label="Subscription Duration *"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />
          <v-text-field
            v-model.number="newLicData.price"
            label="License Fee (DZD)"
            type="number"
            variant="outlined"
            density="comfortable"
            class="mb-4"
          />

          <v-card-actions class="px-0 pt-2 d-flex justify-end ga-2">
            <v-btn variant="outlined" @click="showCreateModal = false">Cancel</v-btn>
            <v-btn color="primary" type="submit" :loading="creating">Sign & Generate</v-btn>
          </v-card-actions>
        </v-form>
      </v-card>
    </v-dialog>

    <!-- Serial Result Dialog -->
    <v-dialog v-model="showSerialResultDialog" max-width="560" persistent>
      <v-card class="pa-5">
        <div class="d-flex align-center ga-3 mb-3">
          <v-avatar color="success" variant="tonal" size="44">
            <v-icon size="26">mdi-check-decagram</v-icon>
          </v-avatar>
          <div>
            <h3 class="text-h6 font-weight-bold">License Generated & Signed</h3>
            <p class="text-caption text-medium-emphasis mb-0">Ed25519 Asymmetric Signature Ready</p>
          </div>
        </div>

        <div class="pa-4 rounded-lg bg-surface-variant border mb-4">
          <div class="text-caption text-medium-emphasis mb-2 font-weight-bold">FULL ACTIVATION SERIAL CODE</div>
          <div class="text-body-2 font-family-monospace text-wrap pa-2 rounded bg-surface border mb-3" style="word-break: break-all; max-height: 120px; overflow-y: auto;">
            {{ generatedSerial }}
          </div>
          <div class="d-flex ga-2">
            <v-btn
              color="primary"
              variant="elevated"
              prepend-icon="mdi-content-copy"
              block
              @click="copyGeneratedSerial"
            >
              Copy Serial Code
            </v-btn>
          </div>
        </div>

        <v-card-actions class="px-0 pt-2 d-flex justify-end">
          <v-btn color="secondary" variant="tonal" @click="showSerialResultDialog = false">Done</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Danger Revoke Confirmation Dialog -->
    <DangerConfirmDialog
      v-model="showRevokeModal"
      title="Revoke Ed25519 License"
      :message="`You are revoking license ${selectedLicense?.id} for customer ${selectedLicense?.customerName}.`"
      warning-text="Warning: This will immediately prevent the associated SIM and modem from performing any Flexi operations."
      required-text="REVOKE"
      confirm-text="Revoke License Immediately"
      :loading="revoking"
      @confirm="confirmRevoke"
    />

    <!-- Danger Delete Confirmation Dialog -->
    <DangerConfirmDialog
      v-model="showDeleteModal"
      title="Delete License Permanently"
      :message="`Are you sure you want to permanently delete license ${selectedLicense?.id}?`"
      warning-text="This will completely remove this license record from the database."
      required-text="DELETE"
      confirm-text="Permanently Delete License"
      :loading="deleting"
      @confirm="confirmDelete"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useLicenseStore } from '@/stores/license.store';
import { useCustomerStore } from '@/stores/customer.store';
import { useSimStore } from '@/stores/sim.store';
import { useNotificationStore } from '@/stores/notification.store';
import { useExport } from '@/composables/useExport';
import { useDebounce } from '@/composables/useDebounce';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import FilterBar from '@/components/common/FilterBar.vue';
import SearchInput from '@/components/common/SearchInput.vue';
import BaseDataTable, { type TableHeader } from '@/components/common/BaseDataTable.vue';
import LicenseStatusChip from '@/components/common/LicenseStatusChip.vue';
import DangerConfirmDialog from '@/components/common/DangerConfirmDialog.vue';
import type { License } from '@/types';

const router = useRouter();
const licenseStore = useLicenseStore();
const customerStore = useCustomerStore();
const simStore = useSimStore();
const notificationStore = useNotificationStore();
const { exportToCSV } = useExport();

const { licenses, total, loading } = storeToRefs(licenseStore);
const { customers } = storeToRefs(customerStore);
const { simCards } = storeToRefs(simStore);

const search = ref('');
const debouncedSearch = useDebounce(search, 300);
const statusFilter = ref('all');
const operatorFilter = ref('all');
const page = ref(1);
const limit = ref(10);

const showCreateModal = ref(false);
const creating = ref(false);
const showSerialResultDialog = ref(false);
const generatedSerial = ref('');

const newLicData = ref({
  customerId: '',
  simCardId: '',
  validityDays: 365,
  price: 35000,
});

const showRevokeModal = ref(false);
const showDeleteModal = ref(false);
const selectedLicense = ref<License | null>(null);
const revoking = ref(false);
const deleting = ref(false);

const statusOptions = [
  { title: 'All Statuses', value: 'all' },
  { title: 'Active', value: 'active' },
  { title: 'Pending', value: 'pending' },
  { title: 'Expired', value: 'expired' },
  { title: 'Suspended', value: 'suspended' },
  { title: 'Revoked', value: 'revoked' },
];

const operatorOptions = [
  { title: 'All Operators', value: 'all' },
  { title: 'Mobilis (موبيليس)', value: 'MOBILIS' },
  { title: 'Djezzy (جازي)', value: 'DJEZZY' },
  { title: 'Ooredoo (أوريدو)', value: 'OOREDOO' },
];

const customerOptions = computed(() => {
  return customers.value.map((c) => ({
    title: `${c.name} (${c.phone || c.id})`,
    value: c.id,
  }));
});

const availableSimOptions = computed(() => {
  if (!newLicData.value.customerId) return [];
  return simCards.value
    .filter((s) => s.customerId === newLicData.value.customerId)
    .map((s) => ({
      title: `${s.operator} - ${s.phoneNumber} (ICCID: ${s.iccid.slice(-6)})`,
      value: s.id,
    }));
});

const selectedSimHasActiveLicense = computed(() => {
  if (!newLicData.value.simCardId) return false;
  return licenses.value.some((l) => (l.simId === newLicData.value.simCardId || l.simPhone === newLicData.value.simCardId) && l.status === 'active');
});

const onCustomerChanged = async (customerId: string) => {
  newLicData.value.simCardId = '';
  if (customerId) {
    await simStore.fetchSimCards({ customerId, page: 1, limit: 100 });
    if (availableSimOptions.value.length > 0) {
      newLicData.value.simCardId = availableSimOptions.value[0].value;
    }
  }
};

const openCreateModal = async () => {
  await customerStore.fetchCustomers({ page: 1, limit: 100 });
  if (customers.value.length > 0) {
    newLicData.value.customerId = customers.value[0].id;
    await onCustomerChanged(customers.value[0].id);
  }
  showCreateModal.value = true;
};

const headers: TableHeader[] = [
  { title: 'License ID & Serial', key: 'id' },
  { title: 'Customer', key: 'customerName' },
  { title: 'Bound SIM & Operator', key: 'simPhone' },
  { title: 'Host Device', key: 'deviceName' },
  { title: 'Status', key: 'status', align: 'center' },
  { title: 'Expires', key: 'expiresAt' },
  { title: 'Payment', key: 'paymentStatus', align: 'center' },
  { title: 'Actions', key: 'actions', align: 'end' },
];

const formatDate = (val: any) => {
  if (!val) return 'N/A';
  const d = new Date(val);
  return isNaN(d.getTime()) ? 'N/A' : d.toLocaleDateString();
};

const loadData = () => {
  licenseStore.fetchLicenses({
    page: page.value,
    limit: limit.value,
    search: debouncedSearch.value,
    status: statusFilter.value,
    operator: operatorFilter.value,
  });
};

onMounted(loadData);
watch([debouncedSearch, statusFilter, operatorFilter, page], loadData);

const goToDetail = (item: License) => {
  router.push(`/licenses/${item.id}`);
};

const isExpiringSoon = (expiresAt: string) => {
  if (!expiresAt) return false;
  const d = new Date(expiresAt).getTime();
  if (isNaN(d)) return false;
  const diff = (d - Date.now()) / (1000 * 3600 * 24);
  return diff <= 30 && diff > 0;
};

const copySerial = (serial?: string) => {
  if (!serial) {
    notificationStore.showMessage('No serial code available', 'warning');
    return;
  }
  navigator.clipboard.writeText(serial.trim());
  notificationStore.showMessage('License serial copied to clipboard!', 'success');
};

const copyGeneratedSerial = () => {
  if (!generatedSerial.value) return;
  navigator.clipboard.writeText(generatedSerial.value.trim());
  notificationStore.showMessage('License serial copied to clipboard!', 'success');
};

const handleRegenerateSerial = async (lic: License) => {
  try {
    const updated = await licenseStore.regenerateSerial(lic.id, 365);
    generatedSerial.value = updated.serialNumber;
    showSerialResultDialog.value = true;
    notificationStore.showMessage('New Ed25519 serial key re-issued successfully', 'success');
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to regenerate serial', 'error');
  }
};

const handleRenew = async (id: string) => {
  await licenseStore.renewLicense(id, 12);
  notificationStore.showMessage('License renewed successfully for 12 months', 'success');
};

const handleActivate = async (id: string) => {
  await licenseStore.activateLicense(id);
  notificationStore.showMessage('License resumed', 'success');
};

const handleSuspend = async (id: string) => {
  await licenseStore.suspendLicense(id);
  notificationStore.showMessage('License suspended', 'warning');
};

const openRevokeModal = (lic: License) => {
  selectedLicense.value = lic;
  showRevokeModal.value = true;
};

const confirmRevoke = async () => {
  if (!selectedLicense.value) return;
  revoking.value = true;
  try {
    await licenseStore.revokeLicense(selectedLicense.value.id, 'Administrative revocation from Control Center');
    notificationStore.showMessage(`License ${selectedLicense.value.id} REVOKED`, 'error');
    showRevokeModal.value = false;
  } finally {
    revoking.value = false;
  }
};

const openDeleteModal = (lic: License) => {
  selectedLicense.value = lic;
  showDeleteModal.value = true;
};

const confirmDelete = async () => {
  if (!selectedLicense.value) return;
  deleting.value = true;
  try {
    await licenseStore.deleteLicense(selectedLicense.value.id);
    notificationStore.showMessage(`License ${selectedLicense.value.id} permanently deleted`, 'success');
    showDeleteModal.value = false;
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to delete license', 'error');
  } finally {
    deleting.value = false;
  }
};

const handleCreateLicense = async () => {
  if (!newLicData.value.simCardId) {
    notificationStore.showMessage('Please select a valid SIM card', 'error');
    return;
  }
  creating.value = true;
  try {
    const selectedSim = simCards.value.find((s) => s.id === newLicData.value.simCardId);
    const lic = await licenseStore.createLicense({
      customerId: newLicData.value.customerId,
      simId: newLicData.value.simCardId,
      operator: selectedSim ? selectedSim.operator : 'MOBILIS',
      simPhone: selectedSim ? selectedSim.phoneNumber : '',
      validityDays: newLicData.value.validityDays,
      price: newLicData.value.price,
    } as any);

    await licenseStore.fetchLicenses();
    const finalSerial = lic?.serialNumber || (lic as any)?.licenseSerial || '';
    generatedSerial.value = finalSerial;
    showCreateModal.value = false;
    showSerialResultDialog.value = true;
    notificationStore.showMessage('Ed25519 License generated and signed', 'success');
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to generate license', 'error');
  } finally {
    creating.value = false;
  }
};

const handleExport = () => {
  exportToCSV(
    'licenses_export',
    licenses.value,
    [
      { key: 'id', label: 'License ID' },
      { key: 'serialNumber', label: 'Full Serial' },
      { key: 'customerName', label: 'Customer' },
      { key: 'simPhone', label: 'SIM' },
      { key: 'operator', label: 'Operator' },
      { key: 'deviceName', label: 'Host Device' },
      { key: 'status', label: 'Status' },
      { key: 'keyId', label: 'Key Version' },
      { key: 'algorithm', label: 'Algorithm' },
      { key: 'expiresAt', label: 'Expires At' },
      { key: 'paymentStatus', label: 'Payment Status' },
    ]
  );
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
