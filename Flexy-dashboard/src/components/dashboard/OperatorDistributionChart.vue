<template>
  <v-card class="pa-4 fill-height border">
    <div class="mb-2">
      <h3 class="text-subtitle-1 font-weight-bold">Operations by Operator</h3>
      <p class="text-caption text-medium-emphasis mb-0">Share of Flexi transactions across operators</p>
    </div>

    <div style="height: 250px; width: 100%;">
      <v-chart :option="chartOption" autoresize />
    </div>
  </v-card>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useThemeMode } from '@/composables/useThemeMode';

const { isDark } = useThemeMode();

const chartOption = computed(() => {
  const textColor = isDark.value ? '#94A3B8' : '#64748B';

  return {
    tooltip: {
      trigger: 'item',
      formatter: '{b}: {c} ops ({d}%)',
      backgroundColor: isDark.value ? '#1E293B' : '#FFFFFF',
      borderColor: isDark.value ? '#334155' : '#E2E8F0',
      textStyle: { color: isDark.value ? '#F8FAFC' : '#0F172A' },
    },
    legend: {
      bottom: 0,
      textStyle: { color: textColor, fontSize: 12 },
    },
    series: [
      {
        name: 'Operator Operations',
        type: 'pie',
        radius: ['50%', '75%'],
        center: ['50%', '45%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 6,
          borderColor: isDark.value ? '#0B1120' : '#FFFFFF',
          borderWidth: 2,
        },
        label: {
          show: false,
          position: 'center',
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 16,
            fontWeight: 'bold',
            color: isDark.value ? '#F8FAFC' : '#0F172A',
          },
        },
        labelLine: {
          show: false,
        },
        data: [
          { value: 58940, name: 'Mobilis (ATM)', itemStyle: { color: '#10B981' } },
          { value: 45280, name: 'Djezzy', itemStyle: { color: '#EF4444' } },
          { value: 38710, name: 'Ooredoo', itemStyle: { color: '#E11D48' } },
        ],
      },
    ],
  };
});
</script>
