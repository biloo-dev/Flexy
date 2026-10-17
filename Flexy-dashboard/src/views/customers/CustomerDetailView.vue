<template>
  <div class="customer-detail-view">
    <!-- Header with Breadcrumbs -->
    <PageHeader
      :title="customer?.name || 'Customer Profile'"
      :subtitle="customer ? `${customer.company || 'Private Account'} • ${customer.email}` : ''"
      :breadcrumbs="[
        { title: 'Dashboard', to: '/dashboard' },
        { title: 'Customers', to: '/customers' },
        { title: customer ? customer.name : 'Detail' }
      ]"
    >
      <template #badge>
        <StatusChip v-if="customer" :status="customer.status" size="default" />
      </template>

      <template #actions>
        <v-btn
          v-if="customer?.status !== 'active'"
          color="success"
          variant="tonal"
          prepend-icon="mdi-check"
          @click="updateStatus('active')"
        >
          Activate
        </v-btn>
        <v-btn
          v-if="customer?.status !== 'suspended'"
          color="warning"
          variant="tonal"
          prepend-icon="mdi-pause"
          @click="updateStatus('suspended')"
        >
          Suspend
        </v-btn>
        <v-btn
          v-if="customer?.status !== 'blocked'"
          color="error"
          variant="tonal"
          prepend-icon="mdi-block-helper"
          @click="updateStatus('blocked')"
        >
          Block
        </v-btn>
      </template>
    </PageHeader>

    <!-- Loading Skeleton -->
    <LoadingSkeleton v-if="loading && !customer" type="card@3" />

    <!-- Error State -->
    <ErrorState
      v-else-if="!customer"
      title="Customer Not Found"
      message="The customer profile you requested could not be located."
      @retry="loadCustomer"
    />

    <!-- Main Content Tabs -->
    <template v-else>
      <!-- Top Info Summary Cards -->
      <v-row class="mb-4">
        <v-col cols="12" sm="6" md="2.4">
          <MetricCard
            title="Total SIMs"
            :value="customer.simsCount"
            icon="mdi-sim"
            color="primary"
          />
        </v-col>
        <v-col cols="12" sm="6" md="2.4">
          <MetricCard
            title="Active SIMs"
            :value="customer.simsCount"
            icon="mdi-sim-alert"
            color="success"
          />
        </v-col>
        <v-col cols="12" sm="6" md="2.4">
          <MetricCard
            title="Active Licenses"
            :value="customer.licensesCount"
            icon="mdi-key-chain"
            color="info"
          />
        </v-col>
        <v-col cols="12" sm="6" md="2.4">
          <MetricCard
            title="Total Operations"
            :value="customer.operationsCount"
            icon="mdi-swap-horizontal-bold"
            color="warning"
          />
        </v-col>
        <v-col cols="12" sm="6" md="2.4">
          <MetricCard
            title="Total Revenue"
            :value="customer.totalRevenue"
            unit="DZD"
            icon="mdi-cash-multiple"
            color="success"
          />
        </v-col>
      </v-row>

      <!-- Profile Tabs -->
      <v-card class="border">
        <v-tabs v-model="tab" color="primary" class="border-b">
          <v-tab value="overview" prepend-icon="mdi-information-outline">Overview</v-tab>
          <v-tab value="devices" prepend-icon="mdi-laptop">Devices ({{ customer.devicesCount }})</v-tab>
          <v-tab value="sims" prepend-icon="mdi-sim">SIM Cards ({{ customer.simsCount }})</v-tab>
          <v-tab value="licenses" prepend-icon="mdi-key-chain">Licenses ({{ customer.licensesCount }})</v-tab>
          <v-tab value="payments" prepend-icon="mdi-cash-multiple">Payments</v-tab>
          <v-tab value="operations" prepend-icon="mdi-swap-horizontal-bold">Operations</v-tab>
          <v-tab value="activity" prepend-icon="mdi-history">Activity</v-tab>
        </v-tabs>

        <v-card-text class="pa-4">
          <v-window v-model="tab">
            <!-- 1. Overview Tab -->
            <v-window-item value="overview">
              <v-row>
                <v-col cols="12" md="6">
                  <v-card variant="outlined" class="pa-4">
                    <h4 class="text-subtitle-2 font-weight-bold mb-3">Customer Information</h4>
                    <v-list density="compact" class="pa-0">
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 110px;">Customer ID:</span></template>
                        <span class="text-body-2 font-weight-bold font-family-monospace">{{ customer.id }}</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 110px;">Full Name:</span></template>
                        <span class="text-body-2 font-weight-medium">{{ customer.name }}</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 110px;">Email:</span></template>
                        <span class="text-body-2">{{ customer.email }}</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 110px;">Phone:</span></template>
                        <span class="text-body-2 font-family-monospace">{{ customer.phone }}</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 110px;">Company:</span></template>
                        <span class="text-body-2">{{ customer.company || 'N/A' }}</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 110px;">Address:</span></template>
                        <span class="text-body-2">{{ customer.address || 'N/A' }}</span>
                      </v-list-item>
                      <v-list-item class="px-0">
                        <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 110px;">Registered:</span></template>
                        <span class="text-body-2">{{ new Date(customer.createdAt).toLocaleString() }}</span>
                      </v-list-item>
                    </v-list>
                  </v-card>
                </v-col>

                <v-col cols="12" md="6">
                  <v-card variant="outlined" class="pa-4">
                    <h4 class="text-subtitle-2 font-weight-bold mb-3">Quick Navigation</h4>
                    <div class="d-flex flex-column ga-2">
                      <v-btn variant="tonal" color="primary" prepend-icon="mdi-sim" block justify-start to="/sim-cards">
                        View Bound SIM Cards for {{ customer.name }}
                      </v-btn>
                      <v-btn variant="tonal" color="info" prepend-icon="mdi-key-chain" block justify-start to="/licenses">
                        Manage Ed25519 Licenses
                      </v-btn>
                      <v-btn variant="tonal" color="success" prepend-icon="mdi-swap-horizontal-bold" block justify-start to="/operations">
                        Inspect Flexi Operations Stream
                      </v-btn>
                    </div>
                  </v-card>
                </v-col>
              </v-row>
            </v-window-item>

            <!-- 2. Devices Tab -->
            <v-window-item value="devices">
              <v-list lines="two">
                <v-list-item
                  v-for="d in customerDevices"
                  :key="d.id"
                  class="border rounded-lg mb-2 cursor-pointer"
                  :to="`/devices/${d.id}`"
                >
                  <template #prepend>
                    <v-avatar color="info" variant="tonal" size="36" class="me-3">
                      <v-icon size="20">mdi-laptop</v-icon>
                    </v-avatar>
                  </template>
                  <v-list-item-title class="font-weight-bold">{{ d.name }}</v-list-item-title>
                  <v-list-item-subtitle class="text-caption">
                    ID: {{ d.id }} • UUID: {{ d.uuid }} • IP: {{ d.ipAddress }}
                  </v-list-item-subtitle>
                  <template #append>
                    <StatusChip :status="d.status" />
                  </template>
                </v-list-item>
              </v-list>
            </v-window-item>

            <!-- 3. SIM Cards Tab -->
            <v-window-item value="sims">
              <div class="d-flex justify-space-between align-center mb-3">
                <div class="text-subtitle-1 font-weight-bold">Registered SIM Cards ({{ customerSims.length }})</div>
                <v-btn
                  color="primary"
                  size="small"
                  prepend-icon="mdi-plus"
                  class="font-weight-bold"
                  @click="openAddSimDialog"
                >
                  Add SIM Card
                </v-btn>
              </div>

              <v-list v-if="customerSims.length > 0" lines="two">
                <v-list-item
                  v-for="s in customerSims"
                  :key="s.id"
                  class="border rounded-lg mb-2"
                >
                  <template #prepend>
                    <v-avatar :color="s.operator === 'MOBILIS' ? 'success' : s.operator === 'DJEZZY' ? 'error' : 'accent'" variant="tonal" size="36" class="me-3">
                      <v-icon size="20">mdi-sim</v-icon>
                    </v-avatar>
                  </template>
                  <v-list-item-title class="font-weight-bold">
                    <router-link :to="`/sim-cards/${s.id}`" class="text-decoration-none text-high-emphasis">
                      {{ s.operator }} - {{ s.phoneNumber }}
                    </router-link>
                  </v-list-item-title>
                  <v-list-item-subtitle class="text-caption">
                    ICCID: <MaskedValue :raw-value="s.iccid" /> • Balance: {{ s.currentBalance?.toLocaleString() || 0 }} DZD
                  </v-list-item-subtitle>
                  <template #append>
                    <div class="d-flex align-center ga-1" @click.stop>
                      <StatusChip :status="s.status" class="me-2" />

                      <!-- Edit SIM -->
                      <v-tooltip text="Modifier la SIM" location="top">
                        <template #activator="{ props }">
                          <v-btn
                            v-bind="props"
                            icon
                            size="x-small"
                            variant="text"
                            color="info"
                            @click="openEditSimDialog(s)"
                          >
                            <v-icon size="18">mdi-pencil-outline</v-icon>
                          </v-btn>
                        </template>
                      </v-tooltip>

                      <!-- Delete SIM -->
                      <v-tooltip text="Supprimer la SIM" location="top">
                        <template #activator="{ props }">
                          <v-btn
                            v-bind="props"
                            icon
                            size="x-small"
                            variant="text"
                            color="error"
                            @click="openDeleteSimDialog(s)"
                          >
                            <v-icon size="18">mdi-delete-outline</v-icon>
                          </v-btn>
                        </template>
                      </v-tooltip>
                    </div>
                  </template>
                </v-list-item>
              </v-list>
              <EmptyState
                v-else
                title="No SIM Cards Registered"
                message="Add a SIM card with its 20-digit ICCID to bind it to this customer."
                icon="mdi-sim-off"
              />
            </v-window-item>

            <!-- 4. Licenses Tab -->
            <v-window-item value="licenses">
              <div class="d-flex justify-space-between align-center mb-3">
                <div class="text-subtitle-1 font-weight-bold">Cryptographic Licenses ({{ customerLicenses.length }})</div>
                <v-btn
                  color="primary"
                  size="small"
                  prepend-icon="mdi-key-plus"
                  class="font-weight-bold"
                  @click="openGenerateLicenseDialog"
                >
                  Generate License
                </v-btn>
              </div>

              <v-list v-if="customerLicenses.length > 0" lines="two">
                <v-list-item
                  v-for="l in customerLicenses"
                  :key="l.id"
                  class="border rounded-lg mb-2 cursor-pointer"
                  :to="`/licenses/${l.id}`"
                >
                  <template #prepend>
                    <v-avatar color="warning" variant="tonal" size="36" class="me-3">
                      <v-icon size="20">mdi-key-chain</v-icon>
                    </v-avatar>
                  </template>
                  <v-list-item-title class="font-weight-bold">{{ l.id }} ({{ l.maskedSerial }})</v-list-item-title>
                  <v-list-item-subtitle class="text-caption">
                    Key: {{ l.keyId }} • Algorithm: {{ l.algorithm }} • Expires: {{ new Date(l.expiresAt).toLocaleDateString() }}
                  </v-list-item-subtitle>
                  <template #append>
                    <div class="d-flex align-center ga-2">
                      <v-btn
                        size="small"
                        variant="tonal"
                        color="primary"
                        prepend-icon="mdi-content-copy"
                        @click.stop="openSerialResultDialog(l.serialNumber)"
                      >
                        Copy Serial
                      </v-btn>
                      <LicenseStatusChip :status="l.status" />
                    </div>
                  </template>
                </v-list-item>
              </v-list>
              <EmptyState
                v-else
                title="No Active Licenses"
                message="Generate an Ed25519 signed license serial for this customer's SIM cards."
                icon="mdi-key-remove"
              />
            </v-window-item>

            <!-- 5. Payments Tab -->
            <v-window-item value="payments">
              <v-list lines="two">
                <v-list-item
                  v-for="p in customerPayments"
                  :key="p.id"
                  class="border rounded-lg mb-2"
                >
                  <template #prepend>
                    <v-avatar color="success" variant="tonal" size="36" class="me-3">
                      <v-icon size="20">mdi-cash-check</v-icon>
                    </v-avatar>
                  </template>
                  <v-list-item-title class="font-weight-bold">{{ p.reference }}</v-list-item-title>
                  <v-list-item-subtitle class="text-caption">
                    {{ p.amount.toLocaleString() }} {{ p.currency }} • Method: {{ p.paymentMethod }} • {{ new Date(p.createdAt).toLocaleDateString() }}
                  </v-list-item-subtitle>
                  <template #append>
                    <StatusChip :status="p.status" />
                  </template>
                </v-list-item>
              </v-list>
            </v-window-item>

            <!-- 6. Operations Tab -->
            <v-window-item value="operations">
              <v-list lines="two">
                <v-list-item
                  v-for="op in customerOps"
                  :key="op.id"
                  class="border rounded-lg mb-2 cursor-pointer"
                  :to="`/operations/${op.id}`"
                >
                  <template #prepend>
                    <v-avatar :color="op.status === 'success' ? 'success' : 'error'" variant="tonal" size="36" class="me-3">
                      <v-icon size="20">mdi-swap-horizontal-bold</v-icon>
                    </v-avatar>
                  </template>
                  <v-list-item-title class="font-weight-bold">{{ op.operationCode }} ({{ op.amount }} {{ op.currency }})</v-list-item-title>
                  <v-list-item-subtitle class="text-caption">
                    Target: {{ op.targetPhone }} • Operator: {{ op.operator }} • Duration: {{ op.executionDurationMs }}ms
                  </v-list-item-subtitle>
                  <template #append>
                    <OperationStatusChip :status="op.status" />
                  </template>
                </v-list-item>
              </v-list>
            </v-window-item>

            <!-- 7. Activity Tab -->
            <v-window-item value="activity">
              <ActivityTimeline :items="customerActivity" />
            </v-window-item>
          </v-window>
        </v-card-text>
      </v-card>
    </template>

    <!-- Dialog 1: Add SIM Card -->
    <v-dialog v-model="showAddSimDialog" max-width="500">
      <v-card>
        <v-card-title class="pa-4 font-weight-bold d-flex align-center ga-2 border-b">
          <v-icon color="primary">mdi-sim</v-icon>
          <span>Register New SIM Card</span>
        </v-card-title>
        <v-card-text class="pa-4">
          <v-select
            v-model="newSim.operatorId"
            label="Telecom Operator *"
            :items="operatorOptions"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />
          <v-text-field
            v-model="newSim.phoneNumber"
            label="SIM Phone Number *"
            placeholder="0770112233 / 0659812181"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />
          <v-text-field
            v-model="newSim.iccid"
            label="20-Digit ICCID Number *"
            placeholder="89213012345678901234"
            hint="Read directly from modem or SIM plastic card"
            persistent-hint
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />
        </v-card-text>
        <v-card-actions class="pa-4 border-t d-flex justify-end">
          <v-btn variant="text" @click="showAddSimDialog = false">Cancel</v-btn>
          <v-btn
            color="primary"
            variant="elevated"
            :loading="savingSim"
            @click="handleSaveSim"
          >
            Register SIM
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog 2: Generate Ed25519 License -->
    <v-dialog v-model="showGenerateLicenseDialog" max-width="520">
      <v-card>
        <v-card-title class="pa-4 font-weight-bold d-flex align-center ga-2 border-b">
          <v-icon color="warning">mdi-key-chain</v-icon>
          <span>Generate Ed25519 Signed License</span>
        </v-card-title>
        <v-card-text class="pa-4">
          <v-select
            v-model="newLicense.simCardId"
            label="Select Bound SIM Card *"
            :items="customerSims.map((s) => ({ title: `${s.operator} - ${s.phoneNumber} (ICCID: ${s.iccid.slice(-6)})`, value: s.id }))"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />
          <v-select
            v-model="newLicense.validityDays"
            label="Subscription Duration *"
            :items="[
              { title: '1 Year (365 Days) - Recommended', value: 365 },
              { title: '6 Months (180 Days)', value: 180 },
              { title: '3 Months (90 Days)', value: 90 },
              { title: '1 Month (30 Days)', value: 30 }
            ]"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />
          <v-text-field
            v-model.number="newLicense.amount"
            label="Subscription Amount (DZD) *"
            type="number"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />
        </v-card-text>
        <v-card-actions class="pa-4 border-t d-flex justify-end">
          <v-btn variant="text" @click="showGenerateLicenseDialog = false">Cancel</v-btn>
          <v-btn
            color="warning"
            variant="elevated"
            class="font-weight-bold"
            :loading="generatingLicense"
            @click="handleGenerateLicense"
          >
            Generate & Sign
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog 3: Generated Serial Result & WhatsApp Share -->
    <v-dialog v-model="showSerialResultDialog" max-width="600">
      <v-card>
        <v-card-title class="pa-4 font-weight-bold d-flex align-center ga-2 bg-success text-white">
          <v-icon color="white">mdi-check-decagram</v-icon>
          <span>Ed25519 License Generated Successfully!</span>
        </v-card-title>
        <v-card-text class="pa-4">
          <p class="text-body-2 mb-3">
            Copy this license serial and deliver it to the client to paste in their Flexy Desktop app under <strong>Activation SIM</strong>:
          </p>

          <v-sheet class="pa-3 rounded border font-family-monospace text-caption bg-surface-variant mb-4 position-relative" style="word-break: break-all;">
            {{ generatedSerial }}
          </v-sheet>

          <div class="d-flex ga-2">
            <v-btn
              color="primary"
              variant="elevated"
              prepend-icon="mdi-content-copy"
              class="flex-grow-1"
              @click="copyGeneratedSerial"
            >
              Copy Serial Code
            </v-btn>
            <v-btn
              color="success"
              variant="tonal"
              prepend-icon="mdi-whatsapp"
              class="flex-grow-1"
              @click="copyWhatsAppMessage"
            >
              Copy for WhatsApp
            </v-btn>
          </div>
        </v-card-text>
        <v-card-actions class="pa-4 border-t d-flex justify-end">
          <v-btn color="primary" variant="text" @click="showSerialResultDialog = false">Done</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <!-- Dialog 4: Edit SIM Card -->
    <v-dialog v-model="showEditSimDialog" max-width="500">
      <v-card>
        <v-card-title class="pa-4 font-weight-bold d-flex align-center ga-2 border-b">
          <v-icon color="info">mdi-pencil</v-icon>
          <span>Modifier la Carte SIM</span>
        </v-card-title>
        <v-card-text class="pa-4" v-if="editSimForm">
          <v-select
            v-model="editSimForm.operatorId"
            label="Opérateur Réseau *"
            :items="operatorOptions"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />
          <v-text-field
            v-model="editSimForm.phoneNumber"
            label="Numéro de Téléphone"
            placeholder="Ex: 0654605537"
            variant="outlined"
            density="comfortable"
            prepend-inner-icon="mdi-phone"
            class="mb-3"
          />
          <v-select
            v-model="editSimForm.status"
            label="Statut de la Puce *"
            :items="[
              { title: 'Pending (En attente)', value: 'pending' },
              { title: 'Active (Activée)', value: 'active' },
              { title: 'Blocked (Bloquée)', value: 'blocked' },
              { title: 'Suspended (Suspendue)', value: 'suspended' },
              { title: 'Expired (Expirée)', value: 'expired' },
            ]"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />
        </v-card-text>
        <v-card-actions class="pa-4 border-t d-flex justify-end">
          <v-btn variant="text" :disabled="updatingSim" @click="showEditSimDialog = false">Annuler</v-btn>
          <v-btn
            color="info"
            variant="elevated"
            class="font-weight-bold"
            :loading="updatingSim"
            @click="handleUpdateSim"
          >
            Enregistrer les Modifications
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog 5: Delete SIM Card -->
    <DangerConfirmDialog
      v-model="showDeleteSimDialog"
      title="Supprimer la Carte SIM"
      :message="`Êtes-vous sûr de vouloir supprimer définitivement la SIM ${selectedSimToDelete?.phoneNumber} (${selectedSimToDelete?.operator}) ?`"
      warning-text="Cette action supprimera également toutes les licences et liaisons associées à cette puce."
      confirm-text="Confirmer la Suppression"
      :loading="deletingSim"
      @confirm="handleDeleteSim"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useCustomerStore } from '@/stores/customer.store';
import { useSimStore } from '@/stores/sim.store';
import { useLicenseStore } from '@/stores/license.store';
import { useNotificationStore } from '@/stores/notification.store';
import { storeToRefs } from 'pinia';
import {
  mockDevices,
  mockPayments,
  mockOperations,
} from '@/api/mock/mockData';
import PageHeader from '@/components/common/PageHeader.vue';
import MetricCard from '@/components/common/MetricCard.vue';
import StatusChip from '@/components/common/StatusChip.vue';
import LicenseStatusChip from '@/components/common/LicenseStatusChip.vue';
import OperationStatusChip from '@/components/common/OperationStatusChip.vue';
import MaskedValue from '@/components/common/MaskedValue.vue';
import LoadingSkeleton from '@/components/common/LoadingSkeleton.vue';
import ErrorState from '@/components/common/ErrorState.vue';
import EmptyState from '@/components/common/EmptyState.vue';
import ActivityTimeline from '@/components/common/ActivityTimeline.vue';
import DangerConfirmDialog from '@/components/common/DangerConfirmDialog.vue';
import type { SimCard } from '@/types';

const route = useRoute();
const customerStore = useCustomerStore();
const simStore = useSimStore();
const licenseStore = useLicenseStore();
const notificationStore = useNotificationStore();

const { currentCustomer: customer, loading } = storeToRefs(customerStore);
const { simCards } = storeToRefs(simStore);
const { licenses } = storeToRefs(licenseStore);
const tab = ref('overview');

const customerId = computed(() => route.params.id as string);

const customerDevices = computed(() => mockDevices.filter((d) => d.customerId === customerId.value));
const customerSims = computed(() => simCards.value.filter((s) => s.customerId === customerId.value));
const customerLicenses = computed(() => licenses.value.filter((l) => l.customerId === customerId.value));
const customerPayments = computed(() => mockPayments.filter((p) => p.customerId === customerId.value));
const customerOps = computed(() => mockOperations.filter((op) => op.customerId === customerId.value));

// Modals State
const showAddSimDialog = ref(false);
const savingSim = ref(false);
const newSim = ref({
  operatorId: 'djezzy',
  phoneNumber: '',
  iccid: '',
});

// Edit SIM State
const showEditSimDialog = ref(false);
const updatingSim = ref(false);
const editingSimId = ref<string | null>(null);
const editSimForm = ref({
  operatorId: 'djezzy',
  phoneNumber: '',
  status: 'pending' as SimCard['status'],
});

// Delete SIM State
const showDeleteSimDialog = ref(false);
const deletingSim = ref(false);
const selectedSimToDelete = ref<SimCard | null>(null);

const showGenerateLicenseDialog = ref(false);
const generatingLicense = ref(false);
const newLicense = ref({
  simCardId: '',
  validityDays: 365,
  amount: 12000,
});

const showSerialResultDialog = ref(false);
const generatedSerial = ref('');

const operatorOptions = [
  { title: 'Djezzy (جازي)', value: 'djezzy' },
  { title: 'Mobilis (موبيليس)', value: 'mobilis' },
  { title: 'Ooredoo (أوريدو)', value: 'ooredoo' },
];

const customerActivity = [
  { title: 'Operation FLX-20260820-001 executed', description: '1000 DZD sent to 0771998877', time: '10 min ago', color: 'success', icon: 'mdi-check-circle' },
  { title: 'Ed25519 License Synchronized', description: 'License LIC-301 validated on Device DVC-001', time: '1 hour ago', color: 'primary', icon: 'mdi-key' },
  { title: 'Payment Confirmed', description: '35,000 DZD payment confirmed via CIB', time: '2 days ago', color: 'success', icon: 'mdi-cash-check' },
];

const loadCustomer = async () => {
  if (customerId.value) {
    await customerStore.fetchCustomerById(customerId.value);
    await simStore.fetchSimCards({ customerId: customerId.value, page: 1, limit: 100 });
    await licenseStore.fetchLicenses({ customerId: customerId.value, page: 1, limit: 100 });
  }
};

onMounted(loadCustomer);

const updateStatus = async (status: 'active' | 'suspended' | 'blocked') => {
  if (!customer.value) return;
  try {
    await customerStore.updateStatus(customer.value.id, status);
    notificationStore.showMessage(`Customer status updated to ${status}`, 'success');
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to update customer status', 'error');
  }
};

const openAddSimDialog = () => {
  newSim.value = { operatorId: 'djezzy', phoneNumber: '', iccid: '' };
  showAddSimDialog.value = true;
};

const handleSaveSim = async () => {
  if (!newSim.value.iccid.trim()) {
    notificationStore.showMessage('Please enter the 20-digit ICCID', 'error');
    return;
  }
  savingSim.value = true;
  try {
    await simStore.createSim({
      customerId: customerId.value,
      operatorId: newSim.value.operatorId,
      iccid: newSim.value.iccid.trim(),
      phoneNumber: newSim.value.phoneNumber.trim(),
    });
    await simStore.fetchSimCards({ customerId: customerId.value, page: 1, limit: 100 });
    notificationStore.showMessage('SIM Card registered successfully', 'success');
    showAddSimDialog.value = false;
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to register SIM card', 'error');
  } finally {
    savingSim.value = false;
  }
};

const openEditSimDialog = (sim: SimCard) => {
  editingSimId.value = sim.id;
  editSimForm.value = {
    operatorId: sim.operator.toLowerCase(),
    phoneNumber: sim.phoneNumber || '',
    status: sim.status,
  };
  showEditSimDialog.value = true;
};

const handleUpdateSim = async () => {
  if (!editingSimId.value) return;
  updatingSim.value = true;
  try {
    await simStore.updateSim(editingSimId.value, {
      operator: editSimForm.value.operatorId.toUpperCase() as any,
      phoneNumber: editSimForm.value.phoneNumber.trim(),
      status: editSimForm.value.status,
    });
    await simStore.fetchSimCards({ customerId: customerId.value, page: 1, limit: 100 });
    notificationStore.showMessage('Carte SIM modifiée avec succès!', 'success');
    showEditSimDialog.value = false;
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Échec de la modification de la SIM', 'error');
  } finally {
    updatingSim.value = false;
  }
};

const openDeleteSimDialog = (sim: SimCard) => {
  selectedSimToDelete.value = sim;
  showDeleteSimDialog.value = true;
};

const handleDeleteSim = async () => {
  if (!selectedSimToDelete.value) return;
  deletingSim.value = true;
  try {
    await simStore.deleteSim(selectedSimToDelete.value.id);
    await simStore.fetchSimCards({ customerId: customerId.value, page: 1, limit: 100 });
    await licenseStore.fetchLicenses({ customerId: customerId.value, page: 1, limit: 100 });
    await customerStore.fetchCustomerById(customerId.value);
    notificationStore.showMessage('Carte SIM supprimée avec succès!', 'success');
    showDeleteSimDialog.value = false;
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Échec de la suppression de la SIM', 'error');
  } finally {
    deletingSim.value = false;
  }
};

const openGenerateLicenseDialog = () => {
  if (customerSims.value.length > 0) {
    newLicense.value.simCardId = customerSims.value[0].id;
  }
  showGenerateLicenseDialog.value = true;
};

const openSerialResultDialog = (serial?: string) => {
  generatedSerial.value = serial || '';
  showSerialResultDialog.value = true;
};

const handleGenerateLicense = async () => {
  if (!newLicense.value.simCardId) {
    notificationStore.showMessage('Please select a SIM card', 'error');
    return;
  }
  generatingLicense.value = true;
  try {
    const selectedSim = customerSims.value.find((s) => s.id === newLicense.value.simCardId);
    const lic = await licenseStore.createLicense({
      customerId: customerId.value,
      simId: newLicense.value.simCardId,
      operator: selectedSim ? selectedSim.operator : 'MOBILIS',
      simPhone: selectedSim ? selectedSim.phoneNumber : '',
      price: newLicense.value.amount,
    } as any);

    await licenseStore.fetchLicenses({ customerId: customerId.value, page: 1, limit: 100 });
    
    const finalSerial = lic?.serialNumber || (lic as any)?.licenseSerial || (licenses.value[0]?.serialNumber ?? '');
    generatedSerial.value = finalSerial;
    showGenerateLicenseDialog.value = false;
    showSerialResultDialog.value = true;
    notificationStore.showMessage('License generated and signed with Ed25519', 'success');
  } catch (err: any) {
    notificationStore.showMessage(err.message || 'Failed to generate license', 'error');
  } finally {
    generatingLicense.value = false;
  }
};

const copyGeneratedSerial = () => {
  if (!generatedSerial.value) return;
  navigator.clipboard.writeText(generatedSerial.value);
  notificationStore.showMessage('License serial copied to clipboard!', 'success');
};

const copyWhatsAppMessage = () => {
  if (!generatedSerial.value) return;
  const msg = `مرحباً بك،\nإليك كود ترخيص وتفعيل برنامج Flexy الخاص بشريحتك:\n\n${generatedSerial.value}\n\nيرجى فتح البرنامج والذهاب إلى شاشة (تفعيل الشرائح) ولصق الكود ثم الضغط على تفعيل الشريحة ⚡.`;
  navigator.clipboard.writeText(msg);
  notificationStore.showMessage('WhatsApp message copied to clipboard!', 'success');
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

