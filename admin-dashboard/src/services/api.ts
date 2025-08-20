import axios from 'axios';
import { Microservice, ServiceMetrics, DashboardStats, LogEntry } from '../types';

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'http://localhost:3001';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

// Microservices configuration - Updated to include all running services (excluding admin-dashboard itself)
export const MICROSERVICES = [
  { id: 'api-gateway', name: 'API Gateway', port: 3000, healthEndpoint: '/health' },
  { id: 'user-service', name: 'User Service', port: 3001, healthEndpoint: '/health' },
  { id: 'product-service', name: 'Product Service', port: 3002, healthEndpoint: '/health' },
  { id: 'order-service', name: 'Order Service', port: 3003, healthEndpoint: '/health' },
  { id: 'cart-service', name: 'Cart Service', port: 3004, healthEndpoint: '/health' },
  { id: 'frontend', name: 'Frontend', port: 3005, healthEndpoint: '/' },
  { id: 'notification-service', name: 'Notification Service', port: 3006, healthEndpoint: '/health' },
  { id: 'wallet-service', name: 'Wallet Service', port: 3007, healthEndpoint: '/health' },
];

export const microservicesApi = {
  // Get all microservices status
  async getServicesStatus(): Promise<Microservice[]> {
    const services = await Promise.allSettled(
      MICROSERVICES.map(async (service) => {
        try {
          const response = await axios.get(`http://localhost:${service.port}${service.healthEndpoint}`, {
            timeout: 5000,
          });
          
          // Parse health data from response
          let health = 100;
          let uptime = 'Unknown';
          let version = '1.0.0';
          
          if (response.data) {
            health = response.data.health || response.data.status === 'healthy' ? 100 : 0;
            uptime = response.data.uptime || 'Unknown';
            version = response.data.version || '1.0.0';
          }
          
          return {
            id: service.id,
            name: service.name,
            port: service.port,
            status: 'online' as const,
            health,
            uptime,
            version,
            lastCheck: new Date(),
            endpoints: [],
            logs: [],
          };
        } catch (error) {
          return {
            id: service.id,
            name: service.name,
            port: service.port,
            status: 'offline' as const,
            health: 0,
            uptime: '0s',
            version: 'Unknown',
            lastCheck: new Date(),
            endpoints: [],
            logs: [],
          };
        }
      })
    );

    return services.map((result, index) => {
      if (result.status === 'fulfilled') {
        return result.value;
      } else {
        const service = MICROSERVICES[index];
        return {
          id: service.id,
          name: service.name,
          port: service.port,
          status: 'offline' as const,
          health: 0,
          uptime: '0s',
          version: 'Unknown',
          lastCheck: new Date(),
          endpoints: [],
          logs: [],
        };
      }
    });
  },

  // Get service metrics
  async getServiceMetrics(serviceId: string): Promise<ServiceMetrics> {
    const service = MICROSERVICES.find(s => s.id === serviceId);
    if (!service) {
      throw new Error(`Service ${serviceId} not found`);
    }

    try {
      const response = await axios.get(`http://localhost:${service.port}/metrics`, {
        timeout: 5000,
      });
      
      return {
        serviceId,
        requestsPerMinute: response.data.requestsPerMinute || 0,
        averageResponseTime: response.data.averageResponseTime || 0,
        errorRate: response.data.errorRate || 0,
        activeConnections: response.data.activeConnections || 0,
        memoryUsage: response.data.memoryUsage || 0,
        cpuUsage: response.data.cpuUsage || 0,
      };
    } catch (error) {
      return {
        serviceId,
        requestsPerMinute: 0,
        averageResponseTime: 0,
        errorRate: 100,
        activeConnections: 0,
        memoryUsage: 0,
        cpuUsage: 0,
      };
    }
  },

  // Get service logs
  async getServiceLogs(serviceId: string, limit: number = 50): Promise<LogEntry[]> {
    const service = MICROSERVICES.find(s => s.id === serviceId);
    if (!service) {
      throw new Error(`Service ${serviceId} not found`);
    }

    try {
      const response = await axios.get(`http://localhost:${service.port}/logs?limit=${limit}`, {
        timeout: 5000,
      });
      
      return response.data.logs || [];
    } catch (error) {
      return [];
    }
  },

  // Restart service - Updated to use Docker Compose
  async restartService(serviceId: string): Promise<boolean> {
    try {
      // Use Docker Compose to restart the service
      const response = await fetch('/api/admin/restart-service', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ serviceId }),
      });
      
      if (response.ok) {
        const result = await response.json();
        return result.success;
      }
      return false;
    } catch (error) {
      console.error('Failed to restart service:', error);
      return false;
    }
  },

  // Get dashboard statistics
  async getDashboardStats(): Promise<DashboardStats> {
    const services = await this.getServicesStatus();
    const onlineServices = services.filter(s => s.status === 'online').length;
    
    return {
      totalServices: services.length,
      onlineServices,
      totalRequests: services.reduce((sum, s) => sum + (s.endpoints?.length || 0), 0),
      averageResponseTime: services.reduce((sum, s) => sum + (s.endpoints?.reduce((eSum, e) => eSum + e.responseTime, 0) || 0), 0) / Math.max(services.length, 1),
      errorRate: services.filter(s => s.status === 'offline').length / services.length * 100,
    };
  },
};
