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
import type { LicenseStatus } from '@/types';

const props = withDefaults(
  defineProps<{
    status: LicenseStatus | string;
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
    case 'active':
      return { color: 'success', icon: 'mdi-shield-check', text: 'Active' };
    case 'pending':
      return { color: 'warning', icon: 'mdi-clock-outline', text: 'Pending' };
    case 'expired':
      return { color: 'warning', icon: 'mdi-clock-alert-outline', text: 'Expired' };
    case 'suspended':
      return { color: 'secondary', icon: 'mdi-pause-circle-outline', text: 'Suspended' };
    case 'revoked':
      return { color: 'error', icon: 'mdi-shield-alert', text: 'Revoked' };
    default:
      return { color: 'secondary', icon: 'mdi-help-circle-outline', text: props.status };
  }
});
</script>
