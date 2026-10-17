<template>
  <v-chip
    :color="chipConfig.color"
    :variant="variant"
    :size="size"
    class="font-weight-bold"
  >
    <v-icon start size="14">{{ chipConfig.icon }}</v-icon>
    {{ chipConfig.text }}
  </v-chip>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { OperationStatus } from '@/types';

const props = withDefaults(
  defineProps<{
    status: OperationStatus | string;
    size?: 'x-small' | 'small' | 'default';
    variant?: 'flat' | 'tonal' | 'outlined';
  }>(),
  {
    size: 'small',
    variant: 'tonal',
  }
);

const chipConfig = computed(() => {
  switch (props.status) {
    case 'success':
      return { color: 'success', icon: 'mdi-check-circle', text: 'Successful' };
    case 'failed':
      return { color: 'error', icon: 'mdi-close-circle', text: 'Failed' };
    case 'blocked':
      return { color: 'error', icon: 'mdi-shield-lock', text: 'Blocked' };
    case 'pending':
      return { color: 'warning', icon: 'mdi-clock-outline', text: 'Pending' };
    default:
      return { color: 'secondary', icon: 'mdi-help-circle', text: props.status };
  }
});
</script>
