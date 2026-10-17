import { ref, onMounted, onUnmounted } from 'vue';

export type ConnectionState = 'connected' | 'reconnecting' | 'offline';

const status = ref<ConnectionState>('connected');
const lastHeartbeat = ref<Date>(new Date());
const pingMs = ref<number>(24);

export function useConnectionStatus() {
  let intervalId: any = null;

  onMounted(() => {
    // Monitor online/offline events
    window.addEventListener('online', () => {
      status.value = 'connected';
      lastHeartbeat.value = new Date();
    });

    window.addEventListener('offline', () => {
      status.value = 'offline';
    });

    // Simulated heartbeat jitter
    intervalId = setInterval(() => {
      if (navigator.onLine) {
        status.value = 'connected';
        pingMs.value = Math.floor(18 + Math.random() * 15);
        lastHeartbeat.value = new Date();
      } else {
        status.value = 'offline';
      }
    }, 15000);
  });

  onUnmounted(() => {
    if (intervalId) clearInterval(intervalId);
  });

  const simulateReconnect = () => {
    status.value = 'reconnecting';
    setTimeout(() => {
      status.value = 'connected';
      lastHeartbeat.value = new Date();
    }, 1500);
  };

  return {
    status,
    lastHeartbeat,
    pingMs,
    simulateReconnect,
  };
}
