<template>
  <v-text-field
    v-model="modelValue"
    :placeholder="placeholder"
    prepend-inner-icon="mdi-magnify"
    clearable
    hide-details
    density="compact"
    variant="outlined"
    class="search-input"
    @click:clear="$emit('update:modelValue', '')"
  >
    <template v-if="showKbd" #append-inner>
      <kbd class="shortcut-badge">Ctrl + K</kbd>
    </template>
  </v-text-field>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = withDefaults(
  defineProps<{
    modelValue: string;
    placeholder?: string;
    showKbd?: boolean;
  }>(),
  {
    placeholder: 'Search...',
    showKbd: false,
  }
);

const emit = defineEmits<{
  (e: 'update:modelValue', val: string): void;
}>();

const modelValue = computed({
  get: () => props.modelValue,
  set: (val: string) => emit('update:modelValue', val || ''),
});
</script>

<style scoped>
.shortcut-badge {
  font-size: 10px;
  padding: 2px 6px;
  border-radius: 4px;
  background-color: rgba(var(--v-theme-surface-variant), 0.8);
  color: rgb(var(--v-theme-on-surface));
  border: 1px solid rgba(var(--v-border-color), 0.2);
  font-family: inherit;
}
</style>
