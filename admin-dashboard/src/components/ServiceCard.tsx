import React from 'react';
import { Microservice } from '../types';

interface ServiceCardProps {
  service: Microservice;
  onRestart: (serviceId: string) => void; // Keep for compatibility but won't be used
}

const ServiceCard: React.FC<ServiceCardProps> = ({ service }) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'online':
        return 'status-online';
      case 'offline':
        return 'status-offline';
      case 'warning':
        return 'status-warning';
      default:
        return 'status-offline';
    }
  };

  const getHealthColor = (health: number) => {
    if (health >= 80) return '#28a745';
    if (health >= 60) return '#ffc107';
    return '#dc3545';
  };

  return (
    <div className="card">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '15px' }}>
        <div>
          <h3 style={{ margin: '0 0 5px 0', fontSize: '18px', fontWeight: '600' }}>
            {service.name}
          </h3>
          <p style={{ margin: '0', color: '#666', fontSize: '14px' }}>
            Port: {service.port} | Version: {service.version}
          </p>
        </div>
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <span className={`status-indicator ${getStatusColor(service.status)}`}></span>
          <span style={{ 
            fontSize: '12px', 
            fontWeight: '500',
            color: service.status === 'online' ? '#28a745' : '#dc3545'
          }}>
            {service.status.toUpperCase()}
          </span>
        </div>
      </div>

      <div style={{ marginBottom: '15px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '5px' }}>
          <span style={{ fontSize: '14px', color: '#666' }}>Health</span>
          <span style={{ fontSize: '14px', fontWeight: '500' }}>{service.health}%</span>
        </div>
        <div style={{ 
          width: '100%', 
          height: '6px', 
          backgroundColor: '#e9ecef', 
          borderRadius: '3px',
          overflow: 'hidden'
        }}>
          <div style={{
            width: `${service.health}%`,
            height: '100%',
            backgroundColor: getHealthColor(service.health),
            transition: 'width 0.3s ease'
          }}></div>
        </div>
      </div>

      <div style={{ marginBottom: '15px' }}>
        <p style={{ margin: '0 0 5px 0', fontSize: '14px', color: '#666' }}>
          Uptime: <span style={{ fontWeight: '500', color: '#333' }}>{service.uptime}</span>
        </p>
        <p style={{ margin: '0', fontSize: '14px', color: '#666' }}>
          Last Check: <span style={{ fontWeight: '500', color: '#333' }}>
            {service.lastCheck.toLocaleTimeString()}
          </span>
        </p>
      </div>

      <div style={{ display: 'flex', gap: '10px' }}>
        <button 
          className="btn btn-primary"
          onClick={() => window.open(`http://localhost:${service.port}`, '_blank')}
          style={{ width: '100%' }}
        >
          View Service
        </button>
      </div>
      
      {service.status === 'offline' && (
        <div style={{ 
          marginTop: '10px', 
          padding: '8px', 
          backgroundColor: '#f8d7da', 
          color: '#721c24', 
          borderRadius: '4px', 
          fontSize: '12px' 
        }}>
          <strong>Service Offline:</strong> This service is not responding.
        </div>
      )}
    </div>
  );
};

export default ServiceCard;
