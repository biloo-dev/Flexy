<template>
  <div class="loading-skeleton pa-4">
    <v-skeleton-loader
      :type="type"
      class="bg-transparent"
    ></v-skeleton-loader>
  </div>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    type?: string;
  }>(),
  {
    type: 'table-row-divider@5',
  }
);
</script>
