import axios from 'axios';

// User Service Configuration
const USER_SERVICE_URL = import.meta.env.VITE_USER_SERVICE_URL || 'http://localhost:3001/api/v1';

// Create axios instance for User Service
const userAPI = axios.create({
  baseURL: USER_SERVICE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
userAPI.interceptors.request.use(
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

// Response interceptor to handle errors
userAPI.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Token expired or invalid
      localStorage.removeItem('authToken');
      localStorage.removeItem('authRefreshToken');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// User Types
export interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone: string;
  status: number; // 0 = inactive, 1 = active, 2 = pending, 3 = suspended
  role: number; // 0 = user, 1 = admin, 2 = moderator
  last_login_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateUserData {
  email: string;
  password: string;
  password_confirmation: string;
  first_name: string;
  last_name: string;
  phone: string;
}

export interface UpdateUserData {
  first_name?: string;
  last_name?: string;
  phone?: string;
  email?: string;
}

export interface LoginCredentials {
  email: string;
  password: string;
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

export interface UserListResponse {
  status: string;
  data: {
    users: User[];
    pagination: {
      current_page: number;
      total_pages: number;
      total_count: number;
      per_page: number;
    };
  };
}

export interface UserResponse {
  status: string;
  data: {
    user: User;
  };
}

export interface HealthCheckResponse {
  status: string;
  service: string;
  timestamp: string;
  version: string;
  database: string;
  redis: string;
}

export interface OtpRequest {
  phone: string;
}

export interface OtpVerify {
  phone: string;
  otp: string;
}

export interface OtpResponse {
  status: string;
  message: string;
  data?: {
    user?: User;
    token?: string;
    refresh_token?: string;
  };
}

// User Service API
export const userService = {
  // Authentication
  login: async (credentials: LoginCredentials): Promise<AuthResponse> => {
    const response = await userAPI.post('/auth/login', credentials);
    return response.data;
  },

  register: async (userData: CreateUserData): Promise<AuthResponse> => {
    const response = await userAPI.post('/auth/register', { user: userData });
    return response.data;
  },

  logout: async (): Promise<void> => {
    await userAPI.delete('/auth/logout');
    localStorage.removeItem('authToken');
    localStorage.removeItem('authRefreshToken');
    localStorage.removeItem('user');
  },

  refreshToken: async (refreshToken: string): Promise<AuthResponse> => {
    const response = await userAPI.post('/auth/refresh', { refresh_token: refreshToken });
    return response.data;
  },

  // User Management
  getCurrentUser: async (): Promise<User> => {
    const response = await userAPI.get('/users/me');
    return response.data.data.user;
  },

  getUserById: async (userId: number): Promise<User> => {
    const response = await userAPI.get(`/users/${userId}`);
    return response.data.data.user;
  },

  updateProfile: async (userData: UpdateUserData): Promise<UserResponse> => {
    const response = await userAPI.put('/users/me', { user: userData });
    return response.data;
  },

  changePassword: async (currentPassword: string, newPassword: string, confirmPassword: string): Promise<{ status: string; message: string }> => {
    const response = await userAPI.put('/users/me/password', {
      current_password: currentPassword,
      password: newPassword,
      password_confirmation: confirmPassword,
    });
    return response.data;
  },

  // Admin Functions
  getAllUsers: async (page: number = 1, perPage: number = 20): Promise<UserListResponse> => {
    const response = await userAPI.get(`/admin/users?page=${page}&per_page=${perPage}`);
    return response.data;
  },

  createUser: async (userData: CreateUserData): Promise<UserResponse> => {
    const response = await userAPI.post('/admin/users', { user: userData });
    return response.data;
  },

  updateUser: async (userId: number, userData: UpdateUserData): Promise<UserResponse> => {
    const response = await userAPI.put(`/admin/users/${userId}`, { user: userData });
    return response.data;
  },

  deleteUser: async (userId: number): Promise<{ status: string; message: string }> => {
    const response = await userAPI.delete(`/admin/users/${userId}`);
    return response.data;
  },

  activateUser: async (userId: number): Promise<UserResponse> => {
    const response = await userAPI.patch(`/admin/users/${userId}/activate`);
    return response.data;
  },

  deactivateUser: async (userId: number): Promise<UserResponse> => {
    const response = await userAPI.patch(`/admin/users/${userId}/deactivate`);
    return response.data;
  },

  suspendUser: async (userId: number, reason?: string): Promise<UserResponse> => {
    const response = await userAPI.patch(`/admin/users/${userId}/suspend`, { reason });
    return response.data;
  },

  // Password Management
  forgotPassword: async (email: string): Promise<{ status: string; message: string }> => {
    const response = await userAPI.post('/password/forgot', { email });
    return response.data;
  },

  resetPassword: async (token: string, password: string, passwordConfirmation: string): Promise<{ status: string; message: string }> => {
    const response = await userAPI.post('/password/reset', {
      token,
      password,
      password_confirmation: passwordConfirmation,
    });
    return response.data;
  },

  // Health Check
  healthCheck: async (): Promise<HealthCheckResponse> => {
    const response = await userAPI.get('/health');
    return response.data;
  },

  // OTP functionality
  sendOtp: async (phone: string): Promise<OtpResponse> => {
    const response = await userAPI.post('/auth/send-otp', { phone });
    return response.data;
  },

  verifyOtp: async (phone: string, otp: string): Promise<OtpResponse> => {
    const response = await userAPI.post('/auth/verify-otp', { phone, otp });
    return response.data;
  },

  loginWithOtp: async (phone: string, otp: string): Promise<AuthResponse> => {
    const response = await userAPI.post('/auth/login-with-otp', { phone, otp });
    return response.data;
  },

  // Utility Functions
  isAuthenticated: (): boolean => {
    const token = localStorage.getItem('authToken');
    return !!token;
  },

  getStoredUser: (): User | null => {
    const userStr = localStorage.getItem('user');
    return userStr ? JSON.parse(userStr) : null;
  },

  setStoredUser: (user: User): void => {
    localStorage.setItem('user', JSON.stringify(user));
  },

  clearStoredUser: (): void => {
    localStorage.removeItem('user');
  },
};

export default userService;
