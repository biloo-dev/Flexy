<template>
  <v-card width="440" class="pa-6 pa-sm-8 border" elevation="2">
    <!-- Brand Logo & Header -->
    <div class="text-center mb-6">
      <v-avatar color="primary" size="52" rounded="lg" class="mb-3">
        <v-icon color="white" size="28">mdi-lightning-bolt</v-icon>
      </v-avatar>
      <h2 class="text-h5 font-weight-black text-primary">FLEXY PLATFORM</h2>
      <p class="text-caption text-medium-emphasis mt-1">
        Enterprise License & Telecom Operations Control Center
      </p>
    </div>

    <!-- Error Alert -->
    <v-alert
      v-if="error"
      type="error"
      variant="tonal"
      density="compact"
      class="mb-4 text-caption"
      closable
      @click:close="error = null"
    >
      {{ error }}
    </v-alert>

    <!-- Login Form -->
    <v-form @submit.prevent="handleLogin">
      <div class="mb-4">
        <label class="text-caption font-weight-bold d-block mb-1">Admin Email Address</label>
        <v-text-field
          v-model="email"
          prepend-inner-icon="mdi-email-outline"
          placeholder="admin@flexi-platform.dz"
          type="email"
          required
        />
      </div>

      <div class="mb-5">
        <div class="d-flex align-center justify-space-between mb-1">
          <label class="text-caption font-weight-bold">Password</label>
          <span class="text-caption text-primary cursor-pointer">Forgot?</span>
        </div>
        <v-text-field
          v-model="password"
          prepend-inner-icon="mdi-lock-outline"
          :append-inner-icon="showPassword ? 'mdi-eye-off-outline' : 'mdi-eye-outline'"
          :type="showPassword ? 'text' : 'password'"
          placeholder="••••••••••••"
          required
          @click:append-inner="showPassword = !showPassword"
        />
      </div>

      <v-btn
        block
        color="primary"
        size="large"
        type="submit"
        :loading="loading"
        class="font-weight-bold mb-4"
      >
        Sign In to Control Center
      </v-btn>
    </v-form>

    <!-- Demo Fast Login Picker -->
    <div class="border-t pt-4 mt-2">
      <div class="text-caption text-medium-emphasis mb-2 text-center font-weight-medium">
        Quick Demo Profiles:
      </div>
      <div class="d-flex flex-wrap ga-2 justify-center">
        <v-chip
          size="small"
          variant="outlined"
          color="primary"
          @click="selectDemo('admin@flexi.dz')"
        >
          Super Admin (Live Backend)
        </v-chip>
        <v-chip
          size="small"
          variant="outlined"
          color="info"
          @click="selectDemo('support@flexi-platform.dz')"
        >
          Support
        </v-chip>
        <v-chip
          size="small"
          variant="outlined"
          color="success"
          @click="selectDemo('finance@flexi-platform.dz')"
        >
          Finance
        </v-chip>
      </div>
    </div>
  </v-card>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth.store';

const router = useRouter();
const authStore = useAuthStore();

const email = ref('admin@flexi.dz');
const password = ref('AdminFlexi2026!');
const showPassword = ref(false);
const loading = ref(false);
const error = ref<string | null>(null);

const selectDemo = (demoEmail: string) => {
  email.value = demoEmail;
  password.value = demoEmail === 'admin@flexi.dz' ? 'AdminFlexi2026!' : 'password123';
};

const handleLogin = async () => {
  loading.value = true;
  error.value = null;
  try {
    await authStore.login({ email: email.value, password: password.value });
    router.push('/dashboard');
  } catch (err: any) {
    error.value = err.message || 'Login failed. Please verify your credentials.';
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.cursor-pointer {
  cursor: pointer;
}
</style>
