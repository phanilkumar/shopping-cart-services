export interface Microservice {
  id: string;
  name: string;
  port: number;
  status: 'online' | 'offline' | 'warning';
  health: number;
  uptime: string;
  version: string;
  lastCheck: Date;
  endpoints: Endpoint[];
  logs: LogEntry[];
}

export interface Endpoint {
  path: string;
  method: string;
  status: number;
  responseTime: number;
  lastAccessed: Date;
}

export interface LogEntry {
  id: string;
  timestamp: Date;
  level: 'info' | 'warn' | 'error' | 'debug';
  message: string;
  service: string;
}

export interface ServiceMetrics {
  serviceId: string;
  requestsPerMinute: number;
  averageResponseTime: number;
  errorRate: number;
  activeConnections: number;
  memoryUsage: number;
  cpuUsage: number;
}

export interface DashboardStats {
  totalServices: number;
  onlineServices: number;
  totalRequests: number;
  averageResponseTime: number;
  errorRate: number;
}
