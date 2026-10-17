<template>
  <div class="sim-detail-view">
    <!-- Header with Breadcrumbs -->
    <PageHeader
      :title="sim ? `${sim.operator} - ${sim.phoneNumber}` : 'SIM Card Details'"
      :subtitle="sim ? `Customer: ${sim.customerName} • Bound Device: ${sim.boundDeviceName || 'None'}` : ''"
      :breadcrumbs="[
        { title: 'Dashboard', to: '/dashboard' },
        { title: 'SIM Cards', to: '/sim-cards' },
        { title: sim ? sim.phoneNumber : 'Detail' }
      ]"
    >
      <template #badge>
        <SimStatusChip v-if="sim" :status="sim.status" size="default" />
      </template>

      <template #actions>
        <v-btn
          color="info"
          variant="tonal"
          prepend-icon="mdi-account-switch"
          class="me-2"
          @click="openTransferModal"
        >
          Transférer la SIM (Changer de Client)
        </v-btn>
        <v-btn
          v-if="sim?.status === 'blocked'"
          color="success"
          variant="tonal"
          prepend-icon="mdi-check"
          @click="activateSim"
        >
          Unblock SIM
        </v-btn>
        <v-btn
          v-else-if="sim?.status === 'active'"
          color="error"
          variant="tonal"
          prepend-icon="mdi-sim-off"
          @click="showBlockModal = true"
        >
          Block SIM
        </v-btn>
      </template>
    </PageHeader>

    <LoadingSkeleton v-if="loading && !sim" type="card@3" />

    <ErrorState
      v-else-if="!sim"
      title="SIM Card Not Found"
      message="The requested SIM Card record does not exist or has been decommissioned."
      @retry="loadSim"
    />

    <template v-else>
      <!-- Top Cards -->
      <v-row class="mb-4">
        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Operator & Network</div>
            <div class="text-h6 font-weight-bold d-flex align-center ga-2 mt-1">
              <v-icon :color="sim.operator === 'MOBILIS' ? 'success' : sim.operator === 'DJEZZY' ? 'error' : 'accent'">
                mdi-cellphone-tower
              </v-icon>
              {{ sim.operator }}
            </div>
            <div class="text-caption text-medium-emphasis mt-2">Active Carrier Route</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">ICCID Masked & Protected</div>
            <div class="text-body-1 font-weight-bold font-family-monospace mt-1">
              <MaskedValue :raw-value="sim.iccid" />
            </div>
            <div class="text-caption text-medium-emphasis mt-2">Last 4: {{ sim.iccid.slice(-4) }}</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Current SIM Balance</div>
            <div class="text-h6 font-weight-bold text-success mt-1">
              {{ sim.currentBalance?.toLocaleString() || 0 }} DZD
            </div>
            <div class="text-caption text-medium-emphasis mt-2">Available for Flexi recharge</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">License Binding</div>
            <div class="text-h6 font-weight-bold text-primary mt-1">
              <router-link v-if="realLicense" :to="`/licenses/${realLicense.id}`" class="text-decoration-none text-primary">
                {{ realLicense.id }}
              </router-link>
              <span v-else class="text-medium-emphasis">Unlicensed</span>
            </div>
            <div class="text-caption text-medium-emphasis mt-2">Ed25519 Cryptographic Pair</div>
          </v-card>
        </v-col>
      </v-row>

      <!-- Tabs -->
      <v-card class="border">
        <v-tabs v-model="tab" color="primary" class="border-b">
          <v-tab value="overview" prepend-icon="mdi-information-outline">Overview</v-tab>
          <v-tab value="hardware" prepend-icon="mdi-router-wireless">Modem & Device</v-tab>
          <v-tab value="license" prepend-icon="mdi-key-chain">License</v-tab>
          <v-tab value="operations" prepend-icon="mdi-swap-horizontal-bold">Operations</v-tab>
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
                    <h4 class="text-subtitle-2 font-weight-bold mb-3">SIM Identifiers & Security</h4>
                    <v-list density="compact" class="pa-0">
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">SIM ID:</span></template>
                        <span class="text-body-2 font-weight-bold font-family-monospace">{{ sim.id }}</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Phone Number:</span></template>
                        <span class="text-body-2 font-family-monospace font-weight-bold">{{ sim.phoneNumber }}</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">ICCID Hash (SHA256):</span></template>
                        <span class="text-caption font-family-monospace text-truncate" style="max-width: 260px;">{{ sim.iccidHash }}</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Customer:</span></template>
                        <router-link :to="`/customers/${sim.customerId}`" class="text-body-2 text-decoration-none font-weight-bold text-primary">
                          {{ sim.customerName }}
                        </router-link>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Activated On:</span></template>
                        <span class="text-body-2">{{ sim.activatedAt ? new Date(sim.activatedAt).toLocaleString() : 'N/A' }}</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 120px;">Expires On:</span></template>
                        <span class="text-body-2">{{ sim.expiresAt ? new Date(sim.expiresAt).toLocaleString() : 'N/A' }}</span>
                      </v-list-item>
                    </v-list>
                  </v-card>
                </v-col>

                <v-col cols="12" md="6">
                  <v-card variant="outlined" class="pa-4">
                    <h4 class="text-subtitle-2 font-weight-bold mb-3">Hardware Binding Verification</h4>
                    <div class="pa-3 rounded mb-3 bg-surface-variant d-flex align-center justify-space-between">
                      <div>
                        <div class="text-caption text-medium-emphasis">Bound Modem IMEI</div>
                        <div class="text-body-2 font-weight-bold font-family-monospace">
                          {{ sim.boundModemImei || 'Not bound to specific modem' }}
                        </div>
                      </div>
                      <v-chip size="x-small" :color="sim.boundModemId ? 'success' : 'warning'" variant="tonal">
                        {{ sim.boundModemId ? 'Matched' : 'Unbound' }}
                      </v-chip>
                    </div>

                    <div class="pa-3 rounded bg-surface-variant d-flex align-center justify-space-between">
                      <div>
                        <div class="text-caption text-medium-emphasis">Bound Hardware Host</div>
                        <div class="text-body-2 font-weight-bold">{{ sim.boundDeviceName || 'Unbound' }}</div>
                      </div>
                      <v-chip size="x-small" :color="sim.boundDeviceId ? 'success' : 'warning'" variant="tonal">
                        {{ sim.boundDeviceId ? 'Linked' : 'Unbound' }}
                      </v-chip>
                    </div>
                  </v-card>
                </v-col>
              </v-row>
            </v-window-item>

            <!-- 2. Hardware (Modem & Device) -->
            <v-window-item value="hardware">
              <v-row>
                <v-col cols="12" md="6">
                  <v-card variant="outlined" class="pa-4">
                    <h4 class="text-subtitle-2 font-weight-bold mb-3">Modem Details</h4>
                    <div v-if="sim.boundModemImei || sim.boundModemId">
                      <div class="text-caption text-medium-emphasis mb-1">IMEI: {{ sim.boundModemImei || 'Auto-detected on activation' }}</div>
                      <div class="text-caption text-medium-emphasis mb-1">Modem ID: {{ sim.boundModemId || 'N/A' }}</div>
                      <div class="text-caption text-medium-emphasis mb-1">Carrier: {{ sim.operator }}</div>
                    </div>
                    <div v-else class="text-caption text-medium-emphasis">No specific modem locked to this SIM (Dynamic modem binding).</div>
                  </v-card>
                </v-col>

                <v-col cols="12" md="6">
                  <v-card variant="outlined" class="pa-4">
                    <h4 class="text-subtitle-2 font-weight-bold mb-3">Device Host</h4>
                    <div v-if="sim.boundDeviceId || sim.boundDeviceName">
                      <div class="text-caption text-medium-emphasis mb-1">Device: {{ sim.boundDeviceName || 'Customer PC' }}</div>
                      <div class="text-caption text-medium-emphasis mb-1">Device ID: {{ sim.boundDeviceId || 'N/A' }}</div>
                    </div>
                    <div v-else class="text-caption text-medium-emphasis">Any authorized customer PC with valid Ed25519 license.</div>
                  </v-card>
                </v-col>
              </v-row>
            </v-window-item>

            <!-- 3. License -->
            <v-window-item value="license">
              <v-card variant="outlined" class="pa-4">
                <div v-if="realLicense">
                  <div class="d-flex align-center justify-space-between mb-3">
                    <div>
                      <h4 class="text-subtitle-1 font-weight-bold font-family-monospace text-primary">
                        {{ realLicense.id }}
                      </h4>
                      <div class="text-caption text-medium-emphasis">
                        Customer: {{ realLicense.customerName || sim.customerId }}
                      </div>
                    </div>
                    <LicenseStatusChip :status="realLicense.status" />
                  </div>

                  <!-- Real Serial Code Box with Copy Button -->
                  <div class="pa-3 rounded bg-surface-variant border mb-3">
                    <div class="d-flex align-center justify-space-between mb-1">
                      <span class="text-caption text-medium-emphasis font-weight-bold">Serial Code (Ed25519 Token):</span>
                      <v-btn
                        size="x-small"
                        color="primary"
                        variant="tonal"
                        prepend-icon="mdi-content-copy"
                        @click="copySerial(realLicense.serialNumber)"
                      >
                        Copy Full Serial
                      </v-btn>
                    </div>
                    <div class="text-caption font-family-monospace text-wrap" style="word-break: break-all;">
                      {{ realLicense.serialNumber || realLicense.maskedSerial }}
                    </div>
                  </div>

                  <div class="text-caption text-medium-emphasis mb-1">
                    Cryptographic Algorithm: {{ realLicense.algorithm || 'Ed25519' }} (Key ID: {{ realLicense.keyId || '2026-01' }})
                  </div>
                  <div class="text-caption text-medium-emphasis mb-3">
                    Expires: {{ realLicense.expiresAt ? new Date(realLicense.expiresAt).toLocaleDateString() : 'N/A' }}
                  </div>

                  <div class="d-flex ga-2">
                    <v-btn color="primary" variant="tonal" size="small" :to="`/licenses/${realLicense.id}`">
                      Inspect Full License & Keys
                    </v-btn>
                  </div>
                </div>
                <div v-else class="text-caption text-medium-emphasis py-4 text-center">
                  <v-icon size="32" class="mb-2 text-medium-emphasis">mdi-key-remove</v-icon>
                  <div>No active license linked to this SIM card.</div>
                  <div class="text-caption mt-1">Generate a license from the Customer Details page.</div>
                </div>
              </v-card>
            </v-window-item>

            <!-- 4. Operations -->
            <v-window-item value="operations">
              <div class="text-caption text-medium-emphasis py-4 text-center">
                <v-icon size="32" class="mb-2 text-medium-emphasis">mdi-swap-horizontal-bold</v-icon>
                <div>No recorded flexi transactions for this SIM card yet.</div>
              </div>
            </v-window-item>

            <!-- 5. Security Events -->
            <v-window-item value="events">
              <div class="text-caption text-medium-emphasis py-4 text-center">
                <v-icon size="32" class="mb-2 text-medium-emphasis">mdi-shield-check</v-icon>
                <div>No security events or anomalies recorded for this SIM card.</div>
              </div>
            </v-window-item>

            <!-- 6. Audit -->
            <v-window-item value="audit">
              <div class="text-caption text-medium-emphasis">
                Showing immutable change log for SIM record {{ sim.id }}.
              </div>
              <v-timeline density="compact" align="start" class="mt-4">
                <v-timeline-item dot-color="success" size="x-small">
                  <div class="text-caption font-weight-bold">SIM Registered</div>
                  <div class="text-caption text-medium-emphasis">Status: {{ sim.status }} • Carrier: {{ sim.operator }}</div>
                </v-timeline-item>
                <v-timeline-item v-if="realLicense" dot-color="primary" size="x-small">
                  <div class="text-caption font-weight-bold">License Associated</div>
                  <div class="text-caption text-medium-emphasis">Ed25519 License {{ realLicense.id }}</div>
                </v-timeline-item>
              </v-timeline>
            </v-window-item>
          </v-window>
        </v-card-text>
      </v-card>

      <!-- Danger Block Dialog -->
      <DangerConfirmDialog
        v-model="showBlockModal"
        title="Block SIM Card"
        :message="`Are you sure you want to block SIM ${sim.phoneNumber}?`"
        warning-text="This SIM will immediately be forbidden from performing any Flexi transactions."
        confirm-text="Confirm Block"
        :loading="blocking"
        @confirm="confirmBlock"
      />

      <!-- Transfer Ownership Dialog -->
      <v-dialog v-model="showTransferModal" max-width="520" persistent>
        <v-card class="border">
          <v-card-item class="border-b py-3 bg-surface-variant">
            <template #prepend>
              <v-avatar color="info" variant="tonal" size="36">
                <v-icon icon="mdi-account-switch" size="20" />
              </v-avatar>
            </template>
            <v-card-title class="text-subtitle-1 font-weight-bold">
              Transférer la carte SIM (Changement de Propriétaire)
            </v-card-title>
          </v-card-item>

          <v-card-text class="pa-4">
            <v-alert
              type="warning"
              variant="tonal"
              density="compact"
              class="mb-4"
              icon="mdi-shield-alert-outline"
            >
              <div class="text-caption">
                <strong>Attention :</strong> Le transfert de la puce <strong>{{ sim.phoneNumber }}</strong> va immédiatement <strong>révoquer</strong> les licences liées à l'ancien client ({{ sim.customerName }}) et permettra au nouveau client d'activer la puce.
              </div>
            </v-alert>

            <div class="text-caption text-medium-emphasis mb-2">Sélectionnez le nouveau client bénéficiaire :</div>
            <v-select
              v-model="selectedNewCustomerId"
              :items="customerOptions"
              item-title="title"
              item-value="id"
              label="Nouveau Client *"
              placeholder="Choisir un client..."
              variant="outlined"
              density="comfortable"
              prepend-inner-icon="mdi-account-outline"
              :loading="customerStore.loading"
            />
          </v-card-text>

          <v-card-actions class="border-t pa-3 justify-end">
            <v-btn variant="plain" :disabled="transferring" @click="showTransferModal = false">
              Annuler
            </v-btn>
            <v-btn
              color="info"
              variant="flat"
              prepend-icon="mdi-check-bold"
              :loading="transferring"
              :disabled="!selectedNewCustomerId || selectedNewCustomerId === sim.customerId"
              @click="confirmTransfer"
            >
              Confirmer le Transfert
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useSimStore } from '@/stores/sim.store';
import { useLicenseStore } from '@/stores/license.store';
import { useCustomerStore } from '@/stores/customer.store';
import { useNotificationStore } from '@/stores/notification.store';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import SimStatusChip from '@/components/common/SimStatusChip.vue';
import LicenseStatusChip from '@/components/common/LicenseStatusChip.vue';
import MaskedValue from '@/components/common/MaskedValue.vue';
import LoadingSkeleton from '@/components/common/LoadingSkeleton.vue';
import ErrorState from '@/components/common/ErrorState.vue';
import DangerConfirmDialog from '@/components/common/DangerConfirmDialog.vue';

const route = useRoute();
const simStore = useSimStore();
const licenseStore = useLicenseStore();
const customerStore = useCustomerStore();
const notificationStore = useNotificationStore();

const { currentSim: sim, loading } = storeToRefs(simStore);
const tab = ref('overview');
const showBlockModal = ref(false);
const blocking = ref(false);

const showTransferModal = ref(false);
const transferring = ref(false);
const selectedNewCustomerId = ref<string | null>(null);

const simId = computed(() => route.params.id as string);

// Find real database license linked to this SIM
const realLicense = computed(() => {
  return licenseStore.licenses.find((l) => l.simId === simId.value || l.simPhone === sim.value?.phoneNumber);
});

const customerOptions = computed(() => {
  return customerStore.customers.map((c) => ({
    id: c.id,
    title: `${c.name} (${c.company || c.phone || c.id})`,
  }));
});

const loadSim = async () => {
  if (simId.value) {
    await simStore.fetchSimById(simId.value);
    await licenseStore.fetchLicenses();
    await customerStore.fetchCustomers();
  }
};

onMounted(loadSim);

const copySerial = async (serial?: string) => {
  if (!serial) {
    notificationStore.showMessage('No serial code available to copy', 'warning');
    return;
  }
  try {
    await navigator.clipboard.writeText(serial.trim());
    notificationStore.showMessage('Serial code copied to clipboard!', 'success');
  } catch {
    notificationStore.showMessage('Failed to copy serial code', 'error');
  }
};

const activateSim = async () => {
  if (!sim.value) return;
  await simStore.activateSim(sim.value.id);
  notificationStore.showMessage('SIM reactivated successfully', 'success');
};

const confirmBlock = async () => {
  if (!sim.value) return;
  blocking.value = true;
  try {
    await simStore.blockSim(sim.value.id);
    notificationStore.showMessage(`SIM ${sim.value.phoneNumber} has been blocked`, 'warning');
    showBlockModal.value = false;
  } finally {
    blocking.value = false;
  }
};

const openTransferModal = async () => {
  selectedNewCustomerId.value = null;
  await customerStore.fetchCustomers();
  showTransferModal.value = true;
};

const confirmTransfer = async () => {
  if (!sim.value || !selectedNewCustomerId.value) return;
  transferring.value = true;
  try {
    await simStore.transferOwnership(sim.value.id, selectedNewCustomerId.value);
    notificationStore.showMessage('Propriété de la SIM transférée avec succès!', 'success');
    showTransferModal.value = false;
    await loadSim();
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Erreur lors du transfert', 'error');
  } finally {
    transferring.value = false;
  }
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
.cursor-pointer {
  cursor: pointer;
}
</style>
