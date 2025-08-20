import React from 'react';
import { DashboardStats } from '../types';

interface StatsCardProps {
  stats: DashboardStats;
}

const StatsCard: React.FC<StatsCardProps> = ({ stats }) => {
  const getStatusColor = (online: number, total: number) => {
    const percentage = (online / total) * 100;
    if (percentage >= 80) return '#28a745';
    if (percentage >= 60) return '#ffc107';
    return '#dc3545';
  };

  return (
    <div className="card">
      <h2 style={{ margin: '0 0 20px 0', fontSize: '24px', fontWeight: '600', color: '#333' }}>
        System Overview
      </h2>
      
      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', 
        gap: '20px' 
      }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '32px', fontWeight: '700', color: '#007bff', marginBottom: '5px' }}>
            {stats.totalServices}
          </div>
          <div style={{ fontSize: '14px', color: '#666' }}>Total Services</div>
        </div>
        
        <div style={{ textAlign: 'center' }}>
          <div style={{ 
            fontSize: '32px', 
            fontWeight: '700', 
            color: getStatusColor(stats.onlineServices, stats.totalServices),
            marginBottom: '5px' 
          }}>
            {stats.onlineServices}
          </div>
          <div style={{ fontSize: '14px', color: '#666' }}>Online Services</div>
        </div>
        
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '32px', fontWeight: '700', color: '#28a745', marginBottom: '5px' }}>
            {stats.totalRequests}
          </div>
          <div style={{ fontSize: '14px', color: '#666' }}>Total Requests</div>
        </div>
        
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '32px', fontWeight: '700', color: '#ffc107', marginBottom: '5px' }}>
            {stats.averageResponseTime.toFixed(2)}ms
          </div>
          <div style={{ fontSize: '14px', color: '#666' }}>Avg Response Time</div>
        </div>
        
        <div style={{ textAlign: 'center' }}>
          <div style={{ 
            fontSize: '32px', 
            fontWeight: '700', 
            color: stats.errorRate > 10 ? '#dc3545' : '#28a745',
            marginBottom: '5px' 
          }}>
            {stats.errorRate.toFixed(1)}%
          </div>
          <div style={{ fontSize: '14px', color: '#666' }}>Error Rate</div>
        </div>
      </div>
    </div>
  );
};

export default StatsCard;
