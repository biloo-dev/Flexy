<template>
  <v-dialog v-model="isOpen" max-width="650" scrollable>
    <v-card class="global-search-modal overflow-hidden">
      <!-- Search Input Header -->
      <div class="pa-3 border-b d-flex align-center ga-2 bg-surface">
        <v-icon color="primary" size="22">mdi-magnify</v-icon>
        <input
          ref="inputRef"
          v-model="query"
          type="text"
          placeholder="Search customers, SIMs, ICCID last 4, IMEIs, devices, licenses, serials, payments, operations..."
          class="search-text-input flex-grow-1"
          @keydown.esc="isOpen = false"
        />
        <v-btn icon size="x-small" variant="text" @click="isOpen = false">
          <v-icon size="18">mdi-close</v-icon>
        </v-btn>
      </div>

      <!-- Results Area -->
      <v-card-text class="pa-0" style="max-height: 480px;">
        <div v-if="!query" class="pa-6 text-center text-medium-emphasis">
          <v-icon size="36" class="mb-2 opacity-50">mdi-text-box-search-outline</v-icon>
          <div class="text-body-2">Type any keyword, ICCID, IMEI, phone number, or ID...</div>
          <div class="d-flex justify-center ga-2 mt-4">
            <v-chip size="x-small" variant="outlined" @click="query = 'Ahmed'">Ahmed</v-chip>
            <v-chip size="x-small" variant="outlined" @click="query = '0770'">0770</v-chip>
            <v-chip size="x-small" variant="outlined" @click="query = 'DVC-001'">DVC-001</v-chip>
            <v-chip size="x-small" variant="outlined" @click="query = 'LIC-'">LIC-</v-chip>
            <v-chip size="x-small" variant="outlined" @click="query = 'FLX-'">FLX-</v-chip>
          </div>
        </div>

        <div v-else-if="filteredResults.length === 0" class="pa-8 text-center text-medium-emphasis">
          <v-icon size="36" color="warning" class="mb-2">mdi-database-alert-outline</v-icon>
          <div class="text-body-1 font-weight-bold">No results found for "{{ query }}"</div>
          <div class="text-caption">Try searching by partial name, last 4 digits of ICCID, or serial prefix.</div>
        </div>

        <!-- Search Results Groups -->
        <v-list v-else lines="two" density="comfortable" class="pa-2">
          <v-list-item
            v-for="item in filteredResults"
            :key="item.id + item.category"
            class="rounded-lg mb-1 search-result-item"
            @click="navigate(item.link)"
          >
            <template #prepend>
              <v-avatar :color="item.color" variant="tonal" size="36" rounded="md">
                <v-icon size="20">{{ item.icon }}</v-icon>
              </v-avatar>
            </template>

            <v-list-item-title class="d-flex align-center justify-space-between">
              <span class="font-weight-bold text-body-2">{{ item.title }}</span>
              <v-chip size="x-small" :color="item.color" variant="tonal" class="text-capitalize">
                {{ item.category }}
              </v-chip>
            </v-list-item-title>

            <v-list-item-subtitle class="text-caption text-medium-emphasis mt-1">
              {{ item.subtitle }}
            </v-list-item-subtitle>
          </v-list-item>
        </v-list>
      </v-card-text>

      <!-- Footer Info -->
      <div class="pa-2 px-4 border-t bg-surface-variant d-flex align-center justify-space-between text-caption text-medium-emphasis">
        <div class="d-flex align-center ga-3">
          <span><kbd>ESC</kbd> to close</span>
          <span><kbd>ENTER</kbd> to select</span>
        </div>
        <div>
          <span>{{ filteredResults.length }} matching items</span>
        </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  mockCustomers,
  mockSimCards,
  mockModems,
  mockDevices,
  mockLicenses,
  mockPayments,
  mockOperations,
} from '@/api/mock/mockData';

const props = defineProps<{
  modelValue: boolean;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void;
}>();

const router = useRouter();
const query = ref('');
const inputRef = ref<HTMLInputElement | null>(null);

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
});

watch(isOpen, (val) => {
  if (val) {
    query.value = '';
    nextTick(() => {
      inputRef.value?.focus();
    });
  }
});

// Global Keyboard Shortcut: Ctrl + K
const handleGlobalKeydown = (e: KeyboardEvent) => {
  if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
    e.preventDefault();
    isOpen.value = !isOpen.value;
  }
};

onMounted(() => {
  window.addEventListener('keydown', handleGlobalKeydown);
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleGlobalKeydown);
});

interface SearchResult {
  id: string;
  category: string;
  title: string;
  subtitle: string;
  icon: string;
  color: string;
  link: string;
}

const filteredResults = computed<SearchResult[]>(() => {
  const q = query.value.trim().toLowerCase();
  if (!q) return [];

  const results: SearchResult[] = [];

  // 1. Customers
  mockCustomers.forEach((c) => {
    if (
      c.name.toLowerCase().includes(q) ||
      c.email.toLowerCase().includes(q) ||
      c.phone.includes(q) ||
      c.id.toLowerCase().includes(q) ||
      (c.company && c.company.toLowerCase().includes(q))
    ) {
      results.push({
        id: c.id,
        category: 'Customer',
        title: c.name,
        subtitle: `${c.phone} • ${c.email} • ${c.company || c.address}`,
        icon: 'mdi-account',
        color: 'primary',
        link: `/customers/${c.id}`,
      });
    }
  });

  // 2. SIM Cards & ICCID
  mockSimCards.forEach((s) => {
    const iccidLast4 = s.iccid.slice(-4);
    if (
      s.phoneNumber.includes(q) ||
      s.iccid.includes(q) ||
      iccidLast4.includes(q) ||
      s.customerName.toLowerCase().includes(q) ||
      s.id.toLowerCase().includes(q)
    ) {
      results.push({
        id: s.id,
        category: 'SIM Card',
        title: `${s.operator} - ${s.phoneNumber}`,
        subtitle: `ICCID: ••••••••••${iccidLast4} • Customer: ${s.customerName} (${s.status})`,
        icon: 'mdi-sim',
        color: s.operator === 'MOBILIS' ? 'success' : s.operator === 'DJEZZY' ? 'error' : 'accent',
        link: `/sim-cards/${s.id}`,
      });
    }
  });

  // 3. Modems & IMEI
  mockModems.forEach((m) => {
    if (
      m.imei.includes(q) ||
      m.name.toLowerCase().includes(q) ||
      m.manufacturer.toLowerCase().includes(q) ||
      m.model.toLowerCase().includes(q) ||
      m.id.toLowerCase().includes(q)
    ) {
      results.push({
        id: m.id,
        category: 'Modem',
        title: `${m.name} (${m.model})`,
        subtitle: `IMEI: ${m.imei} • Port: ${m.port} • Device: ${m.boundDeviceName}`,
        icon: 'mdi-router-wireless',
        color: 'secondary',
        link: `/modems/${m.id}`,
      });
    }
  });

  // 4. Devices
  mockDevices.forEach((d) => {
    if (
      d.name.toLowerCase().includes(q) ||
      d.uuid.toLowerCase().includes(q) ||
      d.id.toLowerCase().includes(q) ||
      d.ipAddress.includes(q) ||
      d.customerName.toLowerCase().includes(q)
    ) {
      results.push({
        id: d.id,
        category: 'Device',
        title: d.name,
        subtitle: `ID: ${d.id} • UUID: ${d.uuid.substring(0, 8)}... • IP: ${d.ipAddress}`,
        icon: 'mdi-laptop',
        color: 'info',
        link: `/devices/${d.id}`,
      });
    }
  });

  // 5. Licenses & Serials
  mockLicenses.forEach((l) => {
    if (
      l.serialNumber.toLowerCase().includes(q) ||
      l.id.toLowerCase().includes(q) ||
      l.customerName.toLowerCase().includes(q) ||
      l.simPhone.includes(q)
    ) {
      results.push({
        id: l.id,
        category: 'License',
        title: `${l.id} - ${l.maskedSerial}`,
        subtitle: `Ed25519 Key: ${l.keyId} • Status: ${l.status} • Exp: ${new Date(l.expiresAt).toLocaleDateString()}`,
        icon: 'mdi-key-chain',
        color: 'warning',
        link: `/licenses/${l.id}`,
      });
    }
  });

  // 6. Payments
  mockPayments.forEach((p) => {
    if (
      p.reference.toLowerCase().includes(q) ||
      p.customerName.toLowerCase().includes(q) ||
      p.id.toLowerCase().includes(q)
    ) {
      results.push({
        id: p.id,
        category: 'Payment',
        title: p.reference,
        subtitle: `${p.amount.toLocaleString()} ${p.currency} • ${p.customerName} (${p.status})`,
        icon: 'mdi-cash-multiple',
        color: 'success',
        link: `/payments/${p.id}`,
      });
    }
  });

  // 7. Operations
  mockOperations.forEach((op) => {
    if (
      op.operationCode.toLowerCase().includes(q) ||
      op.targetPhone.includes(q) ||
      op.id.toLowerCase().includes(q) ||
      op.idempotencyKey.toLowerCase().includes(q)
    ) {
      results.push({
        id: op.id,
        category: 'Operation',
        title: `${op.operationCode} (${op.amount} ${op.currency})`,
        subtitle: `Target: ${op.targetPhone} • ${op.operator} • Status: ${op.status}`,
        icon: 'mdi-swap-horizontal-bold',
        color: op.status === 'success' ? 'success' : 'error',
        link: `/operations/${op.id}`,
      });
    }
  });

  return results.slice(0, 15);
});

const navigate = (link: string) => {
  isOpen.value = false;
  router.push(link);
};
</script>

<style scoped>
.search-text-input {
  border: none;
  outline: none;
  background: transparent;
  color: inherit;
  font-size: 15px;
  width: 100%;
}
.search-result-item:hover {
  background-color: rgba(var(--v-theme-primary), 0.08);
  cursor: pointer;
}
kbd {
  background-color: rgba(var(--v-theme-surface-variant), 0.9);
  padding: 2px 5px;
  border-radius: 4px;
  border: 1px solid rgba(var(--v-border-color), 0.3);
  font-size: 10px;
}
</style>
