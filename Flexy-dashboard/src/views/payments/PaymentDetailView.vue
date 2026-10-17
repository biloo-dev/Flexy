<template>
  <div class="payment-detail-view">
    <PageHeader
      :title="payment ? payment.reference : 'Payment Record'"
      :subtitle="payment ? `Customer: ${payment.customerName} • ${payment.amount.toLocaleString()} ${payment.currency}` : ''"
      :breadcrumbs="[
        { title: 'Dashboard', to: '/dashboard' },
        { title: 'Payments', to: '/payments' },
        { title: payment ? payment.reference : 'Detail' }
      ]"
    >
      <template #badge>
        <StatusChip v-if="payment" :status="payment.status" size="default" />
      </template>
    </PageHeader>

    <LoadingSkeleton v-if="loading && !payment" type="card@3" />

    <ErrorState
      v-else-if="!payment"
      title="Payment Record Not Found"
      message="The requested transaction could not be located in the database."
      @retry="loadPayment"
    />

    <template v-else>
      <v-row>
        <!-- Payment Details Card -->
        <v-col cols="12" md="7">
          <v-card class="pa-5 border fill-height">
            <h3 class="text-subtitle-1 font-weight-bold mb-4">Transaction Details</h3>
            <v-list density="compact" class="pa-0">
              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 140px;">Reference ID:</span></template>
                <span class="text-body-2 font-weight-bold font-family-monospace">{{ payment.reference }}</span>
              </v-list-item>
              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 140px;">Customer Account:</span></template>
                <router-link :to="`/customers/${payment.customerId}`" class="text-body-2 text-decoration-none font-weight-bold text-primary">
                  {{ payment.customerName }}
                </router-link>
              </v-list-item>
              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 140px;">License Issued:</span></template>
                <router-link :to="`/licenses/${payment.licenseId}`" class="text-body-2 text-decoration-none font-weight-bold text-info">
                  {{ payment.licenseId }}
                </router-link>
              </v-list-item>
              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 140px;">Amount:</span></template>
                <span class="text-h6 font-weight-black font-family-monospace text-success">{{ payment.amount.toLocaleString() }} {{ payment.currency }}</span>
              </v-list-item>
              <v-list-item class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 140px;">Payment Method:</span></template>
                <span class="text-body-2">{{ payment.paymentMethod }}</span>
              </v-list-item>
              <v-list-item v-if="payment.paidAt" class="px-0">
                <template #prepend><span class="text-caption text-medium-emphasis me-4" style="min-width: 140px;">Settled On:</span></template>
                <span class="text-body-2">{{ new Date(payment.paidAt).toLocaleString() }}</span>
              </v-list-item>
              <v-list-item v-if="payment.failureReason" class="px-0">
                <template #prepend><span class="text-caption text-error me-4" style="min-width: 140px;">Failure Reason:</span></template>
                <span class="text-caption font-weight-bold text-error">{{ payment.failureReason }}</span>
              </v-list-item>
            </v-list>
          </v-card>
        </v-col>

        <!-- Payment Lifecycle Timeline -->
        <v-col cols="12" md="5">
          <v-card class="pa-5 border fill-height">
            <h3 class="text-subtitle-1 font-weight-bold mb-4">Payment Lifecycle Timeline</h3>
            <v-timeline density="compact" align="start">
              <v-timeline-item dot-color="primary" size="x-small">
                <div class="text-caption font-weight-bold">Payment Order Created</div>
                <div class="text-caption text-medium-emphasis">{{ new Date(payment.createdAt).toLocaleString() }}</div>
              </v-timeline-item>
              <v-timeline-item :dot-color="payment.status === 'paid' ? 'success' : payment.status === 'failed' ? 'error' : 'warning'" size="x-small">
                <div class="text-caption font-weight-bold">
                  {{ payment.status === 'paid' ? 'Payment Confirmed & Settled' : payment.status === 'failed' ? 'Transaction Failed' : 'Awaiting Payment' }}
                </div>
                <div class="text-caption text-medium-emphasis">
                  {{ payment.paidAt ? new Date(payment.paidAt).toLocaleString() : 'Pending gateway webhook' }}
                </div>
              </v-timeline-item>
              <v-timeline-item :dot-color="payment.status === 'paid' ? 'success' : 'grey'" size="x-small">
                <div class="text-caption font-weight-bold">Ed25519 License Key Generated & Signed</div>
                <div class="text-caption text-medium-emphasis">License {{ payment.licenseId }} bound and active</div>
              </v-timeline-item>
            </v-timeline>
          </v-card>
        </v-col>
      </v-row>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { usePaymentStore } from '@/stores/payment.store';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import StatusChip from '@/components/common/StatusChip.vue';
import LoadingSkeleton from '@/components/common/LoadingSkeleton.vue';
import ErrorState from '@/components/common/ErrorState.vue';

const route = useRoute();
const paymentStore = usePaymentStore();
const { currentPayment: payment, loading } = storeToRefs(paymentStore);

const paymentId = computed(() => route.params.id as string);

const loadPayment = () => {
  if (paymentId.value) {
    paymentStore.fetchPaymentById(paymentId.value);
  }
};

onMounted(loadPayment);
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
