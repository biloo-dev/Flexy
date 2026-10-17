<template>
  <div class="heartbeat-monitor-view">
    <PageHeader
      title="Heartbeat & Hardware Telemetry Monitor"
      subtitle="Real-time ping telemetry, CPU temperatures, and network connectivity across all edge nodes."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Heartbeat Monitor' }]"
    >
      <template #actions>
        <v-btn
          color="primary"
          variant="tonal"
          prepend-icon="mdi-refresh"
          @click="refreshHeartbeats"
        >
          Ping All Nodes
        </v-btn>
      </template>
    </PageHeader>

    <!-- Online / Offline Quick Counts -->
    <v-row class="mb-4">
      <v-col cols="12" sm="6" md="3">
        <MetricCard
          title="Online Devices"
          :value="onlineDevicesCount"
          icon="mdi-laptop"
          color="success"
        />
      </v-col>
      <v-col cols="12" sm="6" md="3">
        <MetricCard
          title="Offline Devices"
          :value="offlineDevicesCount"
          icon="mdi-laptop-off"
          color="error"
        />
      </v-col>
      <v-col cols="12" sm="6" md="3">
        <MetricCard
          title="Online Modems"
          :value="onlineModemsCount"
          icon="mdi-router-wireless"
          color="success"
        />
      </v-col>
      <v-col cols="12" sm="6" md="3">
        <MetricCard
          title="Offline Modems"
          :value="offlineModemsCount"
          icon="mdi-router-wireless-off"
          color="error"
        />
      </v-col>
    </v-row>

    <!-- Real-Time Hardware Nodes Grid -->
    <v-row>
      <v-col
        v-for="hb in heartbeats"
        :key="hb.id"
        cols="12"
        md="6"
        lg="4"
      >
        <v-card class="pa-4 border fill-height">
          <div class="d-flex align-center justify-space-between mb-3">
            <div class="d-flex align-center ga-2">
              <OnlineIndicator :status="hb.status === 'online' ? 'online' : 'offline'" />
              <span class="text-body-1 font-weight-bold">{{ hb.deviceName }}</span>
            </div>
            <StatusChip :status="hb.status" size="x-small" />
          </div>

          <div class="text-caption font-family-monospace text-medium-emphasis mb-3">
            Node ID: {{ hb.deviceId }} • Modem: {{ hb.modemId || 'N/A' }}
          </div>

          <v-divider class="my-2" />

          <!-- Telemetry Gauges -->
          <div class="py-2">
            <!-- CPU Load -->
            <div class="d-flex align-center justify-space-between text-caption mb-1">
              <span>CPU Utilization</span>
              <span class="font-weight-bold font-family-monospace">{{ hb.cpuUsage }}%</span>
            </div>
            <v-progress-linear
              :model-value="hb.cpuUsage"
              :color="hb.cpuUsage > 80 ? 'error' : hb.cpuUsage > 50 ? 'warning' : 'primary'"
              height="6"
              rounded
              class="mb-3"
            />

            <!-- Memory Load -->
            <div class="d-flex align-center justify-space-between text-caption mb-1">
              <span>Memory (RAM)</span>
              <span class="font-weight-bold font-family-monospace">{{ hb.memoryUsage }}%</span>
            </div>
            <v-progress-linear
              :model-value="hb.memoryUsage"
              color="info"
              height="6"
              rounded
              class="mb-3"
            />

            <!-- Signal & Temperature -->
            <v-row dense class="text-caption mt-1">
              <v-col cols="6">
                <div class="text-medium-emphasis">Temperature</div>
                <div class="font-weight-bold font-family-monospace text-high-emphasis">
                  {{ hb.temperature }}°C
                </div>
              </v-col>
              <v-col cols="6">
                <div class="text-medium-emphasis">Signal Quality</div>
                <div class="font-weight-bold font-family-monospace text-success">
                  {{ hb.signalStrength }}%
                </div>
              </v-col>
            </v-row>
          </div>

          <v-divider class="my-2" />

          <div class="d-flex align-center justify-space-between pt-1">
            <span class="text-caption text-medium-emphasis">Latency: {{ hb.latencyMs }}ms</span>
            <v-btn
              size="x-small"
              variant="text"
              color="primary"
              :to="`/devices/${hb.deviceId}`"
            >
              Open Diagnostics
            </v-btn>
          </div>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue';
import { useMonitoringStore } from '@/stores/monitoring.store';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import MetricCard from '@/components/common/MetricCard.vue';
import StatusChip from '@/components/common/StatusChip.vue';
import OnlineIndicator from '@/components/common/OnlineIndicator.vue';

const monitoringStore = useMonitoringStore();
const { heartbeats } = storeToRefs(monitoringStore);

onMounted(() => {
  monitoringStore.fetchHeartbeats();
});

const onlineDevicesCount = computed(() => heartbeats.value.filter((h) => h.status === 'online').length);
const offlineDevicesCount = computed(() => heartbeats.value.filter((h) => h.status === 'offline').length);
const onlineModemsCount = computed(() => 5);
const offlineModemsCount = computed(() => 2);

const refreshHeartbeats = () => {
  monitoringStore.fetchHeartbeats();
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
