<template>
  <v-card class="pa-4 fill-height border">
    <div class="d-flex flex-wrap align-center justify-space-between ga-2 mb-3">
      <div>
        <h3 class="text-subtitle-1 font-weight-bold">Revenue Trends</h3>
        <p class="text-caption text-medium-emphasis mb-0">Platform subscriptions & licensing income (DZD)</p>
      </div>

      <v-btn-toggle
        v-model="granularity"
        mandatory
        density="compact"
        variant="outlined"
        color="primary"
      >
        <v-btn value="daily" size="x-small">Daily</v-btn>
        <v-btn value="weekly" size="x-small">Weekly</v-btn>
        <v-btn value="monthly" size="x-small">Monthly</v-btn>
      </v-btn-toggle>
    </div>

    <div style="height: 260px; width: 100%;">
      <v-chart :option="chartOption" autoresize />
    </div>
  </v-card>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useThemeMode } from '@/composables/useThemeMode';

const { isDark } = useThemeMode();
const granularity = ref('monthly');

const chartData = computed(() => {
  switch (granularity.value) {
    case 'daily':
      return {
        categories: ['14 Aug', '15 Aug', '16 Aug', '17 Aug', '18 Aug', '19 Aug', '20 Aug'],
        values: [140000, 210000, 185000, 320000, 280000, 410000, 395000],
      };
    case 'weekly':
      return {
        categories: ['W29', 'W30', 'W31', 'W32', 'W33'],
        values: [1250000, 1420000, 1380000, 1690000, 1820000],
      };
    case 'monthly':
    default:
      return {
        categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'],
        values: [980000, 1150000, 1340000, 1420000, 1680000, 1890000, 2100000, 2450000],
      };
  }
});

const chartOption = computed(() => {
  const textColor = isDark.value ? '#94A3B8' : '#64748B';
  const splitLineColor = isDark.value ? '#1E293B' : '#F1F5F9';

  return {
    tooltip: {
      trigger: 'axis',
      formatter: (params: any) => {
        const item = params[0];
        return `${item.name}<br/><strong>${Number(item.value).toLocaleString()} DZD</strong>`;
      },
      backgroundColor: isDark.value ? '#1E293B' : '#FFFFFF',
      borderColor: isDark.value ? '#334155' : '#E2E8F0',
      textStyle: { color: isDark.value ? '#F8FAFC' : '#0F172A' },
    },
    grid: {
      top: '10%',
      left: '3%',
      right: '4%',
      bottom: '10%',
      containLabel: true,
    },
    xAxis: {
      type: 'category',
      data: chartData.value.categories,
      axisLine: { lineStyle: { color: splitLineColor } },
      axisLabel: { color: textColor },
    },
    yAxis: {
      type: 'value',
      axisLine: { show: false },
      splitLine: { lineStyle: { color: splitLineColor } },
      axisLabel: {
        color: textColor,
        formatter: (val: number) => `${(val / 1000).toFixed(0)}k`,
      },
    },
    series: [
      {
        name: 'Revenue',
        type: 'bar',
        barWidth: '40%',
        data: chartData.value.values,
        itemStyle: {
          color: {
            type: 'linear',
            x: 0,
            y: 0,
            x2: 0,
            y2: 1,
            colorStops: [
              { offset: 0, color: '#3B82F6' },
              { offset: 1, color: '#1D4ED8' },
            ],
          },
          borderRadius: [4, 4, 0, 0],
        },
      },
    ],
  };
});
</script>
