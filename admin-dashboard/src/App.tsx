import React from 'react';
import DashboardPage from './pages/DashboardPage';
import { AdminAuthProvider } from './contexts/AdminAuthContext';
import ProtectedRoute from './components/auth/ProtectedRoute';
import './App.css';

const App: React.FC = () => {
  console.log('App component rendering...');
  
  return (
    <AdminAuthProvider>
      <div className="App">
        <ProtectedRoute>
          <DashboardPage />
        </ProtectedRoute>
      </div>
    </AdminAuthProvider>
  );
};

export default App;
