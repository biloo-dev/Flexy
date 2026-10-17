<template>
  <div class="error-state text-center py-10 px-4">
    <v-avatar color="error" variant="tonal" size="64" class="mb-4">
      <v-icon size="32">mdi-alert-circle-outline</v-icon>
    </v-avatar>
    <h3 class="text-h6 font-weight-bold text-error mb-1">
      {{ title }}
    </h3>
    <p class="text-body-2 text-medium-emphasis mx-auto mb-4" style="max-width: 420px;">
      {{ message || 'An error occurred while communicating with the service.' }}
    </p>
    <v-btn
      color="primary"
      variant="tonal"
      prepend-icon="mdi-refresh"
      @click="$emit('retry')"
    >
      Retry Request
    </v-btn>
  </div>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    title?: string;
    message?: string;
  }>(),
  {
    title: 'Unable to Load Data',
  }
);

defineEmits<{
  (e: 'retry'): void;
}>();
</script>
