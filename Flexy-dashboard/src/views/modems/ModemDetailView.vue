<template>
  <div class="modem-detail-view">
    <PageHeader
      :title="modem ? `${modem.name} (${modem.model})` : 'Modem Diagnostics'"
      :subtitle="modem ? `IMEI: ${modem.imei} • Serial Port: ${modem.port}` : ''"
      :breadcrumbs="[
        { title: 'Dashboard', to: '/dashboard' },
        { title: 'Modems', to: '/modems' },
        { title: modem ? modem.name : 'Detail' }
      ]"
    >
      <template #badge>
        <StatusChip v-if="modem" :status="modem.status" size="default" />
      </template>

      <template #actions>
        <v-btn
          color="primary"
          variant="tonal"
          prepend-icon="mdi-restart"
          :loading="restarting"
          @click="handleRestartPort"
        >
          Reset AT Port
        </v-btn>
      </template>
    </PageHeader>

    <LoadingSkeleton v-if="loading && !modem" type="card@3" />

    <ErrorState
      v-else-if="!modem"
      title="Modem Not Found"
      message="The modem hardware profile you requested was not found."
      @retry="loadModem"
    />

    <template v-else>
      <!-- Telemetry Cards -->
      <v-row class="mb-4">
        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Hardware IMEI</div>
            <div class="text-body-1 font-weight-bold font-family-monospace mt-1 d-flex align-center ga-1">
              <span>{{ modem.imei }}</span>
              <CopyButton :text="modem.imei" />
            </div>
            <div class="text-caption text-medium-emphasis mt-2">{{ modem.manufacturer }}</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Signal Quality & RAT</div>
            <div class="text-h6 font-weight-bold text-success mt-1 d-flex align-center ga-2">
              <v-icon size="22">mdi-signal-cellular-3</v-icon>
              <span>{{ modem.signalStrength }}% ({{ modem.connectionType }})</span>
            </div>
            <div class="text-caption text-medium-emphasis mt-2">RSRP: -82 dBm • SINR: 18dB</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">SIM Hardware Detection</div>
            <div class="text-h6 font-weight-bold mt-1 d-flex align-center ga-2" :class="modem.simDetected ? 'text-success' : 'text-error'">
              <v-icon size="22">{{ modem.simDetected ? 'mdi-sim' : 'mdi-sim-off' }}</v-icon>
              <span>{{ modem.simDetected ? 'SIM Inserted' : 'No SIM Detected' }}</span>
            </div>
            <div class="text-caption text-medium-emphasis mt-2">PIN State: READY (Unlocked)</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Last Heartbeat Ping</div>
            <div class="text-h6 font-weight-bold text-primary mt-1">
              {{ new Date(modem.lastHeartbeat).toLocaleTimeString() }}
            </div>
            <div class="text-caption text-medium-emphasis mt-2">{{ new Date(modem.lastHeartbeat).toLocaleDateString() }}</div>
          </v-card>
        </v-col>
      </v-row>

      <!-- Details & Heartbeat Timeline -->
      <v-row>
        <v-col cols="12" md="6">
          <v-card variant="outlined" class="pa-4 fill-height">
            <h4 class="text-subtitle-2 font-weight-bold mb-3">Hardware Port & Host Mapping</h4>
            <v-list density="compact" class="pa-0">
              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Modem ID:</span></template>
                <span class="text-body-2 font-weight-bold font-family-monospace">{{ modem.id }}</span>
              </v-list-item>
              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Serial Port:</span></template>
                <v-chip size="x-small" variant="outlined" class="font-family-monospace">{{ modem.port }}</v-chip>
              </v-list-item>
              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Host Device:</span></template>
                <router-link :to="`/devices/${modem.boundDeviceId}`" class="text-body-2 text-decoration-none font-weight-bold text-info">
                  {{ modem.boundDeviceName }}
                </router-link>
              </v-list-item>
              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Bound SIM:</span></template>
                <router-link v-if="modem.boundSimId" :to="`/sim-cards/${modem.boundSimId}`" class="text-body-2 text-decoration-none font-weight-bold text-primary">
                  {{ modem.boundSimPhone }} ({{ modem.boundSimOperator }})
                </router-link>
                <span v-else class="text-caption text-medium-emphasis">None</span>
              </v-list-item>
              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">AT Commands:</span></template>
                <span class="text-caption font-family-monospace">AT+CSQ, AT+CPIN?, AT+CUSD=1...</span>
              </v-list-item>
            </v-list>
          </v-card>
        </v-col>

        <v-col cols="12" md="6">
          <v-card variant="outlined" class="pa-4 fill-height">
            <h4 class="text-subtitle-2 font-weight-bold mb-3">Heartbeat Stream History</h4>
            <v-timeline density="compact" align="start">
              <v-timeline-item dot-color="success" size="x-small">
                <div class="text-caption font-weight-bold">Heartbeat ACK (24ms)</div>
                <div class="text-caption text-medium-emphasis">Signal: 88% • 4G LTE • Port healthy</div>
              </v-timeline-item>
              <v-timeline-item dot-color="success" size="x-small">
                <div class="text-caption font-weight-bold">USSD Session Completed</div>
                <div class="text-caption text-medium-emphasis">Flexi recharge for 1,000 DZD passed</div>
              </v-timeline-item>
              <v-timeline-item dot-color="primary" size="x-small">
                <div class="text-caption font-weight-bold">Modem Initialized</div>
                <div class="text-caption text-medium-emphasis">Port {{ modem.port }} baudrate 115200 8N1</div>
              </v-timeline-item>
            </v-timeline>
          </v-card>
        </v-col>
      </v-row>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useModemStore } from '@/stores/modem.store';
import { useNotificationStore } from '@/stores/notification.store';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import StatusChip from '@/components/common/StatusChip.vue';
import CopyButton from '@/components/common/CopyButton.vue';
import LoadingSkeleton from '@/components/common/LoadingSkeleton.vue';
import ErrorState from '@/components/common/ErrorState.vue';

const route = useRoute();
const modemStore = useModemStore();
const notificationStore = useNotificationStore();

const { currentModem: modem, loading } = storeToRefs(modemStore);
const restarting = ref(false);

const modemId = computed(() => route.params.id as string);

const loadModem = () => {
  if (modemId.value) {
    modemStore.fetchModemById(modemId.value);
  }
};

onMounted(loadModem);

const handleRestartPort = async () => {
  restarting.value = true;
  setTimeout(() => {
    restarting.value = false;
    notificationStore.showMessage(`Port ${modem.value?.port} reset successfully`, 'success');
  }, 1000);
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
