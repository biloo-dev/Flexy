<template>
  <div class="filter-bar d-flex flex-wrap align-center justify-space-between ga-3 mb-4">
    <div class="d-flex flex-wrap align-center ga-2 flex-grow-1" style="max-width: 800px;">
      <slot name="search" />
      <slot name="filters" />
    </div>

    <div class="d-flex align-center ga-2 ms-auto">
      <slot name="actions" />
      <v-btn
        v-if="showExport"
        variant="outlined"
        density="comfortable"
        prepend-icon="mdi-download"
        class="text-caption font-weight-bold"
        @click="$emit('export')"
      >
        Export CSV
      </v-btn>
      <v-btn
        v-if="showRefresh"
        icon
        size="small"
        variant="text"
        density="comfortable"
        color="secondary"
        @click="$emit('refresh')"
      >
        <v-icon size="18">mdi-refresh</v-icon>
      </v-btn>
    </div>
  </div>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    showExport?: boolean;
    showRefresh?: boolean;
  }>(),
  {
    showExport: true,
    showRefresh: true,
  }
);

defineEmits<{
  (e: 'export'): void;
  (e: 'refresh'): void;
}>();
</script>
