<template>
  <v-avatar
    :color="avatarColor"
    :size="size"
    :rounded="rounded"
    class="font-weight-bold"
    :variant="variant"
  >
    <v-img v-if="image" :src="image" :alt="name" />
    <span v-else class="text-caption font-weight-bold">{{ initials }}</span>
  </v-avatar>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = withDefaults(
  defineProps<{
    name: string;
    image?: string;
    size?: number | string;
    rounded?: string | boolean;
    variant?: 'flat' | 'tonal' | 'elevated';
  }>(),
  {
    size: 36,
    rounded: 'md',
    variant: 'tonal',
  }
);

const initials = computed(() => {
  if (!props.name) return '??';
  const parts = props.name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
});

const avatarColor = computed(() => {
  const colors = ['primary', 'secondary', 'success', 'warning', 'info', 'accent'];
  let hash = 0;
  for (let i = 0; i < props.name.length; i++) {
    hash = props.name.charCodeAt(i) + ((hash << 5) - hash);
  }
  const index = Math.abs(hash) % colors.length;
  return colors[index];
});
</script>
