<template>
  <div class="expiring-licenses-view">
    <PageHeader
      title="Expiration Center"
      subtitle="Prioritized monitoring of expiring cryptographic licenses to prevent SIM service disruption."
      :breadcrumbs="[
        { title: 'Dashboard', to: '/dashboard' },
        { title: 'Licenses', to: '/licenses' },
        { title: 'Expiring Licenses' }
      ]"
    />

    <!-- Priority Alerts Grid -->
    <v-row class="mb-4">
      <v-col cols="12" sm="6" md="2.4">
        <v-card class="pa-4 border border-error fill-height bg-surface">
          <div class="d-flex align-center justify-space-between mb-2">
            <span class="text-caption font-weight-bold text-error text-uppercase">Expired</span>
            <v-avatar color="error" variant="tonal" size="32"><v-icon size="18">mdi-alert-octagon</v-icon></v-avatar>
          </div>
          <div class="text-h4 font-weight-bold text-error">{{ expiringLicenses.expired.length }}</div>
          <div class="text-caption text-medium-emphasis mt-1">Immediate renewal needed</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="2.4">
        <v-card class="pa-4 border fill-height bg-surface">
          <div class="d-flex align-center justify-space-between mb-2">
            <span class="text-caption font-weight-bold text-warning text-uppercase">Expires Today</span>
            <v-avatar color="warning" variant="tonal" size="32"><v-icon size="18">mdi-clock-alert</v-icon></v-avatar>
          </div>
          <div class="text-h4 font-weight-bold text-warning">{{ expiringLicenses.today.length }}</div>
          <div class="text-caption text-medium-emphasis mt-1">Within 24 hours</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="2.4">
        <v-card class="pa-4 border fill-height bg-surface">
          <div class="d-flex align-center justify-space-between mb-2">
            <span class="text-caption font-weight-bold text-uppercase">Expires in 3 Days</span>
            <v-avatar color="warning" variant="tonal" size="32"><v-icon size="18">mdi-clock-fast</v-icon></v-avatar>
          </div>
          <div class="text-h4 font-weight-bold">{{ expiringLicenses.in3Days.length }}</div>
          <div class="text-caption text-medium-emphasis mt-1">Urgent reminder queue</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="2.4">
        <v-card class="pa-4 border fill-height bg-surface">
          <div class="d-flex align-center justify-space-between mb-2">
            <span class="text-caption font-weight-bold text-uppercase">Expires in 7 Days</span>
            <v-avatar color="info" variant="tonal" size="32"><v-icon size="18">mdi-calendar-week</v-icon></v-avatar>
          </div>
          <div class="text-h4 font-weight-bold">{{ expiringLicenses.in7Days.length }}</div>
          <div class="text-caption text-medium-emphasis mt-1">Weekly renewal cohort</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="2.4">
        <v-card class="pa-4 border fill-height bg-surface">
          <div class="d-flex align-center justify-space-between mb-2">
            <span class="text-caption font-weight-bold text-uppercase">Expires in 30 Days</span>
            <v-avatar color="primary" variant="tonal" size="32"><v-icon size="18">mdi-calendar-month</v-icon></v-avatar>
          </div>
          <div class="text-h4 font-weight-bold">{{ expiringLicenses.in30Days.length }}</div>
          <div class="text-caption text-medium-emphasis mt-1">Monthly cycle</div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Expiring Licenses Grouped Table -->
    <v-card class="border pa-4">
      <div class="d-flex align-center justify-space-between mb-4">
        <h3 class="text-subtitle-1 font-weight-bold">At-Risk Licenses List</h3>
        <v-btn-toggle v-model="selectedCategory" mandatory density="compact" variant="outlined" color="primary">
          <v-btn value="all" size="x-small">All Expiring</v-btn>
          <v-btn value="expired" size="x-small">Expired</v-btn>
          <v-btn value="today" size="x-small">Today</v-btn>
          <v-btn value="3days" size="x-small">3 Days</v-btn>
          <v-btn value="30days" size="x-small">30 Days</v-btn>
        </v-btn-toggle>
      </div>

      <v-table hover density="comfortable">
        <thead>
          <tr class="bg-surface-variant">
            <th class="text-caption font-weight-bold text-uppercase">License ID</th>
            <th class="text-caption font-weight-bold text-uppercase">Customer</th>
            <th class="text-caption font-weight-bold text-uppercase">SIM & Carrier</th>
            <th class="text-caption font-weight-bold text-uppercase">Expires On</th>
            <th class="text-caption font-weight-bold text-uppercase">Time Left</th>
            <th class="text-caption font-weight-bold text-uppercase text-end">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="lic in filteredExpiringList" :key="lic.id">
            <td class="font-family-monospace font-weight-bold text-primary">
              <router-link :to="`/licenses/${lic.id}`" class="text-decoration-none text-primary">
                {{ lic.id }}
              </router-link>
            </td>
            <td>
              <router-link :to="`/customers/${lic.customerId}`" class="text-decoration-none text-high-emphasis font-weight-medium">
                {{ lic.customerName }}
              </router-link>
            </td>
            <td>
              <div class="font-family-monospace font-weight-medium">{{ lic.simPhone }}</div>
              <div class="text-caption text-medium-emphasis">{{ lic.operator }}</div>
            </td>
            <td>{{ new Date(lic.expiresAt).toLocaleDateString() }}</td>
            <td>
              <v-chip
                :color="getTimeLeftColor(lic.expiresAt)"
                size="x-small"
                variant="tonal"
                class="font-weight-bold"
              >
                {{ getTimeLeftText(lic.expiresAt) }}
              </v-chip>
            </td>
            <td class="text-end">
              <div class="d-flex align-center justify-end ga-2">
                <v-btn
                  size="x-small"
                  variant="tonal"
                  color="primary"
                  prepend-icon="mdi-autorenew"
                  @click="handleRenew(lic.id)"
                >
                  Renew
                </v-btn>
                <v-btn
                  size="x-small"
                  variant="outlined"
                  color="secondary"
                  prepend-icon="mdi-phone"
                  @click="contactCustomer(lic)"
                >
                  Contact
                </v-btn>
              </div>
            </td>
          </tr>
        </tbody>
      </v-table>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useLicenseStore } from '@/stores/license.store';
import { useNotificationStore } from '@/stores/notification.store';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import type { License } from '@/types';

const licenseStore = useLicenseStore();
const notificationStore = useNotificationStore();
const { expiringLicenses } = storeToRefs(licenseStore);

const selectedCategory = ref('all');

onMounted(() => {
  licenseStore.fetchExpiringLicenses();
});

const allExpiringList = computed(() => {
  const map = new Map<string, License>();
  [
    ...expiringLicenses.value.expired,
    ...expiringLicenses.value.today,
    ...expiringLicenses.value.in3Days,
    ...expiringLicenses.value.in7Days,
    ...expiringLicenses.value.in30Days,
  ].forEach((l) => map.set(l.id, l));
  return Array.from(map.values());
});

const filteredExpiringList = computed(() => {
  switch (selectedCategory.value) {
    case 'expired':
      return expiringLicenses.value.expired;
    case 'today':
      return expiringLicenses.value.today;
    case '3days':
      return expiringLicenses.value.in3Days;
    case '30days':
      return expiringLicenses.value.in30Days;
    case 'all':
    default:
      return allExpiringList.value;
  }
});

const getTimeLeftText = (expiresAt: string) => {
  const diffDays = Math.ceil((new Date(expiresAt).getTime() - Date.now()) / (1000 * 3600 * 24));
  if (diffDays < 0) return `Expired ${Math.abs(diffDays)}d ago`;
  if (diffDays === 0) return 'Expires Today!';
  return `${diffDays} days left`;
};

const getTimeLeftColor = (expiresAt: string) => {
  const diffDays = (new Date(expiresAt).getTime() - Date.now()) / (1000 * 3600 * 24);
  if (diffDays <= 0) return 'error';
  if (diffDays <= 3) return 'warning';
  return 'info';
};

const handleRenew = async (id: string) => {
  await licenseStore.renewLicense(id, 12);
  notificationStore.showMessage('License renewed for 12 months', 'success');
  licenseStore.fetchExpiringLicenses();
};

const contactCustomer = (lic: License) => {
  notificationStore.showMessage(`Contacting ${lic.customerName} regarding ${lic.id}...`, 'info');
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
