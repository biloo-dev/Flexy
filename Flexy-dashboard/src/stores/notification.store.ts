import { defineStore } from 'pinia';
import { ref } from 'vue';

export interface AppNotification {
  id: string;
  title: string;
  message: string;
  type: 'info' | 'success' | 'warning' | 'error';
  timestamp: string;
  read: boolean;
  link?: string;
}

export const useNotificationStore = defineStore('notification', () => {
  const notifications = ref<AppNotification[]>([
    {
      id: 'notif-1',
      title: 'Licenses Expiring Soon',
      message: '5 licenses will expire within the next 3 days.',
      type: 'warning',
      timestamp: '10 min ago',
      read: false,
      link: '/licenses/expiring',
    },
    {
      id: 'notif-2',
      title: 'Security Alert: SIM Blocked',
      message: 'SIM Mobilis (+213 550 88 77 66) was automatically blocked due to ICCID mismatch.',
      type: 'error',
      timestamp: '35 min ago',
      read: false,
      link: '/security/events',
    },
    {
      id: 'notif-3',
      title: 'Device Offline',
      message: 'Device Setif Terminal 01 has missed consecutive heartbeats.',
      type: 'warning',
      timestamp: '2 hours ago',
      read: true,
      link: '/monitoring',
    },
    {
      id: 'notif-4',
      title: 'Payment Received',
      message: 'Payment of 70,000 DZD received from Yacine Mansouri Kiosk Network.',
      type: 'success',
      timestamp: '5 hours ago',
      read: true,
      link: '/payments',
    },
  ]);

  const snackbar = ref<{
    show: boolean;
    text: string;
    color: string;
    timeout: number;
  }>({
    show: false,
    text: '',
    color: 'info',
    timeout: 4000,
  });

  function showMessage(text: string, color: 'success' | 'info' | 'warning' | 'error' = 'info') {
    snackbar.value = {
      show: true,
      text,
      color,
      timeout: 4000,
    };
  }

  function markAsRead(id: string) {
    const n = notifications.value.find((item) => item.id === id);
    if (n) n.read = true;
  }

  function markAllAsRead() {
    notifications.value.forEach((n) => (n.read = true));
  }

  function addNotification(notif: Omit<AppNotification, 'id' | 'read' | 'timestamp'>) {
    notifications.value.unshift({
      ...notif,
      id: `notif-${Date.now()}`,
      read: false,
      timestamp: 'Just now',
    });
    showMessage(notif.message, notif.type);
  }

  return {
    notifications,
    snackbar,
    showMessage,
    markAsRead,
    markAllAsRead,
    addNotification,
  };
});
