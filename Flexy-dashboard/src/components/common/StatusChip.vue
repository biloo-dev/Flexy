<template>
  <v-chip
    :color="statusColor"
    :variant="variant"
    :size="size"
    class="font-weight-medium text-capitalize"
  >
    <v-icon v-if="icon" start size="14">{{ icon }}</v-icon>
    {{ label || status }}
  </v-chip>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = withDefaults(
  defineProps<{
    status: string;
    label?: string;
    size?: 'x-small' | 'small' | 'default' | 'large';
    variant?: 'flat' | 'tonal' | 'outlined';
  }>(),
  {
    size: 'small',
    variant: 'tonal',
  }
);

const statusColor = computed(() => {
  const s = props.status?.toLowerCase() || '';
  switch (s) {
    case 'active':
    case 'success':
    case 'paid':
    case 'operational':
    case 'online':
      return 'success';
    case 'pending':
    case 'warning':
    case 'degraded':
      return 'warning';
    case 'suspended':
    case 'expired':
      return 'warning';
    case 'blocked':
    case 'revoked':
    case 'failed':
    case 'offline':
    case 'critical':
      return 'error';
    case 'info':
    case 'reconnecting':
      return 'info';
    default:
      return 'secondary';
  }
});

const icon = computed(() => {
  const s = props.status?.toLowerCase() || '';
  switch (s) {
    case 'active':
    case 'success':
    case 'paid':
    case 'online':
      return 'mdi-check-circle-outline';
    case 'pending':
      return 'mdi-clock-outline';
    case 'suspended':
    case 'expired':
      return 'mdi-alert-circle-outline';
    case 'blocked':
    case 'revoked':
    case 'failed':
    case 'offline':
      return 'mdi-close-circle-outline';
    default:
      return '';
  }
});
</script>
