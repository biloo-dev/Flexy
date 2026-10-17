<template>
  <v-card class="base-data-table overflow-hidden border">
    <!-- Optional Table Header / Toolbar slot -->
    <div v-if="$slots.header" class="pa-4 border-b bg-surface">
      <slot name="header" />
    </div>

    <!-- Data Table Container -->
    <v-table hover density="comfortable" class="w-100">
      <thead>
        <tr class="bg-surface-variant">
          <th
            v-for="header in headers"
            :key="header.key"
            :class="[
              header.align ? `text-${header.align}` : 'text-start',
              'text-caption font-weight-bold text-uppercase tracking-wider py-3'
            ]"
            :style="{ width: header.width }"
          >
            {{ header.title }}
          </th>
        </tr>
      </thead>
      <tbody>
        <!-- Loading Skeleton -->
        <template v-if="loading">
          <tr v-for="i in 5" :key="`skeleton-${i}`">
            <td v-for="h in headers" :key="`skel-col-${h.key}`" class="py-4">
              <v-skeleton-loader type="text" height="20" class="bg-transparent" />
            </td>
          </tr>
        </template>

        <!-- Empty State -->
        <template v-else-if="!items || items.length === 0">
          <tr>
            <td :colspan="headers.length" class="pa-0">
              <slot name="empty">
                <EmptyState />
              </slot>
            </td>
          </tr>
        </template>

        <!-- Data Rows -->
        <template v-else>
          <tr
            v-for="(item, index) in items"
            :key="item.id || index"
            class="table-row cursor-pointer"
            @click="$emit('row-click', item)"
          >
            <td
              v-for="header in headers"
              :key="header.key"
              :class="header.align ? `text-${header.align}` : 'text-start'"
              class="py-3"
            >
              <slot :name="`item.${header.key}`" :item="item" :index="index">
                {{ item[header.key] }}
              </slot>
            </td>
          </tr>
        </template>
      </tbody>
    </v-table>

    <!-- Pagination Footer -->
    <div
      v-if="showPagination && total > 0"
      class="d-flex flex-wrap align-center justify-space-between pa-4 border-t bg-surface"
    >
      <div class="text-caption text-medium-emphasis mb-2 mb-sm-0">
        Showing {{ paginationStart }} to {{ paginationEnd }} of {{ total }} entries
      </div>
      
      <div class="d-flex align-center ga-2">
        <v-pagination
          v-model="currentPage"
          :length="totalPages"
          :total-visible="5"
          density="compact"
          size="small"
          @update:model-value="onPageChange"
        />
      </div>
    </div>
  </v-card>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import EmptyState from './EmptyState.vue';

export interface TableHeader {
  title: string;
  key: string;
  align?: 'start' | 'center' | 'end';
  width?: string;
  sortable?: boolean;
}

const props = withDefaults(
  defineProps<{
    headers: TableHeader[];
    items: any[];
    loading?: boolean;
    page?: number;
    limit?: number;
    total?: number;
    showPagination?: boolean;
  }>(),
  {
    loading: false,
    page: 1,
    limit: 10,
    total: 0,
    showPagination: true,
  }
);

const emit = defineEmits<{
  (e: 'update:page', page: number): void;
  (e: 'row-click', item: any): void;
}>();

const currentPage = computed({
  get: () => props.page,
  set: (val: number) => emit('update:page', val),
});

const totalPages = computed(() => {
  return Math.ceil((props.total || 0) / props.limit) || 1;
});

const paginationStart = computed(() => {
  if (props.total === 0) return 0;
  return (props.page - 1) * props.limit + 1;
});

const paginationEnd = computed(() => {
  return Math.min(props.page * props.limit, props.total);
});

const onPageChange = (page: number) => {
  emit('update:page', page);
};
</script>

<style scoped>
.tracking-wider {
  letter-spacing: 0.05em;
}
.table-row:hover {
  background-color: rgba(var(--v-theme-surface-variant), 0.35) !important;
}
</style>
