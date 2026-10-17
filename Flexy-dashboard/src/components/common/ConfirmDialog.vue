<template>
  <v-dialog v-model="isOpen" max-width="480" persistent>
    <v-card class="pa-4">
      <div class="d-flex align-start ga-3 mb-3">
        <v-avatar :color="color" variant="tonal" size="40">
          <v-icon :size="22">{{ icon }}</v-icon>
        </v-avatar>
        <div>
          <h3 class="text-h6 font-weight-bold mb-1">{{ title }}</h3>
          <p class="text-body-2 text-medium-emphasis mb-0">{{ message }}</p>
        </div>
      </div>

      <slot />

      <v-card-actions class="px-0 pt-4 d-flex justify-end ga-2">
        <v-btn
          variant="outlined"
          :disabled="loading"
          @click="cancel"
        >
          {{ cancelText }}
        </v-btn>
        <v-btn
          :color="color"
          variant="flat"
          :loading="loading"
          @click="confirm"
        >
          {{ confirmText }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = withDefaults(
  defineProps<{
    modelValue: boolean;
    title: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
    color?: string;
    icon?: string;
    loading?: boolean;
  }>(),
  {
    confirmText: 'Confirm',
    cancelText: 'Cancel',
    color: 'primary',
    icon: 'mdi-help-circle-outline',
    loading: false,
  }
);

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void;
  (e: 'confirm'): void;
  (e: 'cancel'): void;
}>();

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
});

const confirm = () => emit('confirm');
const cancel = () => {
  emit('cancel');
  isOpen.value = false;
};
</script>
