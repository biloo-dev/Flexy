<template>
  <div class="license-detail-view">
    <!-- Header with Breadcrumbs -->
    <PageHeader
      :title="license ? `${license.id} - ${license.maskedSerial}` : 'License Details'"
      :subtitle="license ? `Customer: ${license.customerName} • Carrier: ${license.operator}` : ''"
      :breadcrumbs="[
        { title: 'Dashboard', to: '/dashboard' },
        { title: 'Licenses', to: '/licenses' },
        { title: license ? license.id : 'Detail' }
      ]"
    >
      <template #badge>
        <LicenseStatusChip v-if="license" :status="license.status" size="default" />
      </template>

      <template #actions>
        <v-btn
          color="secondary"
          variant="tonal"
          prepend-icon="mdi-refresh-circle"
          @click="regenerateSerial"
        >
          Regenerate Serial
        </v-btn>
        <v-btn
          color="primary"
          variant="tonal"
          prepend-icon="mdi-autorenew"
          @click="renewLicense"
        >
          Renew (1 Year)
        </v-btn>
        <v-btn
          v-if="license?.status === 'suspended'"
          color="success"
          variant="tonal"
          prepend-icon="mdi-play"
          @click="activateLicense"
        >
          Resume
        </v-btn>
        <v-btn
          v-if="license?.status === 'active'"
          color="warning"
          variant="tonal"
          prepend-icon="mdi-pause"
          @click="suspendLicense"
        >
          Suspend
        </v-btn>
        <v-btn
          v-if="license?.status !== 'revoked'"
          color="error"
          variant="tonal"
          prepend-icon="mdi-shield-alert"
          @click="showRevokeModal = true"
        >
          Revoke
        </v-btn>
        <v-btn
          color="error"
          variant="elevated"
          prepend-icon="mdi-delete"
          @click="showDeleteModal = true"
        >
          Delete
        </v-btn>
      </template>
    </PageHeader>

    <LoadingSkeleton v-if="loading && !license" type="card@3" />

    <ErrorState
      v-else-if="!license"
      title="License Not Found"
      message="The requested cryptographic license could not be found in the registry."
      @retry="loadLicense"
    />

    <template v-else>
      <!-- Telemetry Cards -->
      <v-row class="mb-4">
        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Ed25519 Signature Status</div>
            <div class="text-h6 font-weight-bold text-success mt-1 d-flex align-center ga-2">
              <v-icon size="22">mdi-shield-check</v-icon>
              <span>Cryptographically Valid</span>
            </div>
            <div class="text-caption text-medium-emphasis mt-2">Key: {{ license.keyId }} ({{ license.keyVersion }})</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Bound SIM Card</div>
            <div class="text-body-1 font-weight-bold font-family-monospace mt-1">
              <router-link :to="`/sim-cards/${license.simId}`" class="text-decoration-none text-primary">
                {{ license.simPhone }}
              </router-link>
            </div>
            <div class="text-caption text-medium-emphasis mt-2">{{ license.operator }} Network</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Host Gateway Device</div>
            <div class="text-body-1 font-weight-bold mt-1">
              <router-link :to="`/devices/${license.deviceId}`" class="text-decoration-none text-info">
                {{ license.deviceName }}
              </router-link>
            </div>
            <div class="text-caption text-medium-emphasis mt-2">ID: {{ license.deviceId }}</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Expiration Date</div>
            <div class="text-h6 font-weight-bold mt-1" :class="license.status === 'expired' ? 'text-error' : 'text-high-emphasis'">
              {{ new Date(license.expiresAt).toLocaleDateString() }}
            </div>
            <div class="text-caption text-medium-emphasis mt-2">Issued: {{ new Date(license.issuedAt).toLocaleDateString() }}</div>
          </v-card>
        </v-col>
      </v-row>

      <!-- Tabs -->
      <v-card class="border">
        <v-tabs v-model="tab" color="primary" class="border-b">
          <v-tab value="overview" prepend-icon="mdi-information-outline">Overview</v-tab>
          <v-tab value="serial" prepend-icon="mdi-key-variant">Serial & Cryptography</v-tab>
          <v-tab value="payment" prepend-icon="mdi-cash-multiple">Payment</v-tab>
          <v-tab value="activations" prepend-icon="mdi-shield-check-outline">Activations</v-tab>
          <v-tab value="events" prepend-icon="mdi-shield-alert-outline">Security Events</v-tab>
          <v-tab value="audit" prepend-icon="mdi-file-document-outline">Audit</v-tab>
        </v-tabs>

        <v-card-text class="pa-4">
          <v-window v-model="tab">
            <!-- 1. Overview -->
            <v-window-item value="overview">
              <v-row>
                <v-col cols="12" md="6">
                  <v-card variant="outlined" class="pa-4">
                    <h4 class="text-subtitle-2 font-weight-bold mb-3">License Metadata</h4>
                    <v-list density="compact" class="pa-0">
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">License ID:</span></template>
                        <span class="text-body-2 font-weight-bold font-family-monospace">{{ license.id }}</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Customer:</span></template>
                        <router-link :to="`/customers/${license.customerId}`" class="text-body-2 text-decoration-none font-weight-bold text-primary">
                          {{ license.customerName }}
                        </router-link>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Algorithm:</span></template>
                        <v-chip size="x-small" color="primary" variant="tonal">{{ license.algorithm }}</v-chip>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Key Version:</span></template>
                        <span class="text-body-2 font-family-monospace">{{ license.keyId }} ({{ license.keyVersion }})</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Annual Fee:</span></template>
                        <span class="text-body-2 font-weight-bold">{{ license.price?.toLocaleString() }} DZD</span>
                      </v-list-item>
                      <v-list-item v-if="license.revocationReason" class="px-0">
                        <template #prepend><span class="text-caption text-error me-4" style="min-width: 120px;">Revocation Reason:</span></template>
                        <span class="text-caption text-error font-weight-bold">{{ license.revocationReason }}</span>
                      </v-list-item>
                    </v-list>
                  </v-card>
                </v-col>

                <v-col cols="12" md="6">
                  <v-card variant="outlined" class="pa-4">
                    <h4 class="text-subtitle-2 font-weight-bold mb-3">Enforcement Policies</h4>
                    <div class="pa-3 rounded bg-surface-variant mb-2">
                      <div class="d-flex align-center ga-2 text-body-2 font-weight-bold text-success mb-1">
                        <v-icon size="16">mdi-check-circle</v-icon>
                        Hardware Lock Enforced
                      </div>
                      <div class="text-caption text-medium-emphasis">
                        License is bound to Device UUID {{ license.deviceId }} and cannot be transferred without admin key re-signing.
                      </div>
                    </div>

                    <div class="pa-3 rounded bg-surface-variant">
                      <div class="d-flex align-center ga-2 text-body-2 font-weight-bold text-success mb-1">
                        <v-icon size="16">mdi-check-circle</v-icon>
                        ICCID Matching Mandatory
                      </div>
                      <div class="text-caption text-medium-emphasis">
                        All USSD transmissions require modem port ICCID verification against SIM {{ license.simPhone }}.
                      </div>
                    </div>
                  </v-card>
                </v-col>
              </v-row>
            </v-window-item>

            <!-- 2. Serial & Cryptography Viewer (SECURITY CRITICAL: NEVER EXPOSES PRIVATE KEYS) -->
            <v-window-item value="serial">
              <v-card variant="outlined" class="pa-5">
                <div class="d-flex align-center justify-space-between mb-4">
                  <div>
                    <h4 class="text-subtitle-1 font-weight-bold">Ed25519 Public License Payload</h4>
                    <p class="text-caption text-medium-emphasis mb-0">Client authorization token for daemon activation</p>
                  </div>
                  <v-chip color="success" size="small" variant="tonal">
                    <v-icon start size="14">mdi-lock-check</v-icon>
                    Asymmetric Verification Ready
                  </v-chip>
                </div>

                <!-- Serial Box -->
                <div class="pa-4 rounded-lg bg-surface-variant border mb-4">
                  <div class="text-caption text-medium-emphasis mb-1 font-weight-bold">FULL LICENSE SERIAL</div>
                  <div class="d-flex align-center justify-space-between ga-2">
                    <span class="text-body-1 font-family-monospace font-weight-bold text-high-emphasis">
                      {{ license.serialNumber }}
                    </span>
                    <CopyButton :text="license.serialNumber" tooltip="Copy Serial Key" />
                  </div>
                </div>

                <!-- Public Key & Cryptographic Info -->
                <v-row dense>
                  <v-col cols="12" md="6">
                    <div class="text-caption text-medium-emphasis">Signing Algorithm</div>
                    <div class="text-body-2 font-weight-bold font-family-monospace">Ed25519 (RFC 8032)</div>
                  </v-col>
                  <v-col cols="12" md="6">
                    <div class="text-caption text-medium-emphasis">Public Key Ring Version</div>
                    <div class="text-body-2 font-weight-bold font-family-monospace">KEY-{{ license.keyId }}</div>
                  </v-col>
                </v-row>

                <!-- Security Guarantee Alert -->
                <v-alert
                  color="info"
                  variant="tonal"
                  density="compact"
                  icon="mdi-shield-lock-outline"
                  class="mt-4 text-caption font-weight-medium"
                >
                  Notice: Private signing keys are stored exclusively in the secure NestJS Key Enclave. The dashboard never retrieves, caches, or exposes private keys.
                </v-alert>
              </v-card>
            </v-window-item>

            <!-- 3. Payment -->
            <v-window-item value="payment">
              <v-card variant="outlined" class="pa-4">
                <div class="d-flex align-center justify-space-between mb-3">
                  <span class="text-subtitle-2 font-weight-bold">Payment Status</span>
                  <StatusChip :status="license.paymentStatus" />
                </div>
                <div class="text-body-2 mb-1">Fee: <strong>{{ license.price.toLocaleString() }} DZD</strong></div>
                <div class="text-caption text-medium-emphasis">Payment Reference: {{ license.paymentId || 'PAY-401' }}</div>
              </v-card>
            </v-window-item>

            <!-- 4. Activations -->
            <v-window-item value="activations">
              <v-list lines="two">
                <v-list-item
                  v-for="act in licenseActivations"
                  :key="act.id"
                  class="border rounded-lg mb-2"
                >
                  <template #prepend>
                    <v-avatar :color="act.result === 'success' ? 'success' : 'error'" variant="tonal" size="36" class="me-3">
                      <v-icon size="20">{{ act.result === 'success' ? 'mdi-shield-check' : 'mdi-shield-alert' }}</v-icon>
                    </v-avatar>
                  </template>
                  <v-list-item-title class="font-weight-bold">
                    Activation {{ act.result === 'success' ? 'Succeeded' : 'Failed: ' + act.failureReason }}
                  </v-list-item-title>
                  <v-list-item-subtitle class="text-caption">
                    IP: {{ act.clientIp }} • Signature: {{ act.signatureVerified ? 'Verified' : 'Invalid' }} • {{ new Date(act.timestamp).toLocaleString() }}
                  </v-list-item-subtitle>
                </v-list-item>
              </v-list>
            </v-window-item>

            <!-- 5. Events -->
            <v-window-item value="events">
              <v-list lines="two">
                <v-list-item
                  v-for="ev in licenseEvents"
                  :key="ev.id"
                  class="border rounded-lg mb-2"
                >
                  <template #prepend>
                    <v-avatar :color="ev.severity === 'critical' ? 'error' : 'warning'" variant="tonal" size="36" class="me-3">
                      <v-icon size="20">mdi-alert-circle</v-icon>
                    </v-avatar>
                  </template>
                  <v-list-item-title class="font-weight-bold">{{ ev.title }}</v-list-item-title>
                  <v-list-item-subtitle class="text-caption">{{ ev.description }}</v-list-item-subtitle>
                </v-list-item>
              </v-list>
            </v-window-item>

            <!-- 6. Audit -->
            <v-window-item value="audit">
              <div class="text-caption text-medium-emphasis">
                Immutable audit history for License {{ license.id }}.
              </div>
            </v-window-item>
          </v-window>
        </v-card-text>
      </v-card>

      <!-- Danger Revoke Dialog -->
      <DangerConfirmDialog
        v-model="showRevokeModal"
        title="Revoke License"
        :message="`Revoking license ${license.id} will immediately block SIM ${license.simPhone} from executing operations.`"
        required-text="REVOKE"
        confirm-text="Revoke License Now"
        :loading="revoking"
        @confirm="confirmRevoke"
      />

      <!-- Danger Delete Dialog -->
      <DangerConfirmDialog
        v-model="showDeleteModal"
        title="Delete License Permanently"
        :message="`Are you sure you want to permanently delete license ${license.id}?`"
        warning-text="This will completely remove this license record from the database."
        required-text="DELETE"
        confirm-text="Permanently Delete License"
        :loading="deleting"
        @confirm="confirmDelete"
      />
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useLicenseStore } from '@/stores/license.store';
import { useNotificationStore } from '@/stores/notification.store';
import { storeToRefs } from 'pinia';
import { mockActivations, mockSecurityEvents } from '@/api/mock/mockData';
import PageHeader from '@/components/common/PageHeader.vue';
import LicenseStatusChip from '@/components/common/LicenseStatusChip.vue';
import StatusChip from '@/components/common/StatusChip.vue';
import CopyButton from '@/components/common/CopyButton.vue';
import LoadingSkeleton from '@/components/common/LoadingSkeleton.vue';
import ErrorState from '@/components/common/ErrorState.vue';
import DangerConfirmDialog from '@/components/common/DangerConfirmDialog.vue';

const route = useRoute();
const router = useRouter();
const licenseStore = useLicenseStore();
const notificationStore = useNotificationStore();

const { currentLicense: license, loading } = storeToRefs(licenseStore);
const tab = ref('overview');
const showRevokeModal = ref(false);
const showDeleteModal = ref(false);
const revoking = ref(false);
const deleting = ref(false);

const licenseId = computed(() => route.params.id as string);

const licenseActivations = computed(() => mockActivations.filter((a) => a.licenseId === licenseId.value));
const licenseEvents = computed(() => mockSecurityEvents.filter((e) => e.licenseId === licenseId.value));

const loadLicense = () => {
  if (licenseId.value) {
    licenseStore.fetchLicenseById(licenseId.value);
  }
};

onMounted(loadLicense);

const regenerateSerial = async () => {
  if (!license.value) return;
  try {
    const updated = await licenseStore.regenerateSerial(license.value.id);
    notificationStore.showMessage('New Ed25519 serial key re-issued successfully', 'success');
    if (updated?.serialNumber) {
      navigator.clipboard.writeText(updated.serialNumber);
      notificationStore.showMessage('New serial copied to clipboard!', 'info');
    }
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to regenerate serial', 'error');
  }
};

const renewLicense = async () => {
  if (!license.value) return;
  try {
    await licenseStore.renewLicense(license.value.id, 12);
    notificationStore.showMessage('License renewed for 12 months', 'success');
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to renew license', 'error');
  }
};

const activateLicense = async () => {
  if (!license.value) return;
  try {
    await licenseStore.activateLicense(license.value.id);
    notificationStore.showMessage('License resumed', 'success');
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to resume license', 'error');
  }
};

const suspendLicense = async () => {
  if (!license.value) return;
  try {
    await licenseStore.suspendLicense(license.value.id);
    notificationStore.showMessage('License suspended', 'warning');
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to suspend license', 'error');
  }
};

const confirmRevoke = async () => {
  if (!license.value) return;
  revoking.value = true;
  try {
    await licenseStore.revokeLicense(license.value.id, 'Administrative revocation from Control Center');
    notificationStore.showMessage(`License ${license.value.id} REVOKED`, 'error');
    showRevokeModal.value = false;
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to revoke license', 'error');
  } finally {
    revoking.value = false;
  }
};

const confirmDelete = async () => {
  if (!license.value) return;
  deleting.value = true;
  try {
    await licenseStore.deleteLicense(license.value.id);
    notificationStore.showMessage(`License ${license.value.id} permanently deleted`, 'success');
    showDeleteModal.value = false;
    router.push('/licenses');
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to delete license', 'error');
  } finally {
    deleting.value = false;
  }
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
