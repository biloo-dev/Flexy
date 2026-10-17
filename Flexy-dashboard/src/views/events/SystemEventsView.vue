<template>
  <div class="system-events-view">
    <PageHeader
      title="Live System Events Stream"
      subtitle="Full real-time telemetric event stream across microservices, licenses, and telecom carriers."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'System Events' }]"
    >
      <template #actions>
        <v-btn-toggle v-model="categoryFilter" mandatory density="compact" variant="outlined" color="primary">
          <v-btn value="all" size="x-small">All Categories</v-btn>
          <v-btn value="Flexi" size="x-small">Flexi</v-btn>
          <v-btn value="License" size="x-small">License</v-btn>
          <v-btn value="SIM" size="x-small">SIM</v-btn>
          <v-btn value="Security" size="x-small">Security</v-btn>
        </v-btn-toggle>
      </template>
    </PageHeader>

    <v-card class="pa-4 border">
      <v-list lines="two" class="pa-0">
        <v-list-item
          v-for="ev in filteredEvents"
          :key="ev.id"
          class="border rounded-lg mb-2"
        >
          <template #prepend>
            <v-avatar :color="getCategoryColor(ev.category)" variant="tonal" size="36" class="me-3">
              <v-icon size="20">{{ getCategoryIcon(ev.category) }}</v-icon>
            </v-avatar>
          </template>

          <v-list-item-title class="font-weight-bold d-flex align-center justify-space-between">
            <span>{{ ev.type }}</span>
            <v-chip :color="getCategoryColor(ev.category)" size="x-small" variant="tonal" class="font-weight-bold">
              {{ ev.category }}
            </v-chip>
          </v-list-item-title>

          <v-list-item-subtitle class="text-caption text-medium-emphasis mt-1">
            {{ ev.description }}
          </v-list-item-subtitle>

          <template #append>
            <span class="text-caption text-medium-emphasis font-family-monospace">
              {{ ev.timestamp }}
            </span>
          </template>
        </v-list-item>
      </v-list>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import PageHeader from '@/components/common/PageHeader.vue';

const categoryFilter = ref('all');

const systemEvents = [
  { id: 'EV-01', category: 'Flexi', type: 'FLEXI_RECHARGE_CONFIRMED', description: 'Transaction #FLX-20260820-001 executed on Djezzy gateway via /dev/ttyUSB0', severity: 'info', timestamp: '16:15:32' },
  { id: 'EV-02', category: 'License', type: 'ED25519_LICENSE_VERIFIED', description: 'License LIC-301 cryptographic signature verified for Device DVC-001', severity: 'info', timestamp: '16:10:00' },
  { id: 'EV-03', category: 'Security', type: 'ICCID_MISMATCH_ALERT', description: 'SIM swap anomaly detected on modem MDM-107. Transaction blocked.', severity: 'critical', timestamp: '15:30:05' },
  { id: 'EV-04', category: 'Payment', type: 'PAYMENT_SETTLED_CIB', description: 'Payment of 35,000 DZD confirmed via SATIM/CIB gateway for LIC-301', severity: 'info', timestamp: '11:55:00' },
  { id: 'EV-05', category: 'SIM', type: 'SIM_BALANCE_SYNCHRONIZED', description: 'Balance updated: 45,800 DZD available on Djezzy SIM (+213 770 11 22 33)', severity: 'info', timestamp: '10:30:00' },
  { id: 'EV-06', category: 'Device', type: 'HEARTBEAT_ACKNOWLEDGED', description: 'Oran Station Master (DVC-003) sent health telemetry: CPU 24%, 4G LTE 85%', severity: 'info', timestamp: '10:00:00' },
];

const filteredEvents = computed(() => {
  if (categoryFilter.value === 'all') return systemEvents;
  return systemEvents.filter((e) => e.category === categoryFilter.value);
});

const getCategoryColor = (cat: string) => {
  switch (cat) {
    case 'Flexi': return 'primary';
    case 'License': return 'info';
    case 'Security': return 'error';
    case 'SIM': return 'success';
    case 'Payment': return 'warning';
    default: return 'secondary';
  }
};

const getCategoryIcon = (cat: string) => {
  switch (cat) {
    case 'Flexi': return 'mdi-swap-horizontal-bold';
    case 'License': return 'mdi-key-chain';
    case 'Security': return 'mdi-shield-alert';
    case 'SIM': return 'mdi-sim';
    case 'Payment': return 'mdi-cash-multiple';
    default: return 'mdi-bell-outline';
  }
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
