<template>
  <v-card class="pa-4 fill-height border">
    <div class="d-flex flex-wrap align-center justify-space-between ga-2 mb-3">
      <div>
        <h3 class="text-subtitle-1 font-weight-bold">Flexi Operations Overview</h3>
        <p class="text-caption text-medium-emphasis mb-0">Transaction volume & delivery performance</p>
      </div>

      <!-- Time Range Toggle -->
      <v-btn-toggle
        v-model="timeRange"
        mandatory
        density="compact"
        variant="outlined"
        color="primary"
      >
        <v-btn value="24h" size="x-small">24h</v-btn>
        <v-btn value="7d" size="x-small">7d</v-btn>
        <v-btn value="30d" size="x-small">30d</v-btn>
        <v-btn value="90d" size="x-small">90d</v-btn>
        <v-btn value="1y" size="x-small">1y</v-btn>
      </v-btn-toggle>
    </div>

    <!-- Chart -->
    <div style="height: 280px; width: 100%;">
      <v-chart :option="chartOption" autoresize />
    </div>
  </v-card>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useThemeMode } from '@/composables/useThemeMode';

const { isDark } = useThemeMode();
const timeRange = ref('7d');

const chartData = computed(() => {
  switch (timeRange.value) {
    case '24h':
      return {
        categories: ['00:00', '03:00', '06:00', '09:00', '12:00', '15:00', '18:00', '21:00'],
        success: [120, 45, 80, 450, 780, 920, 1100, 650],
        failed: [4, 1, 2, 8, 12, 15, 18, 9],
        blocked: [1, 0, 0, 3, 5, 4, 6, 2],
      };
    case '30d':
      return {
        categories: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
        success: [14200, 16800, 15400, 18900],
        failed: [180, 210, 195, 230],
        blocked: [45, 60, 52, 68],
      };
    case '90d':
      return {
        categories: ['May', 'Jun', 'Jul'],
        success: [54000, 62000, 71000],
        failed: [620, 740, 810],
        blocked: [180, 210, 240],
      };
    case '1y':
      return {
        categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'],
        success: [32000, 38000, 44000, 51000, 58000, 65000, 72000, 79000],
        failed: [400, 450, 520, 590, 660, 730, 800, 850],
        blocked: [110, 130, 160, 180, 200, 230, 250, 280],
      };
    case '7d':
    default:
      return {
        categories: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        success: [2400, 2800, 3100, 3400, 4100, 3800, 4300],
        failed: [28, 32, 25, 40, 48, 35, 30],
        blocked: [8, 12, 6, 14, 18, 10, 9],
      };
  }
});

const chartOption = computed(() => {
  const textColor = isDark.value ? '#94A3B8' : '#64748B';
  const splitLineColor = isDark.value ? '#1E293B' : '#F1F5F9';

  return {
    tooltip: {
      trigger: 'axis',
      backgroundColor: isDark.value ? '#1E293B' : '#FFFFFF',
      borderColor: isDark.value ? '#334155' : '#E2E8F0',
      textStyle: { color: isDark.value ? '#F8FAFC' : '#0F172A' },
    },
    legend: {
      bottom: 0,
      textStyle: { color: textColor, fontSize: 12 },
      itemGap: 20,
    },
    grid: {
      top: '12%',
      left: '3%',
      right: '4%',
      bottom: '15%',
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
      axisLabel: { color: textColor },
    },
    series: [
      {
        name: 'Successful',
        type: 'line',
        smooth: true,
        data: chartData.value.success,
        itemStyle: { color: '#10B981' },
        areaStyle: {
          color: {
            type: 'linear',
            x: 0,
            y: 0,
            x2: 0,
            y2: 1,
            colorStops: [
              { offset: 0, color: 'rgba(16, 185, 129, 0.25)' },
              { offset: 1, color: 'rgba(16, 185, 129, 0.0)' },
            ],
          },
        },
      },
      {
        name: 'Failed',
        type: 'line',
        smooth: true,
        data: chartData.value.failed,
        itemStyle: { color: '#EF4444' },
      },
      {
        name: 'Blocked (Security)',
        type: 'line',
        smooth: true,
        data: chartData.value.blocked,
        itemStyle: { color: '#F59E0B' },
      },
    ],
  };
});
</script>
