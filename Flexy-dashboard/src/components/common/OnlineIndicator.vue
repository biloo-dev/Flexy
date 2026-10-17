<template>
  <div class="d-inline-flex align-center ga-1">
    <span
      class="status-dot"
      :class="[statusClass, { 'pulse': pulse && status === 'online' }]"
    ></span>
    <span v-if="label" class="text-caption font-weight-medium text-capitalize" :class="textClass">
      {{ label }}
    </span>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = withDefaults(
  defineProps<{
    status: 'online' | 'offline' | 'blocked' | 'unknown' | 'connected' | 'reconnecting';
    label?: string;
    pulse?: boolean;
  }>(),
  {
    pulse: true,
  }
);

const statusClass = computed(() => {
  switch (props.status) {
    case 'online':
    case 'connected':
      return 'bg-success';
    case 'offline':
      return 'bg-error';
    case 'blocked':
      return 'bg-error';
    case 'reconnecting':
      return 'bg-warning';
    default:
      return 'bg-grey';
  }
});

const textClass = computed(() => {
  switch (props.status) {
    case 'online':
    case 'connected':
      return 'text-success';
    case 'offline':
    case 'blocked':
      return 'text-error';
    case 'reconnecting':
      return 'text-warning';
    default:
      return 'text-medium-emphasis';
  }
});
</script>

<style scoped>
.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
}

.pulse {
  box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7);
  animation: pulse-animation 2s infinite;
}

@keyframes pulse-animation {
  0% {
    box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7);
  }
  70% {
    box-shadow: 0 0 0 6px rgba(16, 185, 129, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(16, 185, 129, 0);
  }
}
</style>
