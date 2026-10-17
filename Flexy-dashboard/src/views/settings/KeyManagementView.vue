<template>
  <div class="key-management-view">
    <PageHeader
      title="Ed25519 Cryptographic Key Ring"
      subtitle="Public license verification key pairs, version lifecycle, and cryptographic key rotation."
      :breadcrumbs="[
        { title: 'Dashboard', to: '/dashboard' },
        { title: 'Settings', to: '/settings' },
        { title: 'Key Management' }
      ]"
    >
      <template #actions>
        <v-btn
          color="warning"
          variant="flat"
          prepend-icon="mdi-key-change"
          class="font-weight-bold"
          @click="showRotateModal = true"
        >
          Rotate Security Key
        </v-btn>
      </template>
    </PageHeader>

    <v-row>
      <!-- Navigation Sidebar -->
      <v-col cols="12" md="3">
        <v-card class="border pa-2">
          <v-list density="compact" nav>
            <v-list-item to="/settings" prepend-icon="mdi-tune" title="General Settings" />
            <v-list-item to="/settings/security/keys" prepend-icon="mdi-key-variant" title="Ed25519 Keys" active />
            <v-list-item to="/settings/users" prepend-icon="mdi-account-cog" title="Admin Users & Roles" />
          </v-list>
        </v-card>
      </v-col>

      <!-- Key Ring Table -->
      <v-col cols="12" md="9">
        <v-card class="pa-5 border">
          <div class="d-flex align-center justify-space-between mb-4">
            <div>
              <h3 class="text-subtitle-1 font-weight-bold">Active & Retired Key Versions</h3>
              <p class="text-caption text-medium-emphasis mb-0">Public keys used for license signature verification</p>
            </div>
            <v-chip color="success" size="small" variant="tonal">
              <v-icon start size="14">mdi-shield-lock</v-icon>
              Hardware Enclave Protected
            </v-chip>
          </div>

          <v-table hover density="comfortable">
            <thead>
              <tr class="bg-surface-variant">
                <th class="text-caption font-weight-bold text-uppercase">Key Version</th>
                <th class="text-caption font-weight-bold text-uppercase">Algorithm</th>
                <th class="text-caption font-weight-bold text-uppercase">Public Fingerprint</th>
                <th class="text-caption font-weight-bold text-uppercase">Active Licenses</th>
                <th class="text-caption font-weight-bold text-uppercase">Status</th>
                <th class="text-caption font-weight-bold text-uppercase">Rotation Date</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="key in keyVersions" :key="key.id">
                <td class="font-family-monospace font-weight-bold text-primary">
                  {{ key.keyId }}
                </td>
                <td>
                  <v-chip size="x-small" variant="outlined" color="primary">{{ key.algorithm }}</v-chip>
                </td>
                <td class="font-family-monospace text-caption text-truncate" style="max-width: 220px;">
                  {{ key.publicKeyFingerprint }}
                </td>
                <td class="font-weight-medium">
                  {{ key.activeLicensesCount }} / {{ key.totalLicensesIssued }}
                </td>
                <td>
                  <v-chip
                    :color="key.status === 'active' ? 'success' : 'secondary'"
                    size="x-small"
                    variant="tonal"
                    class="font-weight-bold text-capitalize"
                  >
                    {{ key.status }}
                  </v-chip>
                </td>
                <td class="text-caption text-medium-emphasis">
                  {{ key.rotationDate ? new Date(key.rotationDate).toLocaleDateString() : 'Active (No expiry)' }}
                </td>
              </tr>
            </tbody>
          </v-table>

          <!-- Security Policy Notice -->
          <v-alert
            color="info"
            variant="tonal"
            density="compact"
            icon="mdi-information-outline"
            class="mt-4 text-caption font-weight-medium"
          >
            Zero-Trust Architectural Guarantee: Private keys are never transmitted to or displayed in the browser. Rotation generates a new asymmetric key pair on the backend and retires prior versions gracefully without revoking valid unexpired client licenses.
          </v-alert>
        </v-card>
      </v-col>
    </v-row>

    <!-- Key Rotation Dialog -->
    <DangerConfirmDialog
      v-model="showRotateModal"
      title="Rotate Ed25519 Cryptographic Master Key"
      message="Rotating the master signing key will retire the current active key ring and establish a new key version for future license issuances."
      warning-text="Notice: Existing licenses will remain valid until their expiration, but new licenses will strictly require the new key ring."
      required-text="ROTATE"
      confirm-text="Rotate Master Key Now"
      :loading="rotating"
      @confirm="handleRotateKey"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useSettingsStore } from '@/stores/settings.store';
import { useNotificationStore } from '@/stores/notification.store';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import DangerConfirmDialog from '@/components/common/DangerConfirmDialog.vue';

const settingsStore = useSettingsStore();
const notificationStore = useNotificationStore();
const { keyVersions } = storeToRefs(settingsStore);

const showRotateModal = ref(false);
const rotating = ref(false);

onMounted(() => {
  settingsStore.fetchKeyVersions();
});

const handleRotateKey = async () => {
  rotating.value = true;
  try {
    const nextKeyId = `2026-${String(new Date().getMonth() + 2).padStart(2, '0')}`;
    await settingsStore.rotateKey(nextKeyId);
    notificationStore.showMessage(`Master key rotated. Active key is now ${nextKeyId}`, 'success');
    showRotateModal.value = false;
  } catch (err: any) {
    notificationStore.showMessage('Failed to rotate key', 'error');
  } finally {
    rotating.value = false;
  }
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
