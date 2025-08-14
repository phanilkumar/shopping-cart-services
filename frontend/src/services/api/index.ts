import authService, { User, AuthResponse, LoginCredentials, RegisterData } from './authAPI';
import oauthService, { OAuthUser, OAuthResponse, OAuthAccount } from './oauthAPI';

// Unified API service that combines both Auth and OAuth services
export const apiService = {
  // Auth Service methods
  auth: {
    login: authService.login,
    register: authService.register,
    logout: authService.logout,
    refreshToken: authService.refreshToken,
    getCurrentUser: authService.getCurrentUser,
    updateProfile: authService.updateProfile,
    getUserProfile: authService.getUserProfile,
    forgotPassword: authService.forgotPassword,
    resetPassword: authService.resetPassword,
    changePassword: authService.changePassword,
    healthCheck: authService.healthCheck,
  },

  // OAuth Service methods
  oauth: {
    googleAuth: oauthService.googleAuth,
    facebookAuth: oauthService.facebookAuth,
    githubAuth: oauthService.githubAuth,
    twitterAuth: oauthService.twitterAuth,
    linkedinAuth: oauthService.linkedinAuth,
    handleCallback: oauthService.handleCallback,
    getCurrentUser: oauthService.getCurrentUser,
    getUserProfile: oauthService.getUserProfile,
    updateProfile: oauthService.updateProfile,
    healthCheck: oauthService.healthCheck,
    redirectToProvider: oauthService.redirectToProvider,
    handleCallbackUrl: oauthService.handleCallbackUrl,
  },

  // Unified methods
  user: {
    // Get user from either service
    getCurrentUser: async (): Promise<User | OAuthUser | null> => {
      try {
        // Try Auth Service first
        const authToken = localStorage.getItem('authToken');
        if (authToken) {
          return await authService.getCurrentUser();
        }

        // Try OAuth Service
        const oauthToken = localStorage.getItem('oauthToken');
        if (oauthToken) {
          return await oauthService.getCurrentUser();
        }

        return null;
      } catch (error) {
        console.error('Error getting current user:', error);
        return null;
      }
    },

    // Logout from both services
    logout: async (): Promise<void> => {
      try {
        await authService.logout();
      } catch (error) {
        console.error('Error logging out from auth service:', error);
      }

      try {
        // OAuth service doesn't have a logout endpoint, just clear tokens
        localStorage.removeItem('oauthToken');
        localStorage.removeItem('oauthRefreshToken');
        localStorage.removeItem('oauthUser');
      } catch (error) {
        console.error('Error clearing OAuth tokens:', error);
      }
    },

    // Check if user is authenticated
    isAuthenticated: (): boolean => {
      const authToken = localStorage.getItem('authToken');
      const oauthToken = localStorage.getItem('oauthToken');
      return !!(authToken || oauthToken);
    },

    // Get authentication method
    getAuthMethod: (): 'auth' | 'oauth' | null => {
      const authToken = localStorage.getItem('authToken');
      const oauthToken = localStorage.getItem('oauthToken');
      
      if (authToken) return 'auth';
      if (oauthToken) return 'oauth';
      return null;
    },
  },

  // Health checks for both services
  health: {
    checkAll: async () => {
      const results = {
        auth: null as any,
        oauth: null as any,
      };

      try {
        results.auth = await authService.healthCheck();
      } catch (error) {
        console.error('Auth service health check failed:', error);
      }

      try {
        results.oauth = await oauthService.healthCheck();
      } catch (error) {
        console.error('OAuth service health check failed:', error);
      }

      return results;
    },
  },
};

// Export individual services for direct use
export { authService, oauthService };

// Export types
export type { User, AuthResponse, LoginCredentials, RegisterData };
export type { OAuthUser, OAuthResponse, OAuthAccount };

export default apiService;
