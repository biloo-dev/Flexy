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

const props = withDefaults(
  defineProps<{
    status: string;
    size?: 'x-small' | 'small' | 'default';
    variant?: 'flat' | 'tonal' | 'outlined';
  }>(),
  {
    size: 'small',
    variant: 'tonal',
  }
);

const chipConfig = computed(() => {
  switch (props.status?.toLowerCase()) {
    case 'active':
      return { color: 'success', icon: 'mdi-sim', text: 'Active' };
    case 'pending':
      return { color: 'warning', icon: 'mdi-sim-alert', text: 'Pending' };
    case 'suspended':
      return { color: 'warning', icon: 'mdi-pause-circle-outline', text: 'Suspended' };
    case 'blocked':
      return { color: 'error', icon: 'mdi-sim-off', text: 'Blocked' };
    case 'expired':
      return { color: 'secondary', icon: 'mdi-clock-alert-outline', text: 'Expired' };
    case 'revoked':
      return { color: 'error', icon: 'mdi-cancel', text: 'Revoked' };
    default:
      return { color: 'secondary', icon: 'mdi-sim', text: props.status };
  }
});
</script>
