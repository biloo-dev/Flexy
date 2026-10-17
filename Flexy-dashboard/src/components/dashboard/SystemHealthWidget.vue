<template>
  <v-card class="pa-4 fill-height border">
    <div class="d-flex align-center justify-space-between mb-3">
      <div>
        <h3 class="text-subtitle-1 font-weight-bold">System Health & Services</h3>
        <p class="text-caption text-medium-emphasis mb-0">Live infrastructure & microservices telemetry</p>
      </div>
      <v-chip color="success" size="small" variant="tonal" class="font-weight-bold">
        <v-icon start size="12">mdi-check-circle</v-icon>
        All Systems Operational
      </v-chip>
    </div>

    <v-list density="compact" class="pa-0 bg-transparent">
      <v-list-item
        v-for="service in services"
        :key="service.name"
        class="px-0 py-2 border-b-dashed"
      >
        <template #prepend>
          <v-avatar
            :color="service.status === 'operational' ? 'success' : 'warning'"
            variant="tonal"
            size="32"
            rounded="md"
            class="me-3"
          >
            <v-icon size="16">
              {{ getCategoryIcon(service.category) }}
            </v-icon>
          </v-avatar>
        </template>

        <v-list-item-title class="d-flex align-center justify-space-between">
          <span class="text-body-2 font-weight-bold">{{ service.name }}</span>
          <div class="d-flex align-center ga-2">
            <span class="text-caption font-family-monospace text-medium-emphasis">{{ service.latencyMs }}ms</span>
            <v-chip
              :color="service.status === 'operational' ? 'success' : 'warning'"
              size="x-small"
              variant="tonal"
              class="font-weight-bold text-capitalize"
            >
              ● {{ service.status }}
            </v-chip>
          </div>
        </v-list-item-title>

        <v-list-item-subtitle class="d-flex align-center justify-space-between text-caption text-medium-emphasis mt-1">
          <span>Uptime: {{ service.uptime }}</span>
          <span>Checked: {{ service.lastChecked }}</span>
        </v-list-item-subtitle>
      </v-list-item>
    </v-list>
  </v-card>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';
import { useMonitoringStore } from '@/stores/monitoring.store';
import { storeToRefs } from 'pinia';

const monitoringStore = useMonitoringStore();
const { services } = storeToRefs(monitoringStore);

onMounted(() => {
  if (!services.value.length) {
    monitoringStore.fetchServices();
  }
});

const getCategoryIcon = (category: string) => {
  switch (category) {
    case 'API':
      return 'mdi-api';
    case 'Database':
      return 'mdi-database-check';
    case 'Auth':
      return 'mdi-shield-lock';
    case 'License Service':
      return 'mdi-key-variant';
    case 'Heartbeat Service':
      return 'mdi-heart-pulse';
    case 'Flexi Engine':
      return 'mdi-rocket-launch';
    default:
      return 'mdi-server';
  }
};
</script>

<style scoped>
.border-b-dashed {
  border-bottom: 1px dashed rgba(var(--v-border-color), 0.2);
}
.border-b-dashed:last-child {
  border-bottom: none;
}
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
