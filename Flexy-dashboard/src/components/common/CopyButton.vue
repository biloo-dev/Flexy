<template>
  <v-tooltip :text="copied ? 'Copied!' : tooltip" location="top">
    <template #activator="{ props }">
      <v-btn
        v-bind="props"
        icon
        :size="size"
        variant="text"
        density="compact"
        :color="copied ? 'success' : 'secondary'"
        @click.stop="copyText"
      >
        <v-icon :size="iconSize">{{ copied ? 'mdi-check' : 'mdi-content-copy' }}</v-icon>
      </v-btn>
    </template>
  </v-tooltip>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const props = withDefaults(
  defineProps<{
    text: string;
    tooltip?: string;
    size?: 'x-small' | 'small' | 'default';
    iconSize?: number;
  }>(),
  {
    tooltip: 'Copy to clipboard',
    size: 'x-small',
    iconSize: 15,
  }
);

const copied = ref(false);

const copyText = async () => {
  if (!props.text) return;
  try {
    await navigator.clipboard.writeText(props.text);
    copied.value = true;
    setTimeout(() => {
      copied.value = false;
    }, 2000);
  } catch (err) {
    console.error('Clipboard copy failed:', err);
  }
};
</script>
