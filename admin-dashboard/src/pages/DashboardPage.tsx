import React, { useState, useEffect } from 'react';
import { Microservice, DashboardStats } from '../types';
import { microservicesApi } from '../services/api';
import { useAdminAuth } from '../contexts/AdminAuthContext';
import ServiceCard from '../components/ServiceCard';
import StatsCard from '../components/StatsCard';
import ServiceLogs from '../components/ServiceLogs';

const DashboardPage: React.FC = () => {
  const { user, logout } = useAdminAuth();
  const [services, setServices] = useState<Microservice[]>([]);
  const [stats, setStats] = useState<DashboardStats>({
    totalServices: 0,
    onlineServices: 0,
    totalRequests: 0,
    averageResponseTime: 0,
    errorRate: 0,
  });
  const [loading, setLoading] = useState(true);
  const [selectedService, setSelectedService] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [servicesData, statsData] = await Promise.all([
        microservicesApi.getServicesStatus(),
        microservicesApi.getDashboardStats(),
      ]);
      
      setServices(servicesData);
      setStats(statsData);
      setError(null);
    } catch (err) {
      setError('Failed to fetch dashboard data');
      console.error('Error fetching dashboard data:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 30000); // Refresh every 30 seconds

    return () => clearInterval(interval);
  }, []);

  const handleRestart = async (serviceId: string) => {
    // This function is now called by ServiceCard after successful restart
    // We just need to refresh the data
    setTimeout(fetchData, 2000);
  };

  const handleLogout = () => {
    if (window.confirm('Are you sure you want to logout?')) {
      logout();
    }
  };

  if (loading) {
    return (
      <div className="container" style={{ paddingTop: '20px' }}>
        <div style={{ textAlign: 'center', padding: '40px' }}>
          <div style={{ fontSize: '18px', color: '#666' }}>Loading dashboard...</div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container" style={{ paddingTop: '20px' }}>
        <div style={{ textAlign: 'center', padding: '40px', color: '#dc3545' }}>
          <div style={{ fontSize: '18px', marginBottom: '10px' }}>Error</div>
          <div>{error}</div>
          <button 
            className="btn btn-primary" 
            onClick={fetchData}
            style={{ marginTop: '20px' }}
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="container" style={{ paddingTop: '20px' }}>
      {/* Header with logout button */}
      <div style={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'flex-start', 
        marginBottom: '30px',
        paddingBottom: '20px',
        borderBottom: '1px solid #eee'
      }}>
        <div>
          <h1 style={{ 
            margin: '0 0 10px 0', 
            fontSize: '32px', 
            fontWeight: '700', 
            color: '#333' 
          }}>
            Microservices Admin Dashboard
          </h1>
          <p style={{ margin: '0', color: '#666', fontSize: '16px' }}>
            Monitor and manage your microservices infrastructure
          </p>
          {user && (
            <p style={{ margin: '10px 0 0 0', color: '#888', fontSize: '14px' }}>
              Logged in as: <strong>{user.full_name}</strong> ({user.email})
            </p>
          )}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <button 
            className="btn btn-outline-secondary"
            onClick={handleLogout}
            style={{
              padding: '8px 16px',
              fontSize: '14px',
              border: '1px solid #6c757d',
              borderRadius: '4px',
              backgroundColor: 'transparent',
              color: '#6c757d',
              cursor: 'pointer',
              transition: 'all 0.2s ease'
            }}
            onMouseOver={(e) => {
              e.currentTarget.style.backgroundColor = '#6c757d';
              e.currentTarget.style.color = 'white';
            }}
            onMouseOut={(e) => {
              e.currentTarget.style.backgroundColor = 'transparent';
              e.currentTarget.style.color = '#6c757d';
            }}
          >
            Logout
          </button>
        </div>
      </div>

      <StatsCard stats={stats} />

      <div style={{ marginBottom: '30px' }}>
        <h2 style={{ 
          margin: '0 0 20px 0', 
          fontSize: '24px', 
          fontWeight: '600', 
          color: '#333' 
        }}>
          Services
        </h2>
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', 
          gap: '20px' 
        }}>
          {services.map((service) => (
            <ServiceCard 
              key={service.id} 
              service={service} 
              onRestart={handleRestart}
            />
          ))}
        </div>
      </div>

      <div style={{ marginBottom: '30px' }}>
        <h2 style={{ 
          margin: '0 0 20px 0', 
          fontSize: '24px', 
          fontWeight: '600', 
          color: '#333' 
        }}>
          Service Logs
        </h2>
        <div style={{ marginBottom: '15px' }}>
          <select 
            value={selectedService || ''} 
            onChange={(e) => setSelectedService(e.target.value || null)}
            style={{
              padding: '8px 12px',
              border: '1px solid #ddd',
              borderRadius: '4px',
              fontSize: '14px',
              minWidth: '200px'
            }}
          >
            <option value="">Select a service to view logs</option>
            {services.map((service) => (
              <option key={service.id} value={service.id}>
                {service.name}
              </option>
            ))}
          </select>
        </div>
        
        {selectedService && (
          <ServiceLogs serviceId={selectedService} />
        )}
      </div>
    </div>
  );
};

export default DashboardPage;
