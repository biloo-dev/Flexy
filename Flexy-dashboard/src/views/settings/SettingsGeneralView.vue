<template>
  <div class="settings-general-view">
    <PageHeader
      title="Platform Settings & Configuration"
      subtitle="Configure enterprise parameters, system timeouts, operator defaults, and daemon policies."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Settings' }]"
    />

    <v-row>
      <v-col cols="12" md="3">
        <v-card class="border pa-2">
          <v-list density="compact" nav>
            <v-list-item to="/settings" prepend-icon="mdi-tune" title="General Settings" active />
            <v-list-item to="/settings/security/keys" prepend-icon="mdi-key-variant" title="Ed25519 Keys" />
            <v-list-item to="/settings/users" prepend-icon="mdi-account-cog" title="Admin Users & Roles" />
          </v-list>
        </v-card>
      </v-col>

      <v-col cols="12" md="9">
        <v-card class="pa-5 border">
          <h3 class="text-subtitle-1 font-weight-bold mb-4">General Platform Configuration</h3>

          <v-form @submit.prevent="saveSettings">
            <v-row>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="config.platformName"
                  label="Platform Title"
                  variant="outlined"
                  class="mb-3"
                />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="config.defaultCurrency"
                  label="Default Settlement Currency"
                  variant="outlined"
                  class="mb-3"
                />
              </v-col>
            </v-row>

            <v-divider class="my-4" />

            <h4 class="text-subtitle-2 font-weight-bold mb-3">Daemon & Hardware Policies</h4>
            <v-row>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="config.heartbeatIntervalSeconds"
                  label="Heartbeat Timeout (Seconds)"
                  type="number"
                  variant="outlined"
                  class="mb-3"
                />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="config.maxFailedAttemptsBeforeLock"
                  label="Failed Activations Lock Threshold"
                  type="number"
                  variant="outlined"
                  class="mb-3"
                />
              </v-col>
            </v-row>

            <v-switch
              v-model="config.autoBlockOnIccidMismatch"
              color="error"
              label="Automatically block SIM on hardware ICCID mismatch"
              hide-details
              class="mb-2"
            />

            <v-switch
              v-model="config.enforceIdempotencyKeys"
              color="primary"
              label="Enforce strict idempotency validation on all Flexi transactions"
              hide-details
              class="mb-4"
            />

            <v-btn color="primary" type="submit" class="font-weight-bold">
              Save Configuration
            </v-btn>
          </v-form>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useNotificationStore } from '@/stores/notification.store';
import PageHeader from '@/components/common/PageHeader.vue';

const notificationStore = useNotificationStore();

const config = ref({
  platformName: 'FLEXY License Management Platform',
  defaultCurrency: 'DZD (Algerian Dinar)',
  heartbeatIntervalSeconds: 15,
  maxFailedAttemptsBeforeLock: 5,
  autoBlockOnIccidMismatch: true,
  enforceIdempotencyKeys: true,
});

const saveSettings = () => {
  notificationStore.showMessage('Platform configuration saved successfully', 'success');
};
</script>
