<template>
  <div class="device-detail-view">
    <!-- Header with Breadcrumbs -->
    <PageHeader
      :title="device ? device.name : 'Device Host'"
      :subtitle="device ? `UUID: ${device.uuid} • Customer: ${device.customerName}` : ''"
      :breadcrumbs="[
        { title: 'Dashboard', to: '/dashboard' },
        { title: 'Devices', to: '/devices' },
        { title: device ? device.name : 'Detail' }
      ]"
    >
      <template #badge>
        <StatusChip v-if="device" :status="device.status" size="default" />
      </template>
    </PageHeader>

    <LoadingSkeleton v-if="loading && !device" type="card@3" />

    <ErrorState
      v-else-if="!device"
      title="Device Not Found"
      message="The requested edge device could not be identified."
      @retry="loadDevice"
    />

    <template v-else>
      <!-- Hardware Telemetry Cards -->
      <v-row class="mb-4">
        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Hardware Fingerprint</div>
            <div class="text-caption font-family-monospace font-weight-bold text-truncate mt-1">
              {{ device.fingerprint }}
            </div>
            <div class="text-caption text-medium-emphasis mt-2">SHA-256 System Enclave</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Edge Daemon Version</div>
            <div class="text-h6 font-weight-bold text-info mt-1">
              {{ device.appVersion }}
            </div>
            <div class="text-caption text-medium-emphasis mt-2">{{ device.os }}</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Connected Modems & SIMs</div>
            <div class="text-h6 font-weight-bold text-success mt-1">
              {{ device.modemsCount }} Modems / {{ device.simsCount }} SIMs
            </div>
            <div class="text-caption text-medium-emphasis mt-2">All Ports Operational</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Last Heartbeat Seen</div>
            <div class="text-h6 font-weight-bold mt-1" :class="device.status === 'online' ? 'text-success' : 'text-error'">
              {{ device.lastSeen }}
            </div>
            <div class="text-caption text-medium-emphasis mt-2">IP: {{ device.ipAddress }}</div>
          </v-card>
        </v-col>
      </v-row>

      <!-- Tabs -->
      <v-card class="border">
        <v-tabs v-model="tab" color="primary" class="border-b">
          <v-tab value="overview" prepend-icon="mdi-information-outline">Overview</v-tab>
          <v-tab value="modems" prepend-icon="mdi-router-wireless">Modems ({{ device.modemsCount }})</v-tab>
          <v-tab value="sims" prepend-icon="mdi-sim">SIM Cards ({{ device.simsCount }})</v-tab>
          <v-tab value="heartbeats" prepend-icon="mdi-heart-pulse">Heartbeats</v-tab>
          <v-tab value="security" prepend-icon="mdi-shield-alert-outline">Security Events</v-tab>
          <v-tab value="audit" prepend-icon="mdi-file-document-outline">Audit</v-tab>
        </v-tabs>

        <v-card-text class="pa-4">
          <v-window v-model="tab">
            <!-- 1. Overview -->
            <v-window-item value="overview">
              <v-card variant="outlined" class="pa-4">
                <h4 class="text-subtitle-2 font-weight-bold mb-3">System Information & Cryptographic Binding</h4>
                <v-list density="compact" class="pa-0">
                  <v-list-item class="px-0">
                    <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 130px;">Device ID:</span></template>
                    <span class="text-body-2 font-weight-bold font-family-monospace">{{ device.id }}</span>
                  </v-list-item>
                  <v-list-item class="px-0">
                    <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 130px;">Hardware UUID:</span></template>
                    <span class="text-body-2 font-family-monospace">{{ device.uuid }}</span>
                  </v-list-item>
                  <v-list-item class="px-0">
                    <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 130px;">Fingerprint:</span></template>
                    <span class="text-caption font-family-monospace">{{ device.fingerprint }}</span>
                  </v-list-item>
                  <v-list-item class="px-0">
                    <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 130px;">Assigned Customer:</span></template>
                    <router-link :to="`/customers/${device.customerId}`" class="text-body-2 text-decoration-none font-weight-bold text-primary">
                      {{ device.customerName }}
                    </router-link>
                  </v-list-item>
                </v-list>
              </v-card>
            </v-window-item>

            <!-- 2. Modems -->
            <v-window-item value="modems">
              <v-list lines="two">
                <v-list-item
                  v-for="m in deviceModems"
                  :key="m.id"
                  class="border rounded-lg mb-2 cursor-pointer"
                  :to="`/modems/${m.id}`"
                >
                  <template #prepend>
                    <v-avatar color="secondary" variant="tonal" size="36" class="me-3">
                      <v-icon size="20">mdi-router-wireless</v-icon>
                    </v-avatar>
                  </template>
                  <v-list-item-title class="font-weight-bold">{{ m.name }} ({{ m.model }})</v-list-item-title>
                  <v-list-item-subtitle class="text-caption">
                    IMEI: {{ m.imei }} • Port: {{ m.port }} • Signal: {{ m.signalStrength }}%
                  </v-list-item-subtitle>
                  <template #append>
                    <StatusChip :status="m.status" />
                  </template>
                </v-list-item>
              </v-list>
            </v-window-item>

            <!-- 3. SIMs -->
            <v-window-item value="sims">
              <v-list lines="two">
                <v-list-item
                  v-for="s in deviceSims"
                  :key="s.id"
                  class="border rounded-lg mb-2 cursor-pointer"
                  :to="`/sim-cards/${s.id}`"
                >
                  <template #prepend>
                    <v-avatar :color="s.operator === 'MOBILIS' ? 'success' : s.operator === 'DJEZZY' ? 'error' : 'accent'" variant="tonal" size="36" class="me-3">
                      <v-icon size="20">mdi-sim</v-icon>
                    </v-avatar>
                  </template>
                  <v-list-item-title class="font-weight-bold">{{ s.operator }} - {{ s.phoneNumber }}</v-list-item-title>
                  <v-list-item-subtitle class="text-caption">
                    ICCID: <MaskedValue :raw-value="s.iccid" /> • License: {{ s.licenseId }}
                  </v-list-item-subtitle>
                  <template #append>
                    <StatusChip :status="s.status" />
                  </template>
                </v-list-item>
              </v-list>
            </v-window-item>

            <!-- 4. Heartbeats -->
            <v-window-item value="heartbeats">
              <div class="pa-4 border rounded-lg bg-surface-variant">
                <div class="d-flex align-center justify-space-between mb-2">
                  <span class="text-body-2 font-weight-bold">Continuous Daemon Health Telemetry</span>
                  <v-chip color="success" size="x-small" variant="tonal">Active</v-chip>
                </div>
                <div class="text-caption text-medium-emphasis">
                  Device sends heartbeat ping every 15 seconds including CPU temperature, RAM usage, and active port locks.
                </div>
              </div>
            </v-window-item>

            <!-- 5. Security -->
            <v-window-item value="security">
              <v-list lines="two">
                <v-list-item
                  v-for="ev in deviceEvents"
                  :key="ev.id"
                  class="border rounded-lg mb-2"
                >
                  <template #prepend>
                    <v-avatar :color="ev.severity === 'critical' ? 'error' : 'warning'" variant="tonal" size="36" class="me-3">
                      <v-icon size="20">mdi-alert-circle</v-icon>
                    </v-avatar>
                  </template>
                  <v-list-item-title class="font-weight-bold">{{ ev.title }}</v-list-item-title>
                  <v-list-item-subtitle class="text-caption">{{ ev.description }}</v-list-item-subtitle>
                  <template #append>
                    <v-chip :color="ev.severity === 'critical' ? 'error' : 'warning'" size="x-small" variant="tonal" class="text-uppercase font-weight-bold">
                      {{ ev.severity }}
                    </v-chip>
                  </template>
                </v-list-item>
              </v-list>
            </v-window-item>

            <!-- 6. Audit -->
            <v-window-item value="audit">
              <div class="text-caption text-medium-emphasis">
                Immutable audit trail for physical host {{ device.id }}.
              </div>
            </v-window-item>
          </v-window>
        </v-card-text>
      </v-card>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useDeviceStore } from '@/stores/device.store';
import { storeToRefs } from 'pinia';
import { mockModems, mockSimCards, mockSecurityEvents } from '@/api/mock/mockData';
import PageHeader from '@/components/common/PageHeader.vue';
import StatusChip from '@/components/common/StatusChip.vue';
import MaskedValue from '@/components/common/MaskedValue.vue';
import LoadingSkeleton from '@/components/common/LoadingSkeleton.vue';
import ErrorState from '@/components/common/ErrorState.vue';

const route = useRoute();
const deviceStore = useDeviceStore();
const { currentDevice: device, loading } = storeToRefs(deviceStore);
const tab = ref('overview');

const deviceId = computed(() => route.params.id as string);

const deviceModems = computed(() => mockModems.filter((m) => m.boundDeviceId === deviceId.value));
const deviceSims = computed(() => mockSimCards.filter((s) => s.boundDeviceId === deviceId.value));
const deviceEvents = computed(() => mockSecurityEvents.filter((e) => e.deviceId === deviceId.value));

const loadDevice = () => {
  if (deviceId.value) {
    deviceStore.fetchDeviceById(deviceId.value);
  }
};

onMounted(loadDevice);
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
.cursor-pointer {
  cursor: pointer;
}
</style>
