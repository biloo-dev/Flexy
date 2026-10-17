import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router';
import { useAuthStore } from '@/stores/auth.store';

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/auth/LoginView.vue'),
    meta: { layout: 'auth', public: true },
  },
  {
    path: '/',
    redirect: '/dashboard',
  },
  {
    path: '/dashboard',
    name: 'dashboard',
    component: () => import('@/views/dashboard/DashboardView.vue'),
  },
  {
    path: '/customers',
    name: 'customers',
    component: () => import('@/views/customers/CustomersListView.vue'),
  },
  {
    path: '/customers/:id',
    name: 'customer-detail',
    component: () => import('@/views/customers/CustomerDetailView.vue'),
  },
  {
    path: '/operators',
    name: 'operators',
    component: () => import('@/views/operators/OperatorsListView.vue'),
  },
  {
    path: '/sim-cards',
    name: 'sim-cards',
    component: () => import('@/views/sims/SimsListView.vue'),
  },
  {
    path: '/sim-cards/:id',
    name: 'sim-detail',
    component: () => import('@/views/sims/SimDetailView.vue'),
  },
  {
    path: '/modems',
    name: 'modems',
    component: () => import('@/views/modems/ModemsListView.vue'),
  },
  {
    path: '/modems/:id',
    name: 'modem-detail',
    component: () => import('@/views/modems/ModemDetailView.vue'),
  },
  {
    path: '/devices',
    name: 'devices',
    component: () => import('@/views/devices/DevicesListView.vue'),
  },
  {
    path: '/devices/:id',
    name: 'device-detail',
    component: () => import('@/views/devices/DeviceDetailView.vue'),
  },
  {
    path: '/licenses',
    name: 'licenses',
    component: () => import('@/views/licenses/LicensesListView.vue'),
  },
  {
    path: '/licenses/expiring',
    name: 'licenses-expiring',
    component: () => import('@/views/licenses/ExpiringLicensesView.vue'),
  },
  {
    path: '/licenses/:id',
    name: 'license-detail',
    component: () => import('@/views/licenses/LicenseDetailView.vue'),
  },
  {
    path: '/payments',
    name: 'payments',
    component: () => import('@/views/payments/PaymentsListView.vue'),
  },
  {
    path: '/payments/:id',
    name: 'payment-detail',
    component: () => import('@/views/payments/PaymentDetailView.vue'),
  },
  {
    path: '/activations',
    name: 'activations',
    component: () => import('@/views/activations/ActivationsListView.vue'),
  },
  {
    path: '/operations',
    name: 'operations',
    component: () => import('@/views/operations/OperationsListView.vue'),
  },
  {
    path: '/operations/:id',
    name: 'operation-detail',
    component: () => import('@/views/operations/OperationDetailView.vue'),
  },
  {
    path: '/security',
    name: 'security',
    component: () => import('@/views/security/SecurityOverviewView.vue'),
  },
  {
    path: '/security/events',
    name: 'security-events',
    component: () => import('@/views/security/SecurityEventsListView.vue'),
  },
  {
    path: '/monitoring',
    name: 'monitoring',
    component: () => import('@/views/monitoring/HeartbeatMonitorView.vue'),
  },
  {
    path: '/audit',
    name: 'audit',
    component: () => import('@/views/audit/AuditLogsListView.vue'),
  },
  {
    path: '/events',
    name: 'events',
    component: () => import('@/views/events/SystemEventsView.vue'),
  },
  {
    path: '/settings',
    name: 'settings',
    component: () => import('@/views/settings/SettingsGeneralView.vue'),
  },
  {
    path: '/settings/users',
    name: 'settings-users',
    component: () => import('@/views/settings/UsersManagementView.vue'),
  },
  {
    path: '/settings/security/keys',
    name: 'settings-keys',
    component: () => import('@/views/settings/KeyManagementView.vue'),
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/dashboard',
  },
];

export const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior() {
    return { top: 0 };
  },
});

router.beforeEach((to, _from, next) => {
  const authStore = useAuthStore();
  const isPublic = to.meta.public;

  const token = localStorage.getItem('flexi_auth_token');
  if (!isPublic && !token && !authStore.isAuthenticated) {
    return next('/login');
  }
  next();
});

export default router;
