<template>
  <v-card class="pa-4 fill-height border">
    <div class="d-flex align-center justify-space-between mb-3">
      <div>
        <h3 class="text-subtitle-1 font-weight-bold">Live Activity Stream</h3>
        <p class="text-caption text-medium-emphasis mb-0">Real-time telemetric events across all licenses & SIMs</p>
      </div>
      <v-chip color="info" size="x-small" variant="tonal" class="font-weight-medium">
        <span class="live-dot me-1"></span> Live
      </v-chip>
    </div>

    <ActivityTimeline :items="activityEvents" />
  </v-card>
</template>

<script setup lang="ts">
import ActivityTimeline, { type TimelineItem } from '@/components/common/ActivityTimeline.vue';

const activityEvents: TimelineItem[] = [
  {
    title: 'Flexi Operation Successful',
    description: '1,000 DZD sent to +213 771 99 88 77 (Djezzy)',
    time: '2 min ago',
    icon: 'mdi-check-circle',
    color: 'success',
    customer: 'Ahmed Benali Telecom',
    sim: '+213 770 11 22 33',
    device: 'Algiers Hub 01',
  },
  {
    title: 'License Activated',
    description: 'Cryptographic Ed25519 signature verified for LIC-305',
    time: '8 min ago',
    icon: 'mdi-key-check',
    color: 'primary',
    customer: 'Karim Brahimi Services',
    sim: '+213 770 55 66 77',
    device: 'Oran Station Master',
  },
  {
    title: 'SIM Blocked by Security Engine',
    description: 'ICCID mismatch detected on port /dev/ttyUSB0',
    time: '15 min ago',
    icon: 'mdi-shield-alert',
    color: 'error',
    customer: 'Sofiane Meziane Express',
    sim: '+213 550 88 77 66',
    device: 'Blida Kiosk',
  },
  {
    title: 'Payment Confirmed',
    description: 'Payment of 70,000 DZD received via Bank Wire',
    time: '25 min ago',
    icon: 'mdi-cash-check',
    color: 'success',
    customer: 'Yacine Mansouri Kiosk Network',
  },
  {
    title: 'Device Connected & Synchronized',
    description: 'Modem Quectel EC25-E registered with 4G LTE Cat-4',
    time: '42 min ago',
    icon: 'mdi-router-wireless',
    color: 'info',
    customer: 'Ahmed Benali Telecom',
    device: 'Algiers Hub 01',
  },
];
</script>

<style scoped>
.live-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: #38BDF8;
  display: inline-block;
  animation: pulse 1.5s infinite;
}
@keyframes pulse {
  0% { transform: scale(0.9); opacity: 1; }
  50% { transform: scale(1.4); opacity: 0.5; }
  100% { transform: scale(0.9); opacity: 1; }
}
</style>
