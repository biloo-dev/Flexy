<template>
  <div class="operators-view">
    <PageHeader
      title="Algerian Telecom Operators"
      subtitle="Operational status, SIM density, and Flexi gateway routing across carriers."
      :breadcrumbs="[{ title: 'Dashboard', to: '/dashboard' }, { title: 'Operators' }]"
    />

    <!-- Operator Cards Grid -->
    <v-row class="mb-6">
      <v-col
        v-for="op in operators"
        :key="op.id"
        cols="12"
        md="4"
      >
        <v-card class="pa-5 fill-height border" :style="{ borderTop: `4px solid ${op.color}` }">
          <!-- Header -->
          <div class="d-flex align-center justify-space-between mb-4">
            <div class="d-flex align-center ga-3">
              <v-avatar :color="op.color" variant="tonal" size="48" rounded="lg">
                <v-icon size="28" :color="op.color">mdi-cellphone-tower</v-icon>
              </v-avatar>
              <div>
                <h3 class="text-h6 font-weight-bold">{{ op.name }}</h3>
                <span class="text-caption font-family-monospace text-medium-emphasis">Code: {{ op.code }}</span>
              </div>
            </div>
            <StatusChip :status="op.status" />
          </div>

          <!-- Operator Stats Grid -->
          <v-divider class="my-3" />
          <v-row dense class="my-2">
            <v-col cols="6">
              <div class="text-caption text-medium-emphasis">Total SIMs</div>
              <div class="text-h6 font-weight-bold">{{ op.simsCount }}</div>
            </v-col>
            <v-col cols="6">
              <div class="text-caption text-medium-emphasis">Active SIMs</div>
              <div class="text-h6 font-weight-bold text-success">{{ op.activeSimsCount }}</div>
            </v-col>
            <v-col cols="6" class="mt-2">
              <div class="text-caption text-medium-emphasis">Total Operations</div>
              <div class="text-h6 font-weight-bold">{{ op.operationsCount.toLocaleString() }}</div>
            </v-col>
            <v-col cols="6" class="mt-2">
              <div class="text-caption text-medium-emphasis">Success Rate</div>
              <div class="text-h6 font-weight-bold text-primary">{{ op.successRate }}%</div>
            </v-col>
          </v-row>

          <v-divider class="my-3" />

          <!-- Balance & Actions -->
          <div class="d-flex align-center justify-space-between pt-2">
            <div>
              <span class="text-caption text-medium-emphasis d-block">Operator Balance</span>
              <span class="text-body-1 font-weight-black">{{ op.balance?.toLocaleString() }} {{ op.currency }}</span>
            </div>

            <div class="d-flex ga-2">
              <v-btn
                :color="op.status === 'active' ? 'warning' : 'success'"
                variant="tonal"
                size="small"
                :prepend-icon="op.status === 'active' ? 'mdi-pause' : 'mdi-play'"
                @click="toggleStatus(op.id)"
              >
                {{ op.status === 'active' ? 'Suspend' : 'Activate' }}
              </v-btn>
              
              <v-tooltip text="Cannot delete operator with active SIM and license bindings" location="top">
                <template #activator="{ props }">
                  <v-btn
                    v-bind="props"
                    icon
                    size="small"
                    variant="text"
                    disabled
                    color="secondary"
                  >
                    <v-icon size="18">mdi-delete-off-outline</v-icon>
                  </v-btn>
                </template>
              </v-tooltip>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Operational Architecture & Gateway Info -->
    <v-card class="pa-5 border">
      <h3 class="text-subtitle-1 font-weight-bold mb-2">USSD & Direct API Routing Gateway</h3>
      <p class="text-body-2 text-medium-emphasis mb-4">
        All 3 Algerian carriers are configured for zero-latency multi-threaded queueing. The FLEXI engine automatically manages modem serial port multiplexing (/dev/ttyUSB*), AT commands, and USSD protocol framing.
      </p>

      <v-row>
        <v-col cols="12" md="4">
          <v-card variant="outlined" class="pa-3">
            <div class="d-flex align-center ga-2 font-weight-bold mb-1">
              <v-icon color="#EF4444" size="18">mdi-checkbox-blank-circle</v-icon>
              Djezzy USSD Protocol
            </div>
            <div class="text-caption text-medium-emphasis">Prefix: *710*CODE*AMOUNT#</div>
            <div class="text-caption text-success font-weight-medium mt-1">● Latency ~1,400ms</div>
          </v-card>
        </v-col>
        <v-col cols="12" md="4">
          <v-card variant="outlined" class="pa-3">
            <div class="d-flex align-center ga-2 font-weight-bold mb-1">
              <v-icon color="#10B981" size="18">mdi-checkbox-blank-circle</v-icon>
              Mobilis Direct Electronic E-Charge
            </div>
            <div class="text-caption text-medium-emphasis">Prefix: *600*CODE*AMOUNT#</div>
            <div class="text-caption text-success font-weight-medium mt-1">● Latency ~1,100ms</div>
          </v-card>
        </v-col>
        <v-col cols="12" md="4">
          <v-card variant="outlined" class="pa-3">
            <div class="d-flex align-center ga-2 font-weight-bold mb-1">
              <v-icon color="#E11D48" size="18">mdi-checkbox-blank-circle</v-icon>
              Ooredoo Storm Flexi
            </div>
            <div class="text-caption text-medium-emphasis">Prefix: *115*CODE*AMOUNT#</div>
            <div class="text-caption text-success font-weight-medium mt-1">● Latency ~1,600ms</div>
          </v-card>
        </v-col>
      </v-row>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';
import { useOperatorStore } from '@/stores/operator.store';
import { useNotificationStore } from '@/stores/notification.store';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import StatusChip from '@/components/common/StatusChip.vue';

const operatorStore = useOperatorStore();
const notificationStore = useNotificationStore();
const { operators } = storeToRefs(operatorStore);

onMounted(() => {
  operatorStore.fetchOperators();
});

const toggleStatus = async (id: string) => {
  const updated = await operatorStore.toggleStatus(id);
  notificationStore.showMessage(`${updated.name} status set to ${updated.status}`, 'info');
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
