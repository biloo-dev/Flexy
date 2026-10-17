<template>
  <div class="users-management-view">
    <PageHeader
      title="Admin Users & Access Control (RBAC)"
      subtitle="Manage internal operations team roles, authorization levels, and granular permissions."
      :breadcrumbs="[
        { title: 'Dashboard', to: '/dashboard' },
        { title: 'Settings', to: '/settings' },
        { title: 'Admin Users' }
      ]"
    >
      <template #actions>
        <v-btn
          color="primary"
          prepend-icon="mdi-account-plus"
          class="font-weight-bold"
          @click="showAddUserModal = true"
        >
          Add Administrator
        </v-btn>
      </template>
    </PageHeader>

    <v-row>
      <!-- Sidebar -->
      <v-col cols="12" md="3">
        <v-card class="border pa-2">
          <v-list density="compact" nav>
            <v-list-item to="/settings" prepend-icon="mdi-tune" title="General Settings" />
            <v-list-item to="/settings/security/keys" prepend-icon="mdi-key-variant" title="Ed25519 Keys" />
            <v-list-item to="/settings/users" prepend-icon="mdi-account-cog" title="Admin Users & Roles" active />
          </v-list>
        </v-card>
      </v-col>

      <!-- Users & Roles List -->
      <v-col cols="12" md="9">
        <v-card class="pa-5 border">
          <h3 class="text-subtitle-1 font-weight-bold mb-4">Authorized Admin Accounts</h3>

          <v-table hover density="comfortable">
            <thead>
              <tr class="bg-surface-variant">
                <th class="text-caption font-weight-bold text-uppercase">Admin User</th>
                <th class="text-caption font-weight-bold text-uppercase">Role</th>
                <th class="text-caption font-weight-bold text-uppercase">Granular Permissions</th>
                <th class="text-caption font-weight-bold text-uppercase">Last Login</th>
                <th class="text-caption font-weight-bold text-uppercase text-end">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="user in adminUsers" :key="user.id">
                <td>
                  <div class="d-flex align-center ga-3">
                    <EntityAvatar :name="user.name" size="36" />
                    <div>
                      <div class="font-weight-bold text-body-2">{{ user.name }}</div>
                      <div class="text-caption text-medium-emphasis">{{ user.email }}</div>
                    </div>
                  </div>
                </td>
                <td>
                  <v-chip
                    :color="getRoleColor(user.role)"
                    size="small"
                    variant="tonal"
                    class="font-weight-bold"
                  >
                    {{ user.role }}
                  </v-chip>
                </td>
                <td>
                  <div class="d-flex flex-wrap ga-1" style="max-width: 280px;">
                    <v-chip
                      v-for="perm in user.permissions.slice(0, 3)"
                      :key="perm"
                      size="x-small"
                      variant="outlined"
                    >
                      {{ perm }}
                    </v-chip>
                    <v-chip
                      v-if="user.permissions.length > 3"
                      size="x-small"
                      variant="tonal"
                      color="secondary"
                    >
                      +{{ user.permissions.length - 3 }} more
                    </v-chip>
                  </div>
                </td>
                <td class="text-caption text-medium-emphasis">
                  {{ user.lastLoginAt ? new Date(user.lastLoginAt).toLocaleString() : 'Never' }}
                </td>
                <td class="text-end">
                  <v-btn
                    icon
                    size="x-small"
                    variant="text"
                    color="primary"
                    @click="openEditModal(user)"
                  >
                    <v-icon size="18">mdi-pencil-outline</v-icon>
                  </v-btn>
                </td>
              </tr>
            </tbody>
          </v-table>
        </v-card>
      </v-col>
    </v-row>

    <!-- Add / Edit User Modal -->
    <v-dialog v-model="showAddUserModal" max-width="540">
      <v-card class="pa-5">
        <h3 class="text-h6 font-weight-bold mb-4">{{ editingUser ? 'Edit Admin Permissions' : 'Invite New Administrator' }}</h3>
        <v-form @submit.prevent="handleSaveUser">
          <v-text-field
            v-if="!editingUser"
            v-model="newUser.name"
            label="Full Name"
            required
            class="mb-3"
          />
          <v-text-field
            v-if="!editingUser"
            v-model="newUser.email"
            label="Email Address"
            type="email"
            required
            class="mb-3"
          />
          <v-select
            v-model="selectedRole"
            :items="roleOptions"
            label="Administrative Role"
            required
            class="mb-4"
          />

          <div class="mb-3">
            <label class="text-caption font-weight-bold d-block mb-2">Granular Role Permissions:</label>
            <v-row dense>
              <v-col v-for="p in allPermissions" :key="p" cols="6">
                <v-checkbox
                  v-model="selectedPermissions"
                  :value="p"
                  :label="p"
                  density="compact"
                  hide-details
                />
              </v-col>
            </v-row>
          </div>

          <v-card-actions class="px-0 pt-3 d-flex justify-end ga-2">
            <v-btn variant="outlined" @click="showAddUserModal = false">Cancel</v-btn>
            <v-btn color="primary" type="submit">Save User</v-btn>
          </v-card-actions>
        </v-form>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useSettingsStore } from '@/stores/settings.store';
import { useNotificationStore } from '@/stores/notification.store';
import { storeToRefs } from 'pinia';
import PageHeader from '@/components/common/PageHeader.vue';
import EntityAvatar from '@/components/common/EntityAvatar.vue';
import type { AdminUser, AdminRole } from '@/types';

const settingsStore = useSettingsStore();
const notificationStore = useNotificationStore();
const { adminUsers } = storeToRefs(settingsStore);

const showAddUserModal = ref(false);
const editingUser = ref<AdminUser | null>(null);

const newUser = ref({ name: '', email: '' });
const selectedRole = ref<AdminRole>('Support');
const selectedPermissions = ref<string[]>([
  'customers.read',
  'sims.read',
  'licenses.read',
  'operations.read',
]);

const roleOptions: AdminRole[] = [
  'Super Admin',
  'Admin',
  'Support',
  'Finance',
  'Read Only',
];

const allPermissions = [
  'customers.read',
  'customers.write',
  'sims.read',
  'sims.write',
  'licenses.read',
  'licenses.create',
  'licenses.revoke',
  'licenses.renew',
  'payments.read',
  'payments.write',
  'operations.read',
  'security.read',
  'audit.read',
  'settings.manage',
];

onMounted(() => {
  settingsStore.fetchAdminUsers();
});

const getRoleColor = (role: AdminRole) => {
  switch (role) {
    case 'Super Admin': return 'primary';
    case 'Admin': return 'info';
    case 'Finance': return 'success';
    case 'Support': return 'warning';
    default: return 'secondary';
  }
};

const openEditModal = (user: AdminUser) => {
  editingUser.value = user;
  selectedRole.value = user.role;
  selectedPermissions.value = [...user.permissions];
  showAddUserModal.value = true;
};

const handleSaveUser = async () => {
  if (editingUser.value) {
    await settingsStore.updateUserRole(editingUser.value.id, selectedRole.value, selectedPermissions.value);
    notificationStore.showMessage(`User ${editingUser.value.name} updated`, 'success');
  } else {
    await settingsStore.createUser({
      name: newUser.value.name,
      email: newUser.value.email,
      role: selectedRole.value,
      permissions: selectedPermissions.value,
    });
    notificationStore.showMessage('New administrator added', 'success');
  }
  showAddUserModal.value = false;
  editingUser.value = null;
  newUser.value = { name: '', email: '' };
};
</script>

<style scoped>
.font-family-monospace {
  font-family: ui-monospace, monospace;
}
</style>
