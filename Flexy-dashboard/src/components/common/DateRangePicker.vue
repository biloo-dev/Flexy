<template>
  <v-menu v-model="menu" :close-on-content-click="false" location="bottom end">
    <template #activator="{ props }">
      <v-btn
        v-bind="props"
        variant="outlined"
        density="compact"
        prepend-icon="mdi-calendar-range"
        class="text-caption font-weight-medium"
      >
        {{ selectedLabel }}
      </v-btn>
    </template>

    <v-card min-width="220" class="pa-2">
      <v-list density="compact" nav>
        <v-list-item
          v-for="range in predefinedRanges"
          :key="range.value"
          :active="modelValue === range.value"
          @click="selectRange(range.value, range.label)"
        >
          <v-list-item-title class="text-body-2">{{ range.label }}</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-card>
  </v-menu>
</template>

<script setup lang="ts">
import { ref } from 'vue';

defineProps<{
  modelValue: string;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', val: string): void;
}>();

const menu = ref(false);
const selectedLabel = ref('Time: All');

const predefinedRanges = [
  { label: 'All Time', value: 'all' },
  { label: 'Today (24h)', value: '24h' },
  { label: 'Last 7 Days', value: '7d' },
  { label: 'Last 30 Days', value: '30d' },
  { label: 'Last 90 Days', value: '90d' },
  { label: 'This Year (1y)', value: '1y' },
];

const selectRange = (value: string, label: string) => {
  selectedLabel.value = label;
  emit('update:modelValue', value);
  menu.value = false;
};
</script>
