<template>
  <div class="d-inline-flex align-center ga-1 font-family-monospace">
    <span class="text-body-2 font-weight-medium">
      {{ isRevealed ? rawValue : maskedValue }}
    </span>
    
    <!-- Reveal Toggle -->
    <v-tooltip text="Toggle visibility (Authorized Admins)" location="top">
      <template #activator="{ props }">
        <v-btn
          v-bind="props"
          icon
          size="x-small"
          variant="text"
          density="compact"
          color="secondary"
          @click="toggleReveal"
        >
          <v-icon size="16">{{ isRevealed ? 'mdi-eye-off-outline' : 'mdi-eye-outline' }}</v-icon>
        </v-btn>
      </template>
    </v-tooltip>

    <!-- Copy Button -->
    <CopyButton v-if="showCopy" :text="isRevealed ? rawValue : maskedValue" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import CopyButton from './CopyButton.vue';

const props = withDefaults(
  defineProps<{
    rawValue: string;
    visibleSuffixLength?: number;
    showCopy?: boolean;
  }>(),
  {
    visibleSuffixLength: 4,
    showCopy: true,
  }
);

const isRevealed = ref(false);

const maskedValue = computed(() => {
  if (!props.rawValue) return '••••';
  const len = props.rawValue.length;
  if (len <= props.visibleSuffixLength) return '••••';
  const suffix = props.rawValue.slice(-props.visibleSuffixLength);
  const bullets = '••••••••••';
  return `${bullets}${suffix}`;
});

const toggleReveal = () => {
  isRevealed.value = !isRevealed.value;
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
}
</style>
