<template>
  <v-card class="pa-4 fill-height border">
    <div class="mb-3">
      <h3 class="text-subtitle-1 font-weight-bold">Operations Hourly Heatmap</h3>
      <p class="text-caption text-medium-emphasis mb-0">Distribution of Flexi load across days of the week & hours (00:00 - 23:00)</p>
    </div>

    <div style="height: 260px; width: 100%;">
      <v-chart :option="chartOption" autoresize />
    </div>
  </v-card>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useThemeMode } from '@/composables/useThemeMode';

const { isDark } = useThemeMode();

const hours = ['00h', '02h', '04h', '06h', '08h', '10h', '12h', '14h', '16h', '18h', '20h', '22h'];
const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// Generate realistic heatmap matrix [hourIndex, dayIndex, value]
const data = computed(() => {
  const result: [number, number, number][] = [];
  for (let d = 0; d < 7; d++) {
    for (let h = 0; h < 12; h++) {
      let base = (h >= 4 && h <= 10) ? 65 : 15;
      if (d === 4 || d === 5) base += 20; // Weekend/Friday peak
      const val = Math.floor(base + Math.random() * 35);
      result.push([h, d, val]);
    }
  }
  return result;
});

const chartOption = computed(() => {
  const textColor = isDark.value ? '#94A3B8' : '#64748B';

  return {
    tooltip: {
      position: 'top',
      formatter: (params: any) => {
        return `${days[params.value[1]]} at ${hours[params.value[0]]}: <strong>${params.value[2]} ops/min</strong>`;
      },
      backgroundColor: isDark.value ? '#1E293B' : '#FFFFFF',
      borderColor: isDark.value ? '#334155' : '#E2E8F0',
      textStyle: { color: isDark.value ? '#F8FAFC' : '#0F172A' },
    },
    grid: {
      top: '5%',
      left: '4%',
      right: '4%',
      bottom: '18%',
      containLabel: true,
    },
    xAxis: {
      type: 'category',
      data: hours,
      splitArea: { show: true },
      axisLabel: { color: textColor, fontSize: 11 },
    },
    yAxis: {
      type: 'category',
      data: days,
      splitArea: { show: true },
      axisLabel: { color: textColor, fontSize: 11 },
    },
    visualMap: {
      min: 10,
      max: 120,
      calculable: false,
      orient: 'horizontal',
      left: 'center',
      bottom: '0%',
      inRange: {
        color: isDark.value
          ? ['#1E293B', '#1E3A8A', '#2563EB', '#38BDF8']
          : ['#F1F5F9', '#93C5FD', '#2563EB', '#1E3A8A'],
      },
      textStyle: { color: textColor, fontSize: 11 },
    },
    series: [
      {
        name: 'Flexi Load',
        type: 'heatmap',
        data: data.value,
        label: { show: false },
        emphasis: {
          itemStyle: {
            shadowBlur: 10,
            shadowColor: 'rgba(0, 0, 0, 0.5)',
          },
        },
      },
    ],
  };
});
</script>
