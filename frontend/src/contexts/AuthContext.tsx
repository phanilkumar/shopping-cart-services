import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { AppDispatch, RootState } from '../store';
import { getCurrentUser, logout, clearError, login, register, oauthLogin, updateProfile } from '../store/slices/authSlice';
import { apiService } from '../services/api';
import toast from 'react-hot-toast';

interface AuthContextType {
  user: any;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  authMethod: 'auth' | 'oauth' | null;
  login: (email: string, password: string) => Promise<void>;
  register: (userData: any) => Promise<void>;
  oauthLogin: (provider: string) => Promise<void>;
  logout: () => Promise<void>;
  updateProfile: (userData: any) => Promise<void>;
  clearError: () => void;
  checkHealth: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const dispatch = useDispatch<AppDispatch>();
  const { user, isAuthenticated, isLoading, error, authMethod } = useSelector(
    (state: RootState) => state.auth
  );

  const [isInitialized, setIsInitialized] = useState(false);

  // Initialize auth state on app start
  useEffect(() => {
    const initializeAuth = async () => {
      try {
        // Check if user is authenticated
        if (apiService.user.isAuthenticated()) {
          await dispatch(getCurrentUser()).unwrap();
        }
      } catch (error) {
        console.error('Failed to initialize auth:', error);
        // Clear invalid tokens
        localStorage.removeItem('authToken');
        localStorage.removeItem('authRefreshToken');
        localStorage.removeItem('oauthToken');
        localStorage.removeItem('oauthRefreshToken');
        localStorage.removeItem('user');
        localStorage.removeItem('oauthUser');
      } finally {
        setIsInitialized(true);
      }
    };

    initializeAuth();
  }, [dispatch]);

  // Handle auth errors
  useEffect(() => {
    if (error) {
      toast.error(error);
      dispatch(clearError());
    }
  }, [error, dispatch]);

  const handleLogin = async (email: string, password: string) => {
    try {
      await dispatch(login({ email, password })).unwrap();
      toast.success('Login successful!');
    } catch (error: any) {
      toast.error(error.message || 'Login failed');
      throw error;
    }
  };

  const handleRegister = async (userData: any) => {
    try {
      await dispatch(register(userData)).unwrap();
      toast.success('Registration successful!');
    } catch (error: any) {
      toast.error(error.message || 'Registration failed');
      throw error;
    }
  };

  const handleOAuthLogin = async (provider: string) => {
    try {
      // For now, we'll simulate OAuth login since we're using mock data
      await dispatch(oauthLogin(provider)).unwrap();
      toast.success(`${provider} login successful!`);
    } catch (error: any) {
      toast.error(error.message || 'OAuth login failed');
      throw error;
    }
  };

  const handleLogout = async () => {
    try {
      await dispatch(logout()).unwrap();
      toast.success('Logged out successfully');
    } catch (error: any) {
      toast.error(error.message || 'Logout failed');
      // Force logout even if API call fails
      localStorage.removeItem('authToken');
      localStorage.removeItem('authRefreshToken');
      localStorage.removeItem('oauthToken');
      localStorage.removeItem('oauthRefreshToken');
      localStorage.removeItem('user');
      localStorage.removeItem('oauthUser');
    }
  };

  const handleUpdateProfile = async (userData: any) => {
    try {
      await dispatch(updateProfile(userData)).unwrap();
      toast.success('Profile updated successfully!');
    } catch (error: any) {
      toast.error(error.message || 'Profile update failed');
      throw error;
    }
  };

  const checkHealth = async () => {
    try {
      const health = await apiService.health.checkAll();
      console.log('Service health:', health);
      
      if (health.auth?.status === 'healthy') {
        console.log('Auth service is healthy');
      } else {
        console.warn('Auth service health check failed');
      }
      
      if (health.oauth?.status === 'healthy') {
        console.log('OAuth service is healthy');
      } else {
        console.warn('OAuth service health check failed');
      }
    } catch (error) {
      console.error('Health check failed:', error);
    }
  };

  const value: AuthContextType = {
    user,
    isAuthenticated,
    isLoading,
    error,
    authMethod,
    login: handleLogin,
    register: handleRegister,
    oauthLogin: handleOAuthLogin,
    logout: handleLogout,
    updateProfile: handleUpdateProfile,
    clearError: () => dispatch(clearError()),
    checkHealth,
  };

  if (!isInitialized) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh' 
      }}>
        <div>Loading...</div>
      </div>
    );
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
