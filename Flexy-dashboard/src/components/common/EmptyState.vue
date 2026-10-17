<template>
  <div class="empty-state text-center py-10 px-4">
    <v-avatar :color="color" variant="tonal" size="64" class="mb-4">
      <v-icon :size="32">{{ icon }}</v-icon>
    </v-avatar>
    <h3 class="text-h6 font-weight-bold text-high-emphasis mb-1">
      {{ title }}
    </h3>
    <p v-if="description" class="text-body-2 text-medium-emphasis mx-auto mb-4" style="max-width: 420px;">
      {{ description }}
    </p>
    <div v-if="$slots.actions || actionText">
      <slot name="actions">
        <v-btn
          v-if="actionText"
          color="primary"
          :prepend-icon="actionIcon"
          @click="$emit('action')"
        >
          {{ actionText }}
        </v-btn>
      </slot>
    </div>
  </div>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    icon?: string;
    color?: string;
    title?: string;
    description?: string;
    actionText?: string;
    actionIcon?: string;
  }>(),
  {
    icon: 'mdi-database-search-outline',
    color: 'primary',
    title: 'No records found',
    description: 'There is no data matching your current filters or query.',
  }
);

defineEmits<{
  (e: 'action'): void;
}>();
</script>
