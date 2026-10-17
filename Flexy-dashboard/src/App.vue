<template>
  <component :is="layoutComponent">
    <router-view />
  </component>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import AppLayout from '@/layouts/AppLayout.vue';
import AuthLayout from '@/layouts/AuthLayout.vue';

const route = useRoute();

const layoutComponent = computed(() => {
  if (route.meta.layout === 'auth') {
    return AuthLayout;
  }
  return AppLayout;
});
</script>

<style>
/* Global Typography and Design Baseline */
html, body {
  font-family: 'Plus Jakarta Sans', 'Tajawal', sans-serif !important;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

[dir="rtl"] {
  font-family: 'Tajawal', 'Plus Jakarta Sans', sans-serif !important;
}

.cursor-pointer {
  cursor: pointer;
}

.font-family-monospace {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace !important;
}
</style>
