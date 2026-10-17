<template>
  <div class="activity-timeline">
    <div
      v-for="(item, index) in items"
      :key="item.id || index"
      class="timeline-row d-flex align-start ga-3 pb-4"
    >
      <!-- Timeline icon & line -->
      <div class="timeline-indicator-wrapper d-flex flex-column align-center">
        <v-avatar :color="item.color || 'primary'" variant="tonal" size="32" rounded="circle">
          <v-icon :size="16">{{ item.icon || 'mdi-circle-medium' }}</v-icon>
        </v-avatar>
        <div v-if="index < items.length - 1" class="timeline-line my-1"></div>
      </div>

      <!-- Content -->
      <div class="timeline-content flex-grow-1 pt-1">
        <div class="d-flex align-center justify-space-between ga-2">
          <span class="text-body-2 font-weight-bold text-high-emphasis">{{ item.title }}</span>
          <span class="text-caption text-medium-emphasis text-no-wrap">{{ item.time }}</span>
        </div>
        <p v-if="item.description" class="text-caption text-medium-emphasis mb-1">
          {{ item.description }}
        </p>
        
        <!-- Metadata tags -->
        <div v-if="item.customer || item.device || item.sim" class="d-flex flex-wrap align-center ga-2 mt-1">
          <v-chip v-if="item.customer" size="x-small" variant="outlined" density="compact">
            <v-icon start size="12">mdi-account</v-icon>
            {{ item.customer }}
          </v-chip>
          <v-chip v-if="item.sim" size="x-small" variant="outlined" density="compact" color="info">
            <v-icon start size="12">mdi-sim</v-icon>
            {{ item.sim }}
          </v-chip>
          <v-chip v-if="item.device" size="x-small" variant="outlined" density="compact" color="secondary">
            <v-icon start size="12">mdi-router-wireless</v-icon>
            {{ item.device }}
          </v-chip>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
export interface TimelineItem {
  id?: string;
  title: string;
  description?: string;
  time: string;
  icon?: string;
  color?: string;
  customer?: string;
  device?: string;
  sim?: string;
}

defineProps<{
  items: TimelineItem[];
}>();
</script>

<style scoped>
.timeline-indicator-wrapper {
  position: relative;
  min-width: 32px;
}
.timeline-line {
  width: 2px;
  flex-grow: 1;
  min-height: 24px;
  background-color: rgba(var(--v-border-color), 0.2);
}
</style>
