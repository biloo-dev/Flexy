<template>
  <div class="security-overview-view">
    <PageHeader
      title="Security & Threat Center"
      subtitle="Hardware integrity protection, SIM swap detection, and cryptographic validation alerts."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Security Center' }]"
    >
      <template #actions>
        <v-btn
          color="error"
          variant="tonal"
          prepend-icon="mdi-alert-octagon-outline"
          to="/security/events"
          class="font-weight-bold"
        >
          View All Threat Events
        </v-btn>
      </template>
    </PageHeader>

    <!-- Threat KPIs Grid -->
    <v-row class="mb-4">
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="ICCID Mismatches"
          :value="stats.iccidMismatches || 14"
          icon="mdi-sim-alert"
          color="error"
          subtitle="SIM swapping attempts"
          to="/security/events"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Device Mismatches"
          :value="stats.deviceMismatches || 8"
          icon="mdi-laptop-off"
          color="error"
          subtitle="Hardware cloning alerts"
          to="/security/events"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Invalid Signatures"
          :value="stats.invalidSignatures || 3"
          icon="mdi-key-remove"
          color="warning"
          subtitle="Ed25519 forgery attempts"
          to="/security/events"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Blocked Operations"
          :value="stats.blockedOperations || 450"
          icon="mdi-shield-lock"
          color="error"
          subtitle="Real-time interceptions"
          to="/operations"
        />
      </v-col>
      <v-col cols="12" sm="6" md="2.4">
        <MetricCard
          title="Revoked Licenses"
          :value="stats.revokedLicenses || 2"
          icon="mdi-cancel"
          color="error"
          subtitle="Blacklisted credentials"
          to="/licenses"
        />
      </v-col>
    </v-row>

    <!-- Recent Critical Security Incidents -->
    <v-card class="pa-5 border mb-6">
      <div class="d-flex align-center justify-space-between mb-4">
        <div>
          <h3 class="text-subtitle-1 font-weight-bold text-error d-flex align-center ga-2">
            <v-icon size="20">mdi-shield-alert</v-icon>
            Active Threat Feed & Security Violations
          </h3>
          <p class="text-caption text-medium-emphasis mb-0">Automatic anomaly detection engine</p>
        </div>
        <v-btn
          variant="outlined"
          size="small"
          color="primary"
          to="/security/events"
        >
          Full Events Log
        </v-btn>
      </div>

      <v-list lines="two" class="pa-0">
        <v-list-item
          v-for="ev in events.slice(0, 5)"
          :key="ev.id"
          class="border rounded-lg mb-2"
        >
          <template #prepend>
            <v-avatar :color="ev.severity === 'critical' ? 'error' : 'warning'" variant="tonal" size="36" class="me-3">
              <v-icon size="20">
                {{ ev.type === 'ICCID_MISMATCH' ? 'mdi-sim-alert' : ev.type === 'DEVICE_MISMATCH' ? 'mdi-laptop-off' : 'mdi-shield-alert' }}
              </v-icon>
            </v-avatar>
          </template>

          <v-list-item-title class="font-weight-bold d-flex align-center justify-space-between">
            <span>{{ ev.title }}</span>
            <v-chip :color="ev.severity === 'critical' ? 'error' : 'warning'" size="x-small" variant="tonal" class="font-weight-bold text-uppercase">
              {{ ev.severity }}
            </v-chip>
          </v-list-item-title>

          <v-list-item-subtitle class="text-caption text-medium-emphasis mt-1">
            {{ ev.description }}
          </v-list-item-subtitle>

          <template #append>
            <div class="d-flex align-center ga-2">
              <span class="text-caption text-medium-emphasis">{{ new Date(ev.timestamp).toLocaleTimeString() }}</span>
              <v-btn
                v-if="!ev.resolved"
                size="x-small"
                variant="tonal"
                color="success"
                @click="resolveEvent(ev.id)"
              >
                Acknowledge
              </v-btn>
              <v-chip v-else size="x-small" color="success" variant="tonal">Resolved</v-chip>
            </div>
          </template>
        </v-list-item>
      </v-list>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';
import { useSecurityStore } from '@/stores/security.store';
import { useNotificationStore } from '@/stores/notification.store';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import MetricCard from '@/components/common/MetricCard.vue';

const securityStore = useSecurityStore();
const notificationStore = useNotificationStore();
const { events, stats } = storeToRefs(securityStore);

onMounted(() => {
  securityStore.fetchSecurityEvents();
  securityStore.fetchStats();
});

const resolveEvent = async (id: string) => {
  await securityStore.resolveEvent(id);
  notificationStore.showMessage('Security event acknowledged and marked resolved', 'success');
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
