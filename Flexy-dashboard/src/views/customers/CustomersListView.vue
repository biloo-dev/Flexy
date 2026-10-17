<template>
  <div class="customers-view">
    <PageHeader
      title="Customers Management"
      subtitle="Manage telecom resellers, retail kiosks, and enterprise accounts."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Customers' }]"
    >
      <template #actions>
        <v-btn
          color="primary"
          prepend-icon="mdi-account-plus"
          class="font-weight-bold"
          @click="showCreateDialog = true"
        >
          Add Customer
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
          placeholder="Search by name, email, phone, company..."
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

    <!-- Data Table -->
    <BaseDataTable
      :headers="headers"
      :items="customers"
      :loading="loading"
      :page="page"
      :limit="limit"
      :total="total"
      @update:page="page = $event"
      @row-click="goToDetail"
    >
      <template #item.name="{ item }">
        <div class="d-flex align-center ga-3">
          <EntityAvatar :name="item.name" size="36" />
          <div>
            <div class="font-weight-bold text-body-2 text-high-emphasis">{{ item.name }}</div>
            <div class="text-caption text-medium-emphasis">{{ item.company || item.id }}</div>
          </div>
        </div>
      </template>

      <template #item.phone="{ item }">
        <span class="text-body-2 font-family-monospace">{{ item.phone }}</span>
      </template>

      <template #item.email="{ item }">
        <span class="text-body-2">{{ item.email }}</span>
      </template>

      <template #item.devicesCount="{ item }">
        <v-chip size="x-small" variant="tonal" color="info">{{ item.devicesCount }}</v-chip>
      </template>

      <template #item.simsCount="{ item }">
        <v-chip size="x-small" variant="tonal" color="primary">{{ item.simsCount }}</v-chip>
      </template>

      <template #item.licensesCount="{ item }">
        <v-chip size="x-small" variant="tonal" color="success">{{ item.licensesCount }}</v-chip>
      </template>

      <template #item.operationsCount="{ item }">
        <span class="text-body-2 font-weight-medium">{{ item.operationsCount.toLocaleString() }}</span>
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
        <div class="d-flex align-center justify-end ga-1" @click.stop>
          <v-tooltip text="View Profile" location="top">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon
                size="x-small"
                variant="text"
                color="primary"
                :to="`/customers/${item.id}`"
              >
                <v-icon size="18">mdi-eye-outline</v-icon>
              </v-btn>
            </template>
          </v-tooltip>

          <!-- Status Actions Menu -->
          <v-menu location="bottom end">
            <template #activator="{ props }">
              <v-btn v-bind="props" icon size="x-small" variant="text" color="secondary">
                <v-icon size="18">mdi-dots-vertical</v-icon>
              </v-btn>
            </template>

            <v-list density="compact" nav>
              <v-list-item
                v-if="item.status !== 'active'"
                prepend-icon="mdi-check-circle"
                title="Activate Account"
                @click="changeStatus(item.id, 'active')"
              />
              <v-list-item
                v-if="item.status !== 'suspended'"
                prepend-icon="mdi-pause-circle"
                title="Suspend Account"
                @click="changeStatus(item.id, 'suspended')"
              />
              <v-list-item
                v-if="item.status !== 'blocked'"
                prepend-icon="mdi-block-helper"
                title="Block Account"
                color="error"
                @click="changeStatus(item.id, 'blocked')"
              />
              <v-divider class="my-1" />
              <v-list-item
                prepend-icon="mdi-delete"
                title="Delete Account"
                color="error"
                @click="openDeleteDialog(item)"
              />
            </v-list>
          </v-menu>
        </div>
      </template>
    </BaseDataTable>

    <!-- Create Customer Dialog -->
    <v-dialog v-model="showCreateDialog" max-width="540">
      <v-card class="pa-5">
        <h3 class="text-h6 font-weight-bold mb-4">Add New Customer</h3>
        <v-form @submit.prevent="handleCreate">
          <v-text-field
            v-model="newCustomer.name"
            label="Full Name / Representative"
            required
            class="mb-3"
          />
          <v-text-field
            v-model="newCustomer.company"
            label="Company / Reseller Business Name"
            class="mb-3"
          />
          <v-text-field
            v-model="newCustomer.email"
            label="Email Address"
            type="email"
            required
            class="mb-3"
          />
          <v-text-field
            v-model="newCustomer.phone"
            label="Phone Number"
            placeholder="+213 550 00 00 00"
            required
            class="mb-3"
          />
          <v-text-field
            v-model="newCustomer.address"
            label="Address / Region"
            placeholder="Alger, Algérie"
            class="mb-4"
          />

          <v-card-actions class="px-0 pt-2 d-flex justify-end ga-2">
            <v-btn variant="outlined" @click="showCreateDialog = false">Cancel</v-btn>
            <v-btn color="primary" type="submit" :loading="creating">Save Customer</v-btn>
          </v-card-actions>
        </v-form>
      </v-card>
    </v-dialog>

    <!-- Delete Confirmation Dialog -->
    <ConfirmDialog
      v-model="showDeleteDialog"
      title="Delete Customer Account"
      :message="`Are you sure you want to delete ${customerToDelete?.name}? This action cannot be undone.`"
      confirm-text="Delete Customer"
      color="error"
      icon="mdi-delete-alert"
      :loading="deleting"
      @confirm="confirmDelete"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
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
import EntityAvatar from '@/components/common/EntityAvatar.vue';
import ConfirmDialog from '@/components/common/ConfirmDialog.vue';
import type { Customer } from '@/types';

const router = useRouter();
const customerStore = useCustomerStore();
const notificationStore = useNotificationStore();
const { exportToCSV } = useExport();

const { customers, total, loading } = storeToRefs(customerStore);

const search = ref('');
const debouncedSearch = useDebounce(search, 300);
const statusFilter = ref('all');
const page = ref(1);
const limit = ref(10);

const showCreateDialog = ref(false);
const creating = ref(false);
const newCustomer = ref({
  name: '',
  company: '',
  email: '',
  phone: '',
  address: '',
});

const showDeleteDialog = ref(false);
const customerToDelete = ref<Customer | null>(null);
const deleting = ref(false);

const statusOptions = [
  { title: 'All Statuses', value: 'all' },
  { title: 'Active', value: 'active' },
  { title: 'Suspended', value: 'suspended' },
  { title: 'Blocked', value: 'blocked' },
];

const headers: TableHeader[] = [
  { title: 'Customer', key: 'name' },
  { title: 'Phone', key: 'phone' },
  { title: 'Email', key: 'email' },
  { title: 'Devices', key: 'devicesCount', align: 'center' },
  { title: 'SIMs', key: 'simsCount', align: 'center' },
  { title: 'Licenses', key: 'licensesCount', align: 'center' },
  { title: 'Operations', key: 'operationsCount', align: 'end' },
  { title: 'Status', key: 'status', align: 'center' },
  { title: 'Created', key: 'createdAt' },
  { title: 'Actions', key: 'actions', align: 'end' },
];

const loadData = () => {
  customerStore.fetchCustomers({
    page: page.value,
    limit: limit.value,
    search: debouncedSearch.value,
    status: statusFilter.value,
  });
};

onMounted(loadData);
watch([debouncedSearch, statusFilter, page], loadData);

const goToDetail = (item: Customer) => {
  router.push(`/customers/${item.id}`);
};

const changeStatus = async (id: string, status: 'active' | 'suspended' | 'blocked') => {
  await customerStore.updateStatus(id, status);
  notificationStore.showMessage(`Customer status updated to ${status}`, 'success');
};

const handleCreate = async () => {
  creating.value = true;
  try {
    await customerStore.createCustomer(newCustomer.value);
    notificationStore.showMessage('Customer created successfully', 'success');
    showCreateDialog.value = false;
    newCustomer.value = { name: '', company: '', email: '', phone: '', address: '' };
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to create customer', 'error');
  } finally {
    creating.value = false;
  }
};

const openDeleteDialog = (item: Customer) => {
  customerToDelete.value = item;
  showDeleteDialog.value = true;
};

const confirmDelete = async () => {
  if (!customerToDelete.value) return;
  deleting.value = true;
  try {
    await customerStore.deleteCustomer(customerToDelete.value.id);
    notificationStore.showMessage('Customer deleted successfully', 'success');
    showDeleteDialog.value = false;
  } catch (err: any) {
    notificationStore.showMessage('Failed to delete customer', 'error');
  } finally {
    deleting.value = false;
  }
};

const handleExport = () => {
  exportToCSV(
    'customers_export',
    customers.value,
    [
      { key: 'id', label: 'Customer ID' },
      { key: 'name', label: 'Name' },
      { key: 'company', label: 'Company' },
      { key: 'phone', label: 'Phone' },
      { key: 'email', label: 'Email' },
      { key: 'devicesCount', label: 'Devices' },
      { key: 'simsCount', label: 'SIM Cards' },
      { key: 'licensesCount', label: 'Licenses' },
      { key: 'operationsCount', label: 'Total Operations' },
      { key: 'status', label: 'Status' },
      { key: 'createdAt', label: 'Registered At' },
    ]
  );
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
