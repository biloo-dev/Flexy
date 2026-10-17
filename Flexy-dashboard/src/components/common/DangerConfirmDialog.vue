<template>
  <v-dialog v-model="isOpen" max-width="520" persistent>
    <v-card class="pa-5 border-error">
      <div class="d-flex align-start ga-3 mb-3">
        <v-avatar color="error" variant="tonal" size="44">
          <v-icon size="26">mdi-alert-octagon</v-icon>
        </v-avatar>
        <div>
          <h3 class="text-h6 font-weight-bold text-error mb-1">{{ title }}</h3>
          <p class="text-body-2 text-medium-emphasis mb-0">{{ message }}</p>
        </div>
      </div>

      <!-- Critical Warning Box -->
      <v-alert
        color="error"
        variant="tonal"
        icon="mdi-shield-alert"
        class="my-3 text-caption font-weight-medium"
      >
        {{ warningText || 'This action is irreversible. It will immediately disconnect services and revoke cryptographic authorizations.' }}
      </v-alert>

      <!-- Type-to-confirm input if required -->
      <div v-if="requiredText" class="mt-3">
        <label class="text-caption font-weight-bold d-block mb-1">
          To proceed, type <span class="text-error font-weight-black font-family-monospace">{{ requiredText }}</span> below:
        </label>
        <v-text-field
          v-model="typedConfirmation"
          placeholder="Type here..."
          variant="outlined"
          density="compact"
          :error="typedConfirmation.length > 0 && typedConfirmation !== requiredText"
          autofocus
        />
      </div>

      <slot />

      <v-card-actions class="px-0 pt-4 d-flex justify-end ga-2">
        <v-btn
          variant="outlined"
          :disabled="loading"
          @click="cancel"
        >
          Cancel
        </v-btn>
        <v-btn
          color="error"
          variant="flat"
          :loading="loading"
          :disabled="isConfirmDisabled"
          @click="confirm"
        >
          {{ confirmText }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';

const props = withDefaults(
  defineProps<{
    modelValue: boolean;
    title: string;
    message: string;
    warningText?: string;
    requiredText?: string; // e.g. 'REVOKE'
    confirmText?: string;
    loading?: boolean;
  }>(),
  {
    confirmText: 'Execute Danger Action',
    loading: false,
  }
);

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void;
  (e: 'confirm'): void;
  (e: 'cancel'): void;
}>();

const typedConfirmation = ref('');

watch(
  () => props.modelValue,
  (val) => {
    if (val) typedConfirmation.value = '';
  }
);

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
});

const isConfirmDisabled = computed(() => {
  if (!props.requiredText) return false;
  return typedConfirmation.value !== props.requiredText;
});

const confirm = () => emit('confirm');
const cancel = () => {
  emit('cancel');
  isOpen.value = false;
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}
.border-error {
  border: 1px solid rgba(239, 68, 68, 0.4) !important;
}
</style>
