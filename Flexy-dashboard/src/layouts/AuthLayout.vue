<template>
  <v-app class="auth-layout bg-background">
    <v-main class="d-flex align-center justify-center pa-4">
      <slot />
    </v-main>
  </v-app>
</template>

<script setup lang="ts">
</script>

<style scoped>
.auth-layout {
  min-height: 100vh;
  background: radial-gradient(circle at 50% 20%, rgba(37, 99, 235, 0.15), transparent 70%),
              radial-gradient(circle at 80% 80%, rgba(16, 185, 129, 0.1), transparent 60%);
}
</style>
