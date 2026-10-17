<template>
  <slot v-if="isAllowed" />
  <slot v-else name="fallback" />
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { usePermissions } from '@/composables/usePermissions';

const props = defineProps<{
  permission?: string;
  permissions?: string[];
  requireAll?: boolean;
}>();

const { hasPermission, hasAnyPermission, hasAllPermissions } = usePermissions();

const isAllowed = computed(() => {
  if (props.permission) {
    return hasPermission(props.permission);
  }
  if (props.permissions && props.permissions.length > 0) {
    return props.requireAll
      ? hasAllPermissions(props.permissions)
      : hasAnyPermission(props.permissions);
  }
  return true;
});
</script>
