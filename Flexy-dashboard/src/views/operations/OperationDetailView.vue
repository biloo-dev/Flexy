<template>
  <div class="operation-detail-view">
    <PageHeader
      :title="operation ? `${operation.operationCode} (${operation.amount.toLocaleString()} ${operation.currency})` : 'Operation Diagnostic Trace'"
      :subtitle="operation ? `Customer: ${operation.customerName} • Target: ${operation.targetPhone} (${operation.operator})` : ''"
      :breadcrumbs="[
        { title: 'Dashboard', to: '/dashboard' },
        { title: 'Operations', to: '/operations' },
        { title: operation ? operation.operationCode : 'Detail' }
      ]"
    >
      <template #badge>
        <OperationStatusChip v-if="operation" :status="operation.status" size="default" />
      </template>
    </PageHeader>

    <LoadingSkeleton v-if="loading && !operation" type="card@3" />

    <ErrorState
      v-else-if="!operation"
      title="Operation Record Not Found"
      message="The requested transaction trace could not be loaded."
      @retry="loadOperation"
    />

    <template v-else>
      <!-- Telemetry Highlights -->
      <v-row class="mb-4">
        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Recharge Target</div>
            <div class="text-h6 font-weight-bold font-family-monospace mt-1 d-flex align-center ga-2">
              <v-icon :color="operation.operator === 'MOBILIS' ? 'success' : operation.operator === 'DJEZZY' ? 'error' : 'accent'">
                mdi-cellphone-wireless
              </v-icon>
              {{ operation.targetPhone }}
            </div>
            <div class="text-caption text-medium-emphasis mt-2">{{ operation.operator }} Network Route</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Amount Dispatched</div>
            <div class="text-h6 font-weight-bold font-family-monospace text-success mt-1">
              {{ operation.amount.toLocaleString() }} {{ operation.currency }}
            </div>
            <div class="text-caption text-medium-emphasis mt-2">Source: {{ operation.simPhone }}</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Execution Latency</div>
            <div class="text-h6 font-weight-bold font-family-monospace mt-1">
              {{ operation.executionDurationMs }} ms
            </div>
            <div class="text-caption text-medium-emphasis mt-2">USSD round-trip time</div>
          </v-card>
        </v-col>

        <v-col cols="12" sm="6" md="3">
          <v-card class="pa-4 border fill-height">
            <div class="text-caption text-medium-emphasis">Idempotency Status</div>
            <div class="text-caption font-weight-bold font-family-monospace text-truncate mt-1">
              {{ operation.idempotencyKey }}
            </div>
            <div class="text-caption text-success font-weight-medium mt-2">✓ Key Verified Unique</div>
          </v-card>
        </v-col>
      </v-row>

      <!-- Failure / Error Banner if failed or blocked -->
      <v-alert
        v-if="operation.errorMessage"
        color="error"
        variant="tonal"
        icon="mdi-shield-alert"
        class="mb-4"
      >
        <div class="font-weight-bold">Pipeline Execution Error:</div>
        <div class="text-body-2">{{ operation.errorMessage }}</div>
      </v-alert>

      <!-- Verification Pipeline & Deep Lifecycle Diagnostics -->
      <v-row>
        <v-col cols="12" lg="7">
          <OperationPipelineTimeline :steps="operation.verificationPipeline" />
        </v-col>

        <v-col cols="12" lg="5">
          <!-- Relational Context Card -->
          <v-card class="pa-4 border fill-height">
            <h3 class="text-subtitle-1 font-weight-bold mb-3">Relational Hardware Context</h3>
            
            <v-list density="compact" class="pa-0">
              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-3" style="min-width: 110px;">Customer:</span></template>
                <router-link :to="`/customers/${operation.customerId}`" class="text-body-2 text-decoration-none font-weight-bold text-primary">
                  {{ operation.customerName }}
                </router-link>
              </v-list-item>

              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-3" style="min-width: 110px;">Host Gateway:</span></template>
                <router-link :to="`/devices/${operation.deviceId}`" class="text-body-2 text-decoration-none font-weight-bold text-info">
                  {{ operation.deviceName }}
                </router-link>
              </v-list-item>

              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-3" style="min-width: 110px;">Source SIM:</span></template>
                <router-link :to="`/sim-cards/${operation.simId}`" class="text-body-2 font-family-monospace text-decoration-none font-weight-bold text-primary">
                  {{ operation.simPhone }}
                </router-link>
              </v-list-item>

              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-3" style="min-width: 110px;">Execution Port:</span></template>
                <v-chip size="x-small" variant="outlined" class="font-family-monospace">{{ operation.modemId }}</v-chip>
              </v-list-item>

              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-3" style="min-width: 110px;">Started At:</span></template>
                <span class="text-body-2 font-family-monospace">{{ new Date(operation.createdAt).toLocaleString() }}</span>
              </v-list-item>

              <v-list-item v-if="operation.completedAt" class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-3" style="min-width: 110px;">Completed At:</span></template>
                <span class="text-body-2 font-family-monospace">{{ new Date(operation.completedAt).toLocaleString() }}</span>
              </v-list-item>
            </v-list>
          </v-card>
        </v-col>
      </v-row>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useOperationStore } from '@/stores/operation.store';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import OperationStatusChip from '@/components/common/OperationStatusChip.vue';
import OperationPipelineTimeline from '@/components/operations/OperationPipelineTimeline.vue';
import LoadingSkeleton from '@/components/common/LoadingSkeleton.vue';
import ErrorState from '@/components/common/ErrorState.vue';

const route = useRoute();
const operationStore = useOperationStore();
const { currentOperation: operation, loading } = storeToRefs(operationStore);

const operationId = computed(() => route.params.id as string);

const loadOperation = () => {
  if (operationId.value) {
    operationStore.fetchOperationById(operationId.value);
  }
};

onMounted(loadOperation);
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
