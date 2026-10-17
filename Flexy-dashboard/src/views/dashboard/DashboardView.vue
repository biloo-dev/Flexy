<template>
  <div class="dashboard-view">
    <PageHeader
      title="Executive Overview"
      subtitle="Complete visibility over the entire FLEXI License & Telecom infrastructure."
      :breadcrumbs="[{ title: 'Dashboard' }]"
    >
      <template #actions>
        <DateRangePicker v-model="selectedPeriod" />
        <v-btn
          color="primary"
          prepend-icon="mdi-plus"
          class="font-weight-bold"
          to="/licenses"
        >
          Issue License
        </v-btn>
      </template>
    </PageHeader>

    <!-- Top 10 KPI Metric Cards -->
    <v-row class="mb-4">
      <v-col cols="12" sm="6" md="4" lg="2.4" xl="2.4">
        <MetricCard
          title="Total Customers"
          :value="kpis?.totalCustomers || 148"
          icon="mdi-account-group"
          color="primary"
          :change="8.4"
          to="/customers"
        />
      </v-col>
      <v-col cols="12" sm="6" md="4" lg="2.4" xl="2.4">
        <MetricCard
          title="Active Customers"
          :value="kpis?.activeCustomers || 142"
          icon="mdi-account-check"
          color="success"
          to="/customers"
        />
      </v-col>
      <v-col cols="12" sm="6" md="4" lg="2.4" xl="2.4">
        <MetricCard
          title="Total SIM Cards"
          :value="kpis?.totalSims || 1046"
          icon="mdi-sim"
          color="info"
          :change="12.0"
          to="/sim-cards"
        />
      </v-col>
      <v-col cols="12" sm="6" md="4" lg="2.4" xl="2.4">
        <MetricCard
          title="Active SIM Cards"
          :value="kpis?.activeSims || 972"
          icon="mdi-sim-alert"
          color="success"
          to="/sim-cards"
        />
      </v-col>
      <v-col cols="12" sm="6" md="4" lg="2.4" xl="2.4">
        <MetricCard
          title="Active Licenses"
          :value="kpis?.activeLicenses || 1046"
          icon="mdi-key-chain"
          color="primary"
          to="/licenses"
        />
      </v-col>

      <v-col cols="12" sm="6" md="4" lg="2.4" xl="2.4">
        <MetricCard
          title="Expiring Licenses"
          :value="kpis?.expiringLicenses || 18"
          icon="mdi-clock-alert-outline"
          color="warning"
          subtitle="Expires in <= 30 days"
          to="/licenses/expiring"
        />
      </v-col>
      <v-col cols="12" sm="6" md="4" lg="2.4" xl="2.4">
        <MetricCard
          title="Revenue (Total)"
          :value="kpis?.revenue || 12450000"
          unit="DZD"
          icon="mdi-cash-multiple"
          color="success"
          :change="14.8"
          to="/payments"
        />
      </v-col>
      <v-col cols="12" sm="6" md="4" lg="2.4" xl="2.4">
        <MetricCard
          title="Flexi Operations"
          :value="kpis?.totalOperations || 142930"
          icon="mdi-swap-horizontal-bold"
          color="primary"
          to="/operations"
        />
      </v-col>
      <v-col cols="12" sm="6" md="4" lg="2.4" xl="2.4">
        <MetricCard
          title="Successful Ops"
          :value="kpis?.successfulOperations || 141215"
          icon="mdi-check-circle-outline"
          color="success"
          subtitle="98.8% Success Rate"
          to="/operations"
        />
      </v-col>
      <v-col cols="12" sm="6" md="4" lg="2.4" xl="2.4">
        <MetricCard
          title="Failed / Blocked"
          :value="(kpis?.failedOperations || 1265) + (kpis?.blockedOperations || 450)"
          icon="mdi-shield-alert-outline"
          color="error"
          subtitle="450 Security Blocked"
          to="/security"
        />
      </v-col>
    </v-row>

    <!-- Main Charts Section -->
    <v-row class="mb-4">
      <!-- 1. Flexi Operations Overview -->
      <v-col cols="12" lg="8">
        <OperationsChart />
      </v-col>

      <!-- 2. Operations by Operator -->
      <v-col cols="12" lg="4">
        <OperatorDistributionChart />
      </v-col>
    </v-row>

    <v-row class="mb-4">
      <!-- 3. License Status Donut -->
      <v-col cols="12" md="4">
        <LicenseStatusChart />
      </v-col>

      <!-- 4. SIM Status Donut -->
      <v-col cols="12" md="4">
        <SimStatusChart />
      </v-col>

      <!-- 5. Revenue Trends -->
      <v-col cols="12" md="4">
        <RevenueChart />
      </v-col>
    </v-row>

    <v-row class="mb-4">
      <!-- 7. Operations Heatmap -->
      <v-col cols="12" lg="7">
        <OperationsHeatmap />
      </v-col>

      <!-- Real-Time System Health Section -->
      <v-col cols="12" lg="5">
        <SystemHealthWidget />
      </v-col>
    </v-row>

    <!-- Live Activity Timeline Stream -->
    <v-row>
      <v-col cols="12">
        <LiveActivityWidget />
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useOperationStore } from '@/stores/operation.store';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import MetricCard from '@/components/common/MetricCard.vue';
import DateRangePicker from '@/components/common/DateRangePicker.vue';
import OperationsChart from '@/components/dashboard/OperationsChart.vue';
import OperatorDistributionChart from '@/components/dashboard/OperatorDistributionChart.vue';
import LicenseStatusChart from '@/components/dashboard/LicenseStatusChart.vue';
import SimStatusChart from '@/components/dashboard/SimStatusChart.vue';
import RevenueChart from '@/components/dashboard/RevenueChart.vue';
import OperationsHeatmap from '@/components/dashboard/OperationsHeatmap.vue';
import SystemHealthWidget from '@/components/dashboard/SystemHealthWidget.vue';
import LiveActivityWidget from '@/components/dashboard/LiveActivityWidget.vue';

const operationStore = useOperationStore();
const { kpis } = storeToRefs(operationStore);
const selectedPeriod = ref('7d');

onMounted(() => {
  operationStore.fetchKPIs();
});
</script>
