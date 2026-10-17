<template>
  <v-app>
    <!-- Navigation Drawer (Sidebar) -->
    <v-navigation-drawer
      v-model="drawer"
      :rail="rail"
      permanent
      class="border-e app-sidebar"
      color="surface"
      elevation="0"
    >
      <!-- Brand / Logo Header -->
      <div class="d-flex align-center px-4 py-4 brand-container border-b">
        <v-avatar color="primary" variant="flat" size="36" rounded="lg" class="me-3">
          <v-icon color="white" size="20">mdi-lightning-bolt</v-icon>
        </v-avatar>
        <div v-if="!rail" class="brand-text">
          <div class="text-subtitle-1 font-weight-black text-primary line-height-1">FLEXY</div>
          <div class="text-caption text-medium-emphasis font-weight-medium" style="font-size: 10px;">
            LICENSE & TELECOM
          </div>
        </div>
      </div>

      <!-- Navigation Links -->
      <v-list density="compact" nav class="pa-2">
        <template v-for="(group, gIdx) in navigationGroups" :key="gIdx">
          <v-list-subheader
            v-if="!rail && group.subheader"
            class="text-uppercase text-caption font-weight-bold text-medium-emphasis tracking-wider mt-3 mb-1"
          >
            {{ group.subheader }}
          </v-list-subheader>

          <v-list-item
            v-for="item in group.items"
            :key="item.to"
            :to="item.to"
            :prepend-icon="item.icon"
            :title="item.title"
            rounded="lg"
            color="primary"
            class="mb-1"
          >
            <template v-if="item.badge && !rail" #append>
              <v-badge
                :content="item.badge"
                :color="item.badgeColor || 'primary'"
                inline
                size="small"
              />
            </template>
          </v-list-item>
        </template>
      </v-list>

      <!-- Sidebar Footer (Collapse Toggle) -->
      <template #append>
        <div class="pa-2 border-t">
          <v-btn
            block
            variant="text"
            size="small"
            :prepend-icon="rail ? 'mdi-chevron-right' : 'mdi-chevron-left'"
            class="text-caption font-weight-bold text-medium-emphasis"
            @click="rail = !rail"
          >
            <span v-if="!rail">Collapse Sidebar</span>
          </v-btn>
        </div>
      </template>
    </v-navigation-drawer>

    <!-- Top App Bar -->
    <v-app-bar elevation="0" class="border-b px-2" color="surface">
      <!-- Sidebar Toggle for Mobile / Small Screens -->
      <v-app-bar-nav-icon
        variant="text"
        size="small"
        @click="rail = !rail"
      />

      <!-- Global Search Trigger Button (Ctrl + K) -->
      <v-btn
        variant="outlined"
        density="comfortable"
        class="ms-2 search-bar-trigger d-none d-sm-flex align-center ga-2 text-none text-medium-emphasis"
        style="width: 260px; justify-content: space-between;"
        @click="showSearch = true"
      >
        <div class="d-flex align-center ga-2">
          <v-icon size="16">mdi-magnify</v-icon>
          <span class="text-caption">Search everything...</span>
        </div>
        <kbd class="shortcut-kbd">Ctrl K</kbd>
      </v-btn>

      <!-- Mobile Search Icon -->
      <v-btn
        icon
        size="small"
        variant="text"
        class="d-flex d-sm-none"
        @click="showSearch = true"
      >
        <v-icon size="20">mdi-magnify</v-icon>
      </v-btn>

      <v-spacer />

      <!-- Connection Status Indicator -->
      <div class="d-none d-md-flex align-center me-3 px-2 py-1 rounded-pill border bg-surface-variant ga-2">
        <OnlineIndicator :status="connectionStatus" :pulse="connectionStatus === 'connected'" />
        <span class="text-caption font-weight-medium text-capitalize">
          {{ connectionStatus }} ({{ pingMs }}ms)
        </span>
      </div>

      <!-- Language / Direction Switcher (LTR / RTL) -->
      <v-tooltip :text="`Switch to ${currentLanguage === 'en' ? 'Arabic (RTL)' : 'English (LTR)'}`" location="bottom">
        <template #activator="{ props }">
          <v-btn
            v-bind="props"
            icon
            size="small"
            variant="text"
            color="secondary"
            class="me-1"
            @click="toggleLanguage"
          >
            <span class="font-weight-bold text-caption">{{ currentLanguage === 'en' ? 'عربي' : 'EN' }}</span>
          </v-btn>
        </template>
      </v-tooltip>

      <!-- Dark / Light Theme Toggle -->
      <v-tooltip :text="`Switch to ${isDark ? 'Light' : 'Dark'} Mode`" location="bottom">
        <template #activator="{ props }">
          <v-btn
            v-bind="props"
            icon
            size="small"
            variant="text"
            color="secondary"
            class="me-1"
            @click="toggleTheme"
          >
            <v-icon size="20">{{ isDark ? 'mdi-white-balance-sunny' : 'mdi-moon-waning-crescent' }}</v-icon>
          </v-btn>
        </template>
      </v-tooltip>

      <!-- Notifications Menu -->
      <v-menu location="bottom end" :close-on-content-click="false">
        <template #activator="{ props }">
          <v-btn
            v-bind="props"
            icon
            size="small"
            variant="text"
            color="secondary"
            class="me-2"
          >
            <v-badge
              v-if="unreadNotifsCount > 0"
              :content="unreadNotifsCount"
              color="error"
              size="small"
            >
              <v-icon size="20">mdi-bell-outline</v-icon>
            </v-badge>
            <v-icon v-else size="20">mdi-bell-outline</v-icon>
          </v-btn>
        </template>

        <v-card width="360" class="pa-0 border">
          <div class="pa-3 border-b d-flex align-center justify-space-between bg-surface">
            <span class="text-subtitle-2 font-weight-bold">Notifications</span>
            <v-btn
              v-if="unreadNotifsCount > 0"
              variant="text"
              size="x-small"
              color="primary"
              @click="notificationStore.markAllAsRead"
            >
              Mark all read
            </v-btn>
          </div>

          <v-list lines="two" density="compact" class="pa-0" style="max-height: 320px; overflow-y: auto;">
            <v-list-item
              v-for="n in notifications"
              :key="n.id"
              :class="{ 'bg-surface-variant': !n.read }"
              class="border-b"
              @click="handleNotifClick(n)"
            >
              <template #prepend>
                <v-avatar :color="n.type" variant="tonal" size="30" class="me-2">
                  <v-icon size="16">
                    {{ n.type === 'error' ? 'mdi-alert-circle' : n.type === 'warning' ? 'mdi-alert' : 'mdi-information' }}
                  </v-icon>
                </v-avatar>
              </template>

              <v-list-item-title class="text-caption font-weight-bold">{{ n.title }}</v-list-item-title>
              <v-list-item-subtitle class="text-caption text-medium-emphasis">{{ n.message }}</v-list-item-subtitle>
              <template #append>
                <span class="text-caption text-medium-emphasis" style="font-size: 10px;">{{ n.timestamp }}</span>
              </template>
            </v-list-item>
          </v-list>
        </v-card>
      </v-menu>

      <!-- Admin User Profile Menu -->
      <v-menu location="bottom end">
        <template #activator="{ props }">
          <div v-bind="props" class="d-flex align-center ga-2 cursor-pointer px-2 py-1 rounded hover-bg">
            <EntityAvatar :name="authStore.user?.name || 'Admin User'" size="32" />
            <div class="d-none d-md-block text-start">
              <div class="text-caption font-weight-bold line-height-1">
                {{ authStore.user?.name || 'Admin' }}
              </div>
              <div class="text-caption text-medium-emphasis" style="font-size: 10px;">
                {{ authStore.user?.role || 'Super Admin' }}
              </div>
            </div>
            <v-icon size="16" class="text-medium-emphasis">mdi-chevron-down</v-icon>
          </div>
        </template>

        <v-card width="220" class="pa-2 border">
          <div class="pa-2 border-b mb-1">
            <div class="text-subtitle-2 font-weight-bold">{{ authStore.user?.name }}</div>
            <div class="text-caption text-medium-emphasis">{{ authStore.user?.email }}</div>
          </div>
          <v-list density="compact" nav>
            <v-list-item to="/settings" prepend-icon="mdi-cog-outline" title="Settings" />
            <v-list-item to="/settings/users" prepend-icon="mdi-account-group-outline" title="Users & Roles" />
            <v-divider class="my-1" />
            <v-list-item
              prepend-icon="mdi-logout"
              title="Log Out"
              color="error"
              @click="handleLogout"
            />
          </v-list>
        </v-card>
      </v-menu>
    </v-app-bar>

    <!-- Main Content View -->
    <v-main class="bg-background">
      <div class="pa-4 pa-md-6 content-wrapper">
        <slot />
      </div>
    </v-main>

    <!-- Global Search Modal (Ctrl + K) -->
    <GlobalSearchDialog v-model="showSearch" />

    <!-- Global Notification Snackbar -->
    <v-snackbar
      v-model="snackbar.show"
      :color="snackbar.color"
      :timeout="snackbar.timeout"
      location="bottom right"
    >
      {{ snackbar.text }}
      <template #actions>
        <v-btn variant="text" size="small" @click="snackbar.show = false">Close</v-btn>
      </template>
    </v-snackbar>
  </v-app>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth.store';
import { useNotificationStore } from '@/stores/notification.store';
import { useDirection } from '@/composables/useDirection';
import { useThemeMode } from '@/composables/useThemeMode';
import { useConnectionStatus } from '@/composables/useConnectionStatus';
import { storeToRefs } from 'pinia';
import OnlineIndicator from '@/components/common/OnlineIndicator.vue';
import EntityAvatar from '@/components/common/EntityAvatar.vue';
import GlobalSearchDialog from '@/components/common/GlobalSearchDialog.vue';

const router = useRouter();
const authStore = useAuthStore();
const notificationStore = useNotificationStore();
const { notifications, snackbar } = storeToRefs(notificationStore);

const { currentLanguage, toggleLanguage } = useDirection();
const { isDark, toggleTheme } = useThemeMode();
const { status: connectionStatus, pingMs } = useConnectionStatus();

const drawer = ref(true);
const rail = ref(false);
const showSearch = ref(false);

const unreadNotifsCount = computed(() => notifications.value.filter((n) => !n.read).length);

interface NavItem {
  title: string;
  to: string;
  icon: string;
  badge?: string;
  badgeColor?: string;
}

interface NavGroup {
  subheader?: string;
  items: NavItem[];
}

const navigationGroups: NavGroup[] = [
  {
    subheader: 'Overview',
    items: [
      { title: 'Dashboard', to: '/dashboard', icon: 'mdi-view-dashboard-outline' },
    ],
  },
  {
    subheader: 'Telecom Infrastructure',
    items: [
      { title: 'Customers', to: '/customers', icon: 'mdi-account-group-outline' },
      { title: 'Operators', to: '/operators', icon: 'mdi-cellphone-tower' },
      { title: 'SIM Cards', to: '/sim-cards', icon: 'mdi-sim', badge: '1,046' },
      { title: 'Modems', to: '/modems', icon: 'mdi-router-wireless' },
      { title: 'Devices', to: '/devices', icon: 'mdi-laptop' },
    ],
  },
  {
    subheader: 'Licenses & Revenue',
    items: [
      { title: 'Licenses', to: '/licenses', icon: 'mdi-key-chain', badge: '18 exp', badgeColor: 'warning' },
      { title: 'Expiring Licenses', to: '/licenses/expiring', icon: 'mdi-clock-alert-outline' },
      { title: 'Payments', to: '/payments', icon: 'mdi-cash-multiple' },
      { title: 'Activations', to: '/activations', icon: 'mdi-shield-check-outline' },
    ],
  },
  {
    subheader: 'Operations & Security',
    items: [
      { title: 'Flexi Operations', to: '/operations', icon: 'mdi-swap-horizontal-bold' },
      { title: 'Security Center', to: '/security', icon: 'mdi-shield-alert-outline', badge: 'Alerts', badgeColor: 'error' },
      { title: 'Security Events', to: '/security/events', icon: 'mdi-alert-octagon-outline' },
      { title: 'Heartbeat Monitor', to: '/monitoring', icon: 'mdi-heart-pulse' },
      { title: 'Audit Logs', to: '/audit', icon: 'mdi-file-document-outline' },
      { title: 'System Events', to: '/events', icon: 'mdi-bell-badge-outline' },
    ],
  },
  {
    subheader: 'Management',
    items: [
      { title: 'Key Management', to: '/settings/security/keys', icon: 'mdi-key-variant' },
      { title: 'Admin Users', to: '/settings/users', icon: 'mdi-account-cog-outline' },
      { title: 'Settings', to: '/settings', icon: 'mdi-cog-outline' },
    ],
  },
];

const handleNotifClick = (n: any) => {
  notificationStore.markAsRead(n.id);
  if (n.link) router.push(n.link);
};

const handleLogout = () => {
  authStore.logout();
  router.push('/login');
};
</script>

<style scoped>
.app-sidebar {
  transition: width 0.2s ease;
}
.line-height-1 {
  line-height: 1.1;
}
.tracking-wider {
  letter-spacing: 0.08em;
}
.cursor-pointer {
  cursor: pointer;
}
.hover-bg:hover {
  background-color: rgba(var(--v-theme-surface-variant), 0.5);
}
.shortcut-kbd {
  font-size: 10px;
  padding: 2px 5px;
  border-radius: 4px;
  background: rgba(var(--v-theme-surface-variant), 0.9);
  border: 1px solid rgba(var(--v-border-color), 0.3);
}
.content-wrapper {
  max-width: 1600px;
  margin: 0 auto;
}
</style>
