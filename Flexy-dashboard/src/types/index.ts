// Common Types
export type Status = 'active' | 'inactive' | 'pending' | 'suspended' | 'blocked' | 'expired' | 'revoked' | 'operational' | 'degraded' | 'offline' | 'online' | 'unknown' | 'success' | 'failed' | 'paid' | 'refunded';

export type OperatorCode = 'DJEZZY' | 'MOBILIS' | 'OOREDOO';

export type SeverityLevel = 'info' | 'warning' | 'critical';

export interface PaginationParams {
  page: number;
  limit: number;
  search?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// 1. Customer
export interface Customer {
  id: string;
  name: string;
  email: string;
  phone: string;
  company?: string;
  address?: string;
  status: 'active' | 'suspended' | 'blocked';
  devicesCount: number;
  simsCount: number;
  licensesCount: number;
  operationsCount: number;
  totalRevenue: number;
  createdAt: string;
  updatedAt: string;
}

// 2. Operator
export interface Operator {
  id: string;
  name: string;
  code: OperatorCode;
  logo?: string;
  status: 'active' | 'suspended';
  simsCount: number;
  activeSimsCount: number;
  operationsCount: number;
  successRate: number; // e.g. 98.4
  balance?: number;
  currency: string;
  color: string;
  createdAt: string;
}

// 3. SIM Card
export interface SimCard {
  id: string;
  phoneNumber: string;
  iccid: string; // full ICCID (masked in UI by default e.g. ••••••••••7890)
  iccidHash: string;
  operator: OperatorCode;
  customerId: string;
  customerName: string;
  boundModemId?: string;
  boundModemImei?: string;
  boundDeviceId?: string;
  boundDeviceName?: string;
  licenseId?: string;
  status: 'active' | 'pending' | 'blocked' | 'suspended' | 'expired' | 'revoked';
  currentBalance?: number;
  activatedAt?: string;
  expiresAt?: string;
  lastUsedAt?: string;
  createdAt: string;
}

// 4. Modem
export interface Modem {
  id: string;
  name: string;
  imei: string;
  manufacturer: string;
  model: string;
  port: string;
  boundDeviceId: string;
  boundDeviceName: string;
  boundSimId?: string;
  boundSimPhone?: string;
  boundSimOperator?: OperatorCode;
  status: 'online' | 'offline' | 'blocked' | 'unknown';
  signalStrength: number; // 0-100% or dBm
  connectionType: '4G' | '3G' | '2G';
  simDetected: boolean;
  lastHeartbeat: string;
  createdAt: string;
}

// 5. Device
export interface Device {
  id: string;
  uuid: string;
  fingerprint: string;
  name: string;
  customerId: string;
  customerName: string;
  appVersion: string;
  ipAddress: string;
  os: string;
  status: 'online' | 'offline' | 'blocked';
  modemsCount: number;
  simsCount: number;
  activeLicensesCount: number;
  lastSeen: string;
  createdAt: string;
}

// 6. License
export type LicenseStatus = 'active' | 'pending' | 'expired' | 'suspended' | 'revoked';

export interface License {
  id: string;
  serialNumber: string; // e.g. FX1.8F9A2B4C1D6E5F8A
  maskedSerial: string; // FX1.••••••••••••5F8A
  customerId: string;
  customerName: string;
  simId: string;
  simPhone: string;
  operator: OperatorCode;
  deviceId: string;
  deviceName: string;
  modemId?: string;
  status: LicenseStatus;
  keyId: string;
  keyVersion: string;
  algorithm: 'Ed25519';
  issuedAt: string;
  expiresAt: string;
  price: number;
  paymentId?: string;
  paymentStatus: 'paid' | 'pending' | 'failed' | 'refunded';
  revokedAt?: string;
  revocationReason?: string;
  createdAt: string;
}

// 7. Payment
export interface Payment {
  id: string;
  reference: string;
  customerId: string;
  customerName: string;
  licenseId: string;
  amount: number;
  currency: string;
  paymentMethod: 'CIB / Edahabia' | 'Bank Wire' | 'Cash' | 'Credit Card';
  status: 'paid' | 'pending' | 'failed' | 'refunded';
  paidAt?: string;
  failureReason?: string;
  createdAt: string;
}

// 8. License Activation
export interface Activation {
  id: string;
  licenseId: string;
  licenseSerial: string;
  customerId: string;
  customerName: string;
  simId: string;
  simPhone: string;
  deviceId: string;
  deviceName: string;
  modemId?: string;
  iccidVerified: boolean;
  operatorVerified: boolean;
  deviceVerified: boolean;
  signatureVerified: boolean;
  result: 'success' | 'failed';
  failureReason?: 'ICCID mismatch' | 'Device mismatch' | 'Operator mismatch' | 'License expired' | 'License revoked' | 'Invalid signature' | 'Device unauthorized';
  clientIp: string;
  timestamp: string;
}

// 9. Flexi Operation
export type OperationStatus = 'success' | 'failed' | 'blocked' | 'pending';

export interface VerificationStep {
  name: string;
  description: string;
  status: 'passed' | 'failed' | 'skipped' | 'pending';
  timestamp?: string;
  details?: string;
}

export interface FlexiOperation {
  id: string;
  operationCode: string;
  customerId: string;
  customerName: string;
  targetPhone: string;
  operator: OperatorCode;
  simId: string;
  simPhone: string;
  deviceId: string;
  deviceName: string;
  modemId: string;
  amount: number;
  currency: string;
  status: OperationStatus;
  executionDurationMs: number;
  idempotencyKey: string;
  errorMessage?: string;
  createdAt: string;
  completedAt?: string;
  // Step-by-step verification pipeline for debugging
  verificationPipeline: VerificationStep[];
}

// 10. Security Event
export type SecurityEventType = 
  | 'ICCID_MISMATCH'
  | 'DEVICE_MISMATCH'
  | 'INVALID_SIGNATURE'
  | 'UNKNOWN_DEVICE'
  | 'LICENSE_REVOKED'
  | 'LICENSE_EXPIRED'
  | 'OPERATION_BLOCKED'
  | 'MULTIPLE_FAILED_ACTIVATIONS'
  | 'SUSPICIOUS_ACTIVITY';

export interface SecurityEvent {
  id: string;
  type: SecurityEventType;
  title: string;
  description: string;
  severity: SeverityLevel;
  customerId?: string;
  customerName?: string;
  deviceId?: string;
  deviceName?: string;
  simId?: string;
  simPhone?: string;
  licenseId?: string;
  ipAddress: string;
  resolved: boolean;
  timestamp: string;
}

// 11. Audit Log
export interface AuditLog {
  id: string;
  timestamp: string;
  actorId: string;
  actorName: string;
  actorEmail: string;
  actorRole: string;
  action: string;
  entityType: 'Customer' | 'SIM' | 'License' | 'Device' | 'Modem' | 'Payment' | 'SecurityKey' | 'Settings';
  entityId: string;
  customerId?: string;
  deviceId?: string;
  simId?: string;
  licenseId?: string;
  ipAddress: string;
  result: 'SUCCESS' | 'FAILURE';
  severity: SeverityLevel;
  changes?: Record<string, { before: any; after: any }>;
}

// 12. System & Heartbeat Monitoring
export interface Heartbeat {
  id: string;
  deviceId: string;
  deviceName: string;
  modemId?: string;
  status: 'online' | 'offline' | 'degraded';
  cpuUsage: number;
  memoryUsage: number;
  diskUsage: number;
  temperature: number;
  signalStrength: number;
  latencyMs: number;
  timestamp: string;
}

export interface SystemServiceHealth {
  name: string;
  category: 'API' | 'Database' | 'Auth' | 'License Service' | 'Heartbeat Service' | 'Flexi Engine';
  status: 'operational' | 'degraded' | 'down';
  latencyMs: number;
  uptime: string;
  lastChecked: string;
}

export interface SystemEvent {
  id: string;
  category: 'License' | 'SIM' | 'Device' | 'Modem' | 'Payment' | 'Flexi' | 'Security';
  type: string;
  description: string;
  severity: SeverityLevel;
  timestamp: string;
  metadata?: Record<string, any>;
}

// 13. Security Key Version (Ed25519)
export interface KeyVersion {
  id: string;
  keyId: string; // e.g. 2026-01
  algorithm: 'Ed25519';
  publicKeyFingerprint: string;
  status: 'active' | 'retired' | 'revoked';
  activeLicensesCount: number;
  totalLicensesIssued: number;
  createdAt: string;
  rotationDate?: string;
}

// 14. Admin Users & Permissions
export type AdminRole = 'Super Admin' | 'Admin' | 'Support' | 'Finance' | 'Read Only';

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  role: AdminRole;
  status: 'active' | 'suspended';
  permissions: string[];
  lastLoginAt?: string;
  createdAt: string;
}

// 15. Dashboard Overview KPI
export interface DashboardKPIs {
  totalCustomers: number;
  activeCustomers: number;
  totalSims: number;
  activeSims: number;
  activeLicenses: number;
  expiringLicenses: number;
  revenue: number;
  revenueCurrency: string;
  totalOperations: number;
  successfulOperations: number;
  failedOperations: number;
  blockedOperations: number;
  successRate: number;
}
