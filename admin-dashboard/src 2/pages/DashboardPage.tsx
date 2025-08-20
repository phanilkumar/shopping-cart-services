import React from 'react';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Chip,
  IconButton,
  useTheme,
} from '@mui/material';
import {
  TrendingUp,
  TrendingDown,
  People,
  ShoppingCart,
  Inventory,
  AccountBalanceWallet,
  Notifications,
  MoreVert,
  Visibility,
  VisibilityOff,
} from '@mui/icons-material';
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { useQuery } from 'react-query';
import { Helmet } from 'react-helmet-async';

import { adminAPI } from '../services/api/adminAPI';
import StatCard from '../components/dashboard/StatCard';
import RecentActivity from '../components/dashboard/RecentActivity';
import QuickActions from '../components/dashboard/QuickActions';

const DashboardPage: React.FC = () => {
  const theme = useTheme();

  // Fetch dashboard data
  const { data: dashboardData, isLoading, error } = useQuery('dashboardData', () =>
    adminAPI.getDashboardData()
  );

  // Use API data or fallback to mock data
  const apiStats = dashboardData?.stats || {
    total_revenue: 124563,
    total_orders: 1234,
    total_users: 8456,
    total_products: 156
  };

  // Chart data from API or fallback
  const salesData = dashboardData?.chart_data?.sales || [
    { name: 'Jan', sales: 4000, orders: 2400 },
    { name: 'Feb', sales: 3000, orders: 1398 },
    { name: 'Mar', sales: 2000, orders: 9800 },
    { name: 'Apr', sales: 2780, orders: 3908 },
    { name: 'May', sales: 1890, orders: 4800 },
    { name: 'Jun', sales: 2390, orders: 3800 },
  ];

  const userData = [
    { name: 'New Users', value: 400, color: '#8884d8' },
    { name: 'Active Users', value: 300, color: '#82ca9d' },
    { name: 'Inactive Users', value: 200, color: '#ffc658' },
  ];

  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042'];

  const stats = [
    {
      title: 'Total Revenue',
      value: `$${apiStats.total_revenue?.toLocaleString() || '124,563'}`,
      change: '+12.5%',
      trend: 'up' as const,
      icon: <TrendingUp />,
      color: 'success.main',
    },
    {
      title: 'Total Orders',
      value: apiStats.total_orders?.toLocaleString() || '1,234',
      change: '+8.2%',
      trend: 'up' as const,
      icon: <ShoppingCart />,
      color: 'primary.main',
    },
    {
      title: 'Total Users',
      value: apiStats.total_users?.toLocaleString() || '8,456',
      change: '+15.3%',
      trend: 'up' as const,
      icon: <People />,
      color: 'info.main',
    },
    {
      title: 'Total Products',
      value: apiStats.total_products?.toLocaleString() || '567',
      change: '+3.1%',
      trend: 'up' as const,
      icon: <Inventory />,
      color: 'warning.main',
    },
    {
      title: 'Active Wallets',
      value: '2,345',
      change: '+5.7%',
      trend: 'up' as const,
      icon: <AccountBalanceWallet />,
      color: 'secondary.main',
    },
    {
      title: 'Pending Notifications',
      value: '23',
      change: '-2.1%',
      trend: 'down' as const,
      icon: <Notifications />,
      color: 'error.main',
    },
  ];

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <Typography>Loading dashboard...</Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <Typography color="error">Error loading dashboard data: {(error as any)?.message || 'Unknown error'}</Typography>
      </Box>
    );
  }

  return (
    <>
      <Helmet>
        <title>Dashboard - Admin Panel</title>
      </Helmet>
      
      <Box>
        {/* Page Header */}
        <Box sx={{ mb: 3 }}>
          <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 600 }}>
            Dashboard
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Welcome back! Here's what's happening with your store today.
          </Typography>
        </Box>

        {/* Stats Cards */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          {stats.map((stat, index) => (
            <Grid item xs={12} sm={6} md={4} lg={2} key={index}>
              <StatCard
                title={stat.title}
                value={stat.value}
                change={stat.change}
                trend={stat.trend}
                icon={stat.icon}
                color={stat.color}
              />
            </Grid>
          ))}
        </Grid>

        {/* Charts Section */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          {/* Sales Chart */}
          <Grid item xs={12} lg={8}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                  <Typography variant="h6" component="h2">
                    Sales Overview
                  </Typography>
                  <IconButton size="small">
                    <MoreVert />
                  </IconButton>
                </Box>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={salesData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line
                      type="monotone"
                      dataKey="sales"
                      stroke={theme.palette.primary.main}
                      strokeWidth={2}
                    />
                    <Line
                      type="monotone"
                      dataKey="orders"
                      stroke={theme.palette.secondary.main}
                      strokeWidth={2}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </Grid>

          {/* User Distribution */}
          <Grid item xs={12} lg={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" component="h2" gutterBottom>
                  User Distribution
                </Typography>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={userData}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="value"
                    >
                      {userData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Additional Charts */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          {/* Revenue by Category */}
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" component="h2" gutterBottom>
                  Revenue by Category
                </Typography>
                <ResponsiveContainer width="100%" height={250}>
                  <BarChart data={salesData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="sales" fill={theme.palette.primary.main} />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </Grid>

          {/* Orders Trend */}
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" component="h2" gutterBottom>
                  Orders Trend
                </Typography>
                <ResponsiveContainer width="100%" height={250}>
                  <AreaChart data={salesData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis />
                    <Tooltip />
                    <Area
                      type="monotone"
                      dataKey="orders"
                      stackId="1"
                      stroke={theme.palette.secondary.main}
                      fill={theme.palette.secondary.light}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Bottom Section */}
        <Grid container spacing={3}>
          {/* Recent Activity */}
          <Grid item xs={12} lg={8}>
            <RecentActivity />
          </Grid>

          {/* Quick Actions */}
          <Grid item xs={12} lg={4}>
            <QuickActions />
          </Grid>
        </Grid>
      </Box>
    </>
  );
};

export default DashboardPage;
