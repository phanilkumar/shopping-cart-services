const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';

class AdminAPI {
  private baseURL: string;

  constructor() {
    this.baseURL = API_BASE_URL;
  }

  private async request(endpoint: string, options: RequestInit = {}) {
    const token = localStorage.getItem('token');
    const headers = {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
      ...options.headers,
    };

    const response = await fetch(`${this.baseURL}${endpoint}`, {
      ...options,
      headers,
    });

    if (!response.ok) {
      throw new Error(`API request failed: ${response.statusText}`);
    }

    return response.json();
  }

  // Dashboard
  async getDashboardData() {
    return this.request('/api/v1/admin/dashboard');
  }

  // Users
  async getUsers(params?: any) {
    const queryString = params ? `?${new URLSearchParams(params).toString()}` : '';
    return this.request(`/api/v1/admin/users${queryString}`);
  }

  async getUser(id: string) {
    return this.request(`/api/v1/admin/users/${id}`);
  }

  // Products
  async getProducts(params?: any) {
    const queryString = params ? `?${new URLSearchParams(params).toString()}` : '';
    return this.request(`/api/v1/admin/products${queryString}`);
  }

  async getProduct(id: string) {
    return this.request(`/api/v1/admin/products/${id}`);
  }

  // Orders
  async getOrders(params?: any) {
    const queryString = params ? `?${new URLSearchParams(params).toString()}` : '';
    return this.request(`/api/v1/admin/orders${queryString}`);
  }

  async getOrder(id: string) {
    return this.request(`/api/v1/admin/orders/${id}`);
  }

  // Carts
  async getCarts(params?: any) {
    const queryString = params ? `?${new URLSearchParams(params).toString()}` : '';
    return this.request(`/api/v1/admin/carts${queryString}`);
  }

  // Wallets
  async getWallets(params?: any) {
    const queryString = params ? `?${new URLSearchParams(params).toString()}` : '';
    return this.request(`/api/v1/admin/wallets${queryString}`);
  }

  // Notifications
  async getNotifications(params?: any) {
    const queryString = params ? `?${new URLSearchParams(params).toString()}` : '';
    return this.request(`/api/v1/admin/notifications${queryString}`);
  }

  // Analytics
  async getAnalytics(params?: any) {
    const queryString = params ? `?${new URLSearchParams(params).toString()}` : '';
    return this.request(`/api/v1/admin/analytics${queryString}`);
  }

  // Reports
  async getReports(params?: any) {
    const queryString = params ? `?${new URLSearchParams(params).toString()}` : '';
    return this.request(`/api/v1/admin/reports${queryString}`);
  }
}

export const adminAPI = new AdminAPI();



