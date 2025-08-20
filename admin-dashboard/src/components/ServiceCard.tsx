import React, { useState } from 'react';
import { Microservice } from '../types';
import { microservicesApi, RESTART_BLACKLIST } from '../services/api';

interface ServiceCardProps {
  service: Microservice;
  onRestart: (serviceId: string) => void;
}

const ServiceCard: React.FC<ServiceCardProps> = ({ service, onRestart }) => {
  const [restarting, setRestarting] = useState(false);
  const [restartMessage, setRestartMessage] = useState<string | null>(null);
  const [restartWarning, setRestartWarning] = useState<string | null>(null);

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

  const isRestartDisabled = () => {
    return service.status === 'offline' || restarting || RESTART_BLACKLIST.includes(service.id);
  };

  const getRestartButtonText = () => {
    if (restarting) return 'Restarting...';
    if (RESTART_BLACKLIST.includes(service.id)) return 'Restart Disabled';
    return 'Restart';
  };

  const getRestartButtonTitle = () => {
    if (RESTART_BLACKLIST.includes(service.id)) {
      return 'This service cannot be restarted via the dashboard for security reasons.';
    }
    return 'Restart this microservice using Docker Compose. This will stop and start the service container.';
  };

  const handleRestart = async () => {
    // Clear previous messages
    setRestartMessage(null);
    setRestartWarning(null);

    // Check if service is blacklisted
    if (RESTART_BLACKLIST.includes(service.id)) {
      setRestartWarning('This service is critical for dashboard operation and cannot be restarted via the dashboard.');
      return;
    }

    // Add confirmation dialog
    const confirmed = window.confirm(
      `Are you sure you want to restart ${service.name}?\n\nThis will cause a brief downtime for this service.`
    );
    
    if (!confirmed) {
      return;
    }

    setRestarting(true);
    try {
      const result = await microservicesApi.restartService(service.id);
      
      if (result.success) {
        setRestartMessage(result.message);
        // Call the parent onRestart callback
        onRestart(service.id);
      } else {
        setRestartWarning(result.message);
        if (result.warning) {
          setRestartWarning(prev => prev ? `${prev}\n\n${result.warning}` : result.warning);
        }
      }
    } catch (error) {
      setRestartWarning('Failed to restart service. Please try again.');
    } finally {
      setRestarting(false);
    }

    // Clear messages after 5 seconds
    setTimeout(() => {
      setRestartMessage(null);
      setRestartWarning(null);
    }, 5000);
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

      {/* Restart Messages */}
      {restartMessage && (
        <div style={{ 
          marginBottom: '10px', 
          padding: '8px', 
          backgroundColor: '#d4edda', 
          color: '#155724', 
          borderRadius: '4px', 
          fontSize: '12px' 
        }}>
          <strong>Success:</strong> {restartMessage}
        </div>
      )}

      {restartWarning && (
        <div style={{ 
          marginBottom: '10px', 
          padding: '8px', 
          backgroundColor: '#fff3cd', 
          color: '#856404', 
          borderRadius: '4px', 
          fontSize: '12px' 
        }}>
          <strong>Warning:</strong> {restartWarning}
        </div>
      )}

      <div style={{ display: 'flex', gap: '10px' }}>
        <button 
          className="btn btn-primary"
          onClick={() => window.open(`http://localhost:${service.port}`, '_blank')}
          style={{ flex: '1' }}
        >
          View Service
        </button>
        <button 
          className={`btn ${RESTART_BLACKLIST.includes(service.id) ? 'btn-secondary' : 'btn-danger'}`}
          onClick={handleRestart}
          disabled={isRestartDisabled()}
          style={{ flex: '1' }}
          title={getRestartButtonTitle()}
        >
          {getRestartButtonText()}
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
          <strong>Service Offline:</strong> This service is not responding. Use the restart button to attempt recovery.
        </div>
      )}

      {RESTART_BLACKLIST.includes(service.id) && (
        <div style={{ 
          marginTop: '10px', 
          padding: '8px', 
          backgroundColor: '#e2e3e5', 
          color: '#383d41', 
          borderRadius: '4px', 
          fontSize: '12px' 
        }}>
          <strong>Restart Disabled:</strong> This service cannot be restarted via the dashboard for security reasons.
        </div>
      )}
    </div>
  );
};

export default ServiceCard;
