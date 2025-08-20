import axios from 'axios';
import { Microservice, ServiceMetrics, DashboardStats, LogEntry } from '../types';

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'http://localhost:3001';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

// Microservices configuration
export const MICROSERVICES = [
  { id: 'auth-service', name: 'Auth Service', port: 3001, healthEndpoint: '/health' },
  { id: 'oauth-service', name: 'OAuth Service', port: 3002, healthEndpoint: '/health' },
  { id: 'user-service', name: 'User Service', port: 3003, healthEndpoint: '/health' },
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
          
          return {
            id: service.id,
            name: service.name,
            port: service.port,
            status: 'online' as const,
            health: response.data.health || 100,
            uptime: response.data.uptime || 'Unknown',
            version: response.data.version || '1.0.0',
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

  // Restart service
  async restartService(serviceId: string): Promise<boolean> {
    try {
      const response = await api.post(`/admin/services/${serviceId}/restart`);
      return response.data.success;
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
