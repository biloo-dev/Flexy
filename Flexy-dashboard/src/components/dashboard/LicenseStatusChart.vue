<template>
  <v-card class="pa-4 fill-height border">
    <div class="mb-2">
      <h3 class="text-subtitle-1 font-weight-bold">License Status</h3>
      <p class="text-caption text-medium-emphasis mb-0">Active cryptographic authorizations</p>
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
      formatter: '{b}: {c} ({d}%)',
      backgroundColor: isDark.value ? '#1E293B' : '#FFFFFF',
      borderColor: isDark.value ? '#334155' : '#E2E8F0',
      textStyle: { color: isDark.value ? '#F8FAFC' : '#0F172A' },
    },
    legend: {
      bottom: 0,
      textStyle: { color: textColor, fontSize: 11 },
    },
    series: [
      {
        name: 'License Status',
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
        data: [
          { value: 972, name: 'Active', itemStyle: { color: '#10B981' } },
          { value: 24, name: 'Pending', itemStyle: { color: '#F59E0B' } },
          { value: 18, name: 'Expired', itemStyle: { color: '#64748B' } },
          { value: 12, name: 'Suspended', itemStyle: { color: '#0284C7' } },
          { value: 8, name: 'Revoked', itemStyle: { color: '#EF4444' } },
        ],
      },
    ],
  };
});
</script>
