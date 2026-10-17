<template>
  <v-card class="metric-card pa-4 fill-height" :class="{ 'cursor-pointer': !!to }" @click="handleClick">
    <div class="d-flex align-start justify-space-between mb-2">
      <div>
        <div class="text-caption font-weight-bold text-uppercase text-medium-emphasis tracking-wider">
          {{ title }}
        </div>
        <div class="text-h4 font-weight-bold mt-1 d-flex align-baseline ga-1">
          <span>{{ formattedValue }}</span>
          <span v-if="unit" class="text-caption font-weight-medium text-medium-emphasis">{{ unit }}</span>
        </div>
      </div>
      <v-avatar :color="color" variant="tonal" size="44" rounded="lg">
        <v-icon :size="24">{{ icon }}</v-icon>
      </v-avatar>
    </div>

    <div v-if="subtitle || change !== undefined" class="d-flex align-center justify-space-between mt-2 pt-2 border-t">
      <span v-if="subtitle" class="text-caption text-medium-emphasis">{{ subtitle }}</span>
      <div v-if="change !== undefined" class="d-flex align-center ga-1 text-caption font-weight-bold" :class="change >= 0 ? 'text-success' : 'text-error'">
        <v-icon size="14">{{ change >= 0 ? 'mdi-trending-up' : 'mdi-trending-down' }}</v-icon>
        <span>{{ change >= 0 ? '+' : '' }}{{ change }}%</span>
        <span class="text-medium-emphasis font-weight-regular text-caption">vs last mo</span>
      </div>
    </div>
  </v-card>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

const props = withDefaults(
  defineProps<{
    title: string;
    value: string | number;
    icon: string;
    color?: string;
    unit?: string;
    subtitle?: string;
    change?: number;
    to?: string;
  }>(),
  {
    color: 'primary',
  }
);

const formattedValue = computed(() => {
  if (typeof props.value === 'number') {
    return props.value.toLocaleString();
  }
  return props.value;
});

const handleClick = () => {
  if (props.to) {
    router.push(props.to);
  }
};
</script>

<style scoped>
.metric-card {
  transition: transform 0.18s ease, box-shadow 0.18s ease, border-color 0.18s ease;
  position: relative;
  overflow: hidden;
}
.metric-card:hover {
  transform: translateY(-2px);
  border-color: rgba(37, 99, 235, 0.4);
}
.cursor-pointer {
  cursor: pointer;
}
.tracking-wider {
  letter-spacing: 0.05em;
}
</style>
