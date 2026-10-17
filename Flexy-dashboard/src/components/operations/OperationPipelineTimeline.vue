<template>
  <v-card class="pa-4 border">
    <div class="d-flex align-center justify-space-between mb-4">
      <div>
        <h3 class="text-subtitle-1 font-weight-bold">Verification Pipeline & Execution Lifecycle</h3>
        <p class="text-caption text-medium-emphasis mb-0">
          Step-by-step diagnostic breakdown for request execution
        </p>
      </div>
      <v-chip
        :color="allPassed ? 'success' : 'error'"
        variant="tonal"
        size="small"
        class="font-weight-bold"
      >
        <v-icon start size="14">{{ allPassed ? 'mdi-check-all' : 'mdi-alert-circle' }}</v-icon>
        {{ allPassed ? 'Pipeline Verified' : 'Pipeline Blocked / Failed' }}
      </v-chip>
    </div>

    <div class="pipeline-steps">
      <div
        v-for="(step, index) in steps"
        :key="step.name"
        class="step-item d-flex align-start ga-3 py-2"
        :class="{ 'step-failed': step.status === 'failed', 'step-skipped': step.status === 'skipped' }"
      >
        <!-- Step Icon / Indicator -->
        <div class="step-indicator-col d-flex flex-column align-center">
          <v-avatar
            :color="getStepColor(step.status)"
            :variant="step.status === 'passed' ? 'tonal' : 'flat'"
            size="28"
          >
            <v-icon size="14" :color="step.status === 'passed' ? 'success' : '#FFFFFF'">
              {{ getStepIcon(step.status) }}
            </v-icon>
          </v-avatar>
          <div v-if="index < steps.length - 1" class="step-connector"></div>
        </div>

        <!-- Step Body -->
        <div class="step-body flex-grow-1 pb-2">
          <div class="d-flex align-center justify-space-between ga-2">
            <span class="text-body-2 font-weight-bold" :class="getStepTextClass(step.status)">
              {{ step.name }}
            </span>
            <span v-if="step.timestamp" class="text-caption font-family-monospace text-medium-emphasis">
              {{ step.timestamp }}
            </span>
          </div>
          <p class="text-caption text-medium-emphasis mb-1">
            {{ step.description }}
          </p>
          <div v-if="step.details" class="step-details-box pa-2 rounded text-caption mt-1">
            <strong>Diagnostic Trace:</strong> {{ step.details }}
          </div>
        </div>
      </div>
    </div>
  </v-card>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { VerificationStep } from '@/types';

const props = defineProps<{
  steps: VerificationStep[];
}>();

const allPassed = computed(() => {
  return props.steps.every((s) => s.status === 'passed');
});

const getStepColor = (status: string) => {
  switch (status) {
    case 'passed':
      return 'success';
    case 'failed':
      return 'error';
    case 'skipped':
      return 'grey';
    default:
      return 'warning';
  }
};

const getStepIcon = (status: string) => {
  switch (status) {
    case 'passed':
      return 'mdi-check';
    case 'failed':
      return 'mdi-close';
    case 'skipped':
      return 'mdi-minus';
    default:
      return 'mdi-clock-outline';
  }
};

const getStepTextClass = (status: string) => {
  switch (status) {
    case 'passed':
      return 'text-success';
    case 'failed':
      return 'text-error';
    case 'skipped':
      return 'text-medium-emphasis';
    default:
      return 'text-warning';
  }
};
</script>

<style scoped>
.step-indicator-col {
  min-width: 28px;
}
.step-connector {
  width: 2px;
  flex-grow: 1;
  min-height: 22px;
  background-color: rgba(var(--v-border-color), 0.25);
  margin: 4px 0;
}
.step-details-box {
  background-color: rgba(var(--v-theme-error), 0.08);
  border-left: 3px solid rgb(var(--v-theme-error));
  color: rgb(var(--v-theme-error));
}
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
