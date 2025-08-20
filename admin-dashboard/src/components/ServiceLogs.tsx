import React, { useState, useEffect } from 'react';
import { LogEntry } from '../types';
import { microservicesApi } from '../services/api';

interface ServiceLogsProps {
  serviceId: string;
}

const ServiceLogs: React.FC<ServiceLogsProps> = ({ serviceId }) => {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchLogs = async () => {
      try {
        setLoading(true);
        const serviceLogs = await microservicesApi.getServiceLogs(serviceId, 100);
        setLogs(serviceLogs);
        setError(null);
      } catch (err) {
        setError('Failed to fetch logs');
        console.error('Error fetching logs:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchLogs();
    const interval = setInterval(fetchLogs, 10000); // Refresh every 10 seconds

    return () => clearInterval(interval);
  }, [serviceId]);

  const getLogLevelColor = (level: string) => {
    switch (level) {
      case 'error':
        return '#dc3545';
      case 'warn':
        return '#ffc107';
      case 'info':
        return '#007bff';
      case 'debug':
        return '#6c757d';
      default:
        return '#6c757d';
    }
  };

  const formatTimestamp = (timestamp: Date) => {
    return new Date(timestamp).toLocaleString();
  };

  if (loading) {
    return (
      <div className="card">
        <h3>Service Logs</h3>
        <div style={{ textAlign: 'center', padding: '20px' }}>
          Loading logs...
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="card">
        <h3>Service Logs</h3>
        <div style={{ color: '#dc3545', textAlign: 'center', padding: '20px' }}>
          {error}
        </div>
      </div>
    );
  }

  return (
    <div className="card">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <h3 style={{ margin: '0', fontSize: '18px', fontWeight: '600' }}>Service Logs</h3>
        <span style={{ fontSize: '14px', color: '#666' }}>
          {logs.length} entries
        </span>
      </div>

      {logs.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '20px', color: '#666' }}>
          No logs available
        </div>
      ) : (
        <div style={{ 
          maxHeight: '400px', 
          overflowY: 'auto',
          border: '1px solid #e9ecef',
          borderRadius: '4px'
        }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead style={{ 
              backgroundColor: '#f8f9fa', 
              position: 'sticky', 
              top: 0,
              zIndex: 1
            }}>
              <tr>
                <th style={{ 
                  padding: '12px', 
                  textAlign: 'left', 
                  borderBottom: '1px solid #dee2e6',
                  fontSize: '14px',
                  fontWeight: '600'
                }}>
                  Timestamp
                </th>
                <th style={{ 
                  padding: '12px', 
                  textAlign: 'left', 
                  borderBottom: '1px solid #dee2e6',
                  fontSize: '14px',
                  fontWeight: '600'
                }}>
                  Level
                </th>
                <th style={{ 
                  padding: '12px', 
                  textAlign: 'left', 
                  borderBottom: '1px solid #dee2e6',
                  fontSize: '14px',
                  fontWeight: '600'
                }}>
                  Message
                </th>
              </tr>
            </thead>
            <tbody>
              {logs.map((log) => (
                <tr key={log.id} style={{ borderBottom: '1px solid #f1f3f4' }}>
                  <td style={{ 
                    padding: '12px', 
                    fontSize: '13px', 
                    color: '#666',
                    fontFamily: 'monospace'
                  }}>
                    {formatTimestamp(log.timestamp)}
                  </td>
                  <td style={{ padding: '12px' }}>
                    <span style={{
                      padding: '4px 8px',
                      borderRadius: '4px',
                      fontSize: '12px',
                      fontWeight: '500',
                      backgroundColor: getLogLevelColor(log.level) + '20',
                      color: getLogLevelColor(log.level)
                    }}>
                      {log.level.toUpperCase()}
                    </span>
                  </td>
                  <td style={{ 
                    padding: '12px', 
                    fontSize: '14px',
                    fontFamily: 'monospace',
                    wordBreak: 'break-word'
                  }}>
                    {log.message}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default ServiceLogs;
