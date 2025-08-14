import axios from 'axios';

// OAuth Service Configuration
const OAUTH_SERVICE_URL = process.env.REACT_APP_OAUTH_SERVICE_URL || 'http://localhost:3001/api/v1';

// Create axios instance for OAuth Service
const oauthAPI = axios.create({
  baseURL: OAUTH_SERVICE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
oauthAPI.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('oauthToken');
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
oauthAPI.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = localStorage.getItem('oauthRefreshToken');
        if (refreshToken) {
          const response = await axios.post(`${OAUTH_SERVICE_URL}/auth/refresh`, {
            refresh_token: refreshToken,
          });

          const { token, refresh_token } = response.data.data;
          localStorage.setItem('oauthToken', token);
          localStorage.setItem('oauthRefreshToken', refresh_token);

          originalRequest.headers.Authorization = `Bearer ${token}`;
          return oauthAPI(originalRequest);
        }
      } catch (refreshError) {
        // Refresh token failed, redirect to login
        localStorage.removeItem('oauthToken');
        localStorage.removeItem('oauthRefreshToken');
        localStorage.removeItem('oauthUser');
        window.location.href = '/login';
      }
    }

    return Promise.reject(error);
  }
);

export interface OAuthUser {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone: string;
  status: string;
  role: string;
  last_login_at: string;
  connected_providers: string[];
  created_at: string;
  updated_at: string;
}

export interface OAuthAccount {
  id: number;
  provider: string;
  provider_name: string;
  provider_icon: string;
  provider_uid: string;
  active: boolean;
  expired: boolean;
  expires_at: string;
  created_at: string;
  updated_at: string;
}

export interface OAuthResponse {
  status: string;
  message: string;
  data: {
    user: OAuthUser;
    token: string;
    refresh_token: string;
    provider: string;
  };
}

export interface OAuthProviderResponse {
  status: string;
  provider: string;
  auth_url: string;
}

export const oauthService = {
  // OAuth Provider Redirects
  googleAuth: async (): Promise<OAuthProviderResponse> => {
    const response = await oauthAPI.get('/oauth/google');
    return response.data;
  },

  facebookAuth: async (): Promise<OAuthProviderResponse> => {
    const response = await oauthAPI.get('/oauth/facebook');
    return response.data;
  },

  githubAuth: async (): Promise<OAuthProviderResponse> => {
    const response = await oauthAPI.get('/oauth/github');
    return response.data;
  },

  twitterAuth: async (): Promise<OAuthProviderResponse> => {
    const response = await oauthAPI.get('/oauth/twitter');
    return response.data;
  },

  linkedinAuth: async (): Promise<OAuthProviderResponse> => {
    const response = await oauthAPI.get('/oauth/linkedin');
    return response.data;
  },

  // OAuth Callback
  handleCallback: async (provider: string): Promise<OAuthResponse> => {
    const response = await oauthAPI.get(`/oauth/callback?provider=${provider}`);
    return response.data;
  },

  // Get current OAuth user
  getCurrentUser: async (): Promise<OAuthUser> => {
    const response = await oauthAPI.get('/users/1');
    return response.data.data.user;
  },

  // Get user profile with OAuth accounts
  getUserProfile: async (): Promise<{ status: string; data: { user: OAuthUser; oauth_accounts: OAuthAccount[] } }> => {
    const response = await oauthAPI.get('/users/1/profile');
    return response.data;
  },

  // Update user profile
  updateProfile: async (userData: Partial<{ first_name: string; last_name: string; phone: string }>): Promise<{ status: string; message: string; data: { user: OAuthUser } }> => {
    const response = await oauthAPI.put('/users/1', {
      user: userData,
    });
    return response.data;
  },

  // Health check
  healthCheck: async (): Promise<{ status: string; service: string; timestamp: string; version: string }> => {
    const response = await axios.get('http://localhost:3001/health');
    return response.data;
  },

  // Helper method to redirect to OAuth provider
  redirectToProvider: (provider: string) => {
    const providerUrls = {
      google: `${OAUTH_SERVICE_URL}/oauth/google`,
      facebook: `${OAUTH_SERVICE_URL}/oauth/facebook`,
      github: `${OAUTH_SERVICE_URL}/oauth/github`,
      twitter: `${OAUTH_SERVICE_URL}/oauth/twitter`,
      linkedin: `${OAUTH_SERVICE_URL}/oauth/linkedin`,
    };

    const url = providerUrls[provider as keyof typeof providerUrls];
    if (url) {
      window.location.href = url;
    }
  },

  // Helper method to handle OAuth callback URL
  handleCallbackUrl: async (url: string): Promise<OAuthResponse> => {
    const urlParams = new URLSearchParams(url.split('?')[1]);
    const provider = urlParams.get('provider') || 'google';
    return await oauthService.handleCallback(provider);
  },
};

export default oauthService;
