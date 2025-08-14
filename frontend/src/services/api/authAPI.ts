import axios from 'axios';

// Auth Service Configuration
const AUTH_SERVICE_URL = process.env.REACT_APP_AUTH_SERVICE_URL || 'http://localhost:3000/api/v1';

// Create axios instance for Auth Service
const authAPI = axios.create({
  baseURL: AUTH_SERVICE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
authAPI.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle token refresh
authAPI.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = localStorage.getItem('authRefreshToken');
        if (refreshToken) {
          const response = await axios.post(`${AUTH_SERVICE_URL}/auth/refresh`, {
            refresh_token: refreshToken,
          });

          const { token, refresh_token } = response.data.data;
          localStorage.setItem('authToken', token);
          localStorage.setItem('authRefreshToken', refresh_token);

          originalRequest.headers.Authorization = `Bearer ${token}`;
          return authAPI(originalRequest);
        }
      } catch (refreshError) {
        // Refresh token failed, redirect to login
        localStorage.removeItem('authToken');
        localStorage.removeItem('authRefreshToken');
        localStorage.removeItem('user');
        window.location.href = '/login';
      }
    }

    return Promise.reject(error);
  }
);

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  email: string;
  password: string;
  password_confirmation: string;
  first_name: string;
  last_name: string;
  phone: string;
}

export interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone: string;
  status: string;
  role: string;
  last_login_at: string;
  created_at: string;
  updated_at: string;
}

export interface AuthResponse {
  status: string;
  message: string;
  data: {
    user: User;
    token: string;
    refresh_token: string;
  };
}

export const authService = {
  // Login user
  login: async (credentials: LoginCredentials): Promise<AuthResponse> => {
    const response = await authAPI.post('/auth/login', credentials);
    return response.data;
  },

  // Register user
  register: async (userData: RegisterData): Promise<AuthResponse> => {
    const response = await authAPI.post('/auth/register', {
      user: userData,
    });
    return response.data;
  },

  // Refresh token
  refreshToken: async (refreshToken: string): Promise<AuthResponse> => {
    const response = await authAPI.post('/auth/refresh', {
      refresh_token: refreshToken,
    });
    return response.data;
  },

  // Logout user
  logout: async (): Promise<void> => {
    await authAPI.delete('/auth/logout');
    localStorage.removeItem('authToken');
    localStorage.removeItem('authRefreshToken');
    localStorage.removeItem('user');
  },

  // Get current user
  getCurrentUser: async (): Promise<User> => {
    const response = await authAPI.get('/users/1');
    return response.data.data.user;
  },

  // Update user profile
  updateProfile: async (userData: Partial<RegisterData>): Promise<{ status: string; message: string; data: { user: User } }> => {
    const response = await authAPI.put('/users/1', {
      user: userData,
    });
    return response.data;
  },

  // Get user profile
  getUserProfile: async (): Promise<{ status: string; data: { user: User } }> => {
    const response = await authAPI.get('/users/1/profile');
    return response.data;
  },

  // Forgot password
  forgotPassword: async (email: string): Promise<{ status: string; message: string }> => {
    const response = await authAPI.post('/password/forgot', {
      email,
    });
    return response.data;
  },

  // Reset password
  resetPassword: async (token: string, password: string, password_confirmation: string): Promise<{ status: string; message: string }> => {
    const response = await authAPI.post('/password/reset', {
      token,
      password,
      password_confirmation,
    });
    return response.data;
  },

  // Change password
  changePassword: async (current_password: string, password: string, password_confirmation: string): Promise<{ status: string; message: string }> => {
    const response = await authAPI.put('/password/change', {
      current_password,
      password,
      password_confirmation,
    });
    return response.data;
  },

  // Health check
  healthCheck: async (): Promise<{ status: string; service: string; timestamp: string; version: string }> => {
    const response = await axios.get('http://localhost:3000/health');
    return response.data;
  },
};

export default authService;

