<template>
  <div class="page-header mb-6">
    <!-- Breadcrumbs -->
    <v-breadcrumbs
      v-if="breadcrumbs && breadcrumbs.length"
      :items="breadcrumbs"
      density="compact"
      class="pa-0 mb-2"
    >
      <template #prepend>
        <v-icon size="16" class="me-1">mdi-home-outline</v-icon>
      </template>
      <template #divider>
        <v-icon size="14">mdi-chevron-right</v-icon>
      </template>
      <template #item="{ item }">
        <router-link
          v-if="item.to"
          :to="item.to"
          class="text-caption text-decoration-none text-medium-emphasis hover-primary"
        >
          {{ item.title }}
        </router-link>
        <span v-else class="text-caption font-weight-bold text-high-emphasis">
          {{ item.title }}
        </span>
      </template>
    </v-breadcrumbs>

    <!-- Title & Action buttons -->
    <div class="d-flex flex-wrap align-center justify-space-between ga-3">
      <div>
        <div class="d-flex align-center ga-3">
          <h1 class="text-h5 font-weight-bold tracking-tight text-high-emphasis mb-0">
            {{ title }}
          </h1>
          <slot name="badge" />
        </div>
        <p v-if="subtitle" class="text-body-2 text-medium-emphasis mt-1 mb-0">
          {{ subtitle }}
        </p>
      </div>

      <div class="d-flex align-center flex-wrap ga-2">
        <slot name="actions" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
export interface BreadcrumbItem {
  title: string;
  to?: string;
  disabled?: boolean;
}

defineProps<{
  title: string;
  subtitle?: string;
  breadcrumbs?: BreadcrumbItem[];
}>();
</script>

<style scoped>
.hover-primary:hover {
  color: rgb(var(--v-theme-primary)) !important;
}
</style>
