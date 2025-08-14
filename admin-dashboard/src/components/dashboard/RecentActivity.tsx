import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Avatar,
  Box,
  Chip,
  IconButton,
} from '@mui/material';
import {
  ShoppingCart,
  Person,
  Inventory,
  Payment,
  Notifications,
  MoreVert,
} from '@mui/icons-material';

interface Activity {
  id: string;
  type: 'order' | 'user' | 'product' | 'payment' | 'notification';
  title: string;
  description: string;
  time: string;
  user?: string;
  amount?: string;
}

const RecentActivity: React.FC = () => {
  const activities: Activity[] = [
    {
      id: '1',
      type: 'order',
      title: 'New Order Received',
      description: 'Order #12345 has been placed by John Doe',
      time: '2 minutes ago',
      user: 'John Doe',
      amount: '$299.99',
    },
    {
      id: '2',
      type: 'user',
      title: 'New User Registration',
      description: 'Jane Smith has registered a new account',
      time: '5 minutes ago',
      user: 'Jane Smith',
    },
    {
      id: '3',
      type: 'product',
      title: 'Product Updated',
      description: 'iPhone 13 Pro stock has been updated',
      time: '10 minutes ago',
    },
    {
      id: '4',
      type: 'payment',
      title: 'Payment Processed',
      description: 'Payment of $299.99 has been processed successfully',
      time: '15 minutes ago',
      amount: '$299.99',
    },
    {
      id: '5',
      type: 'notification',
      title: 'System Alert',
      description: 'Low stock alert for Samsung Galaxy S21',
      time: '20 minutes ago',
    },
    {
      id: '6',
      type: 'order',
      title: 'Order Shipped',
      description: 'Order #12344 has been shipped to customer',
      time: '25 minutes ago',
      user: 'Mike Johnson',
    },
  ];

  const getActivityIcon = (type: Activity['type']) => {
    switch (type) {
      case 'order':
        return <ShoppingCart />;
      case 'user':
        return <Person />;
      case 'product':
        return <Inventory />;
      case 'payment':
        return <Payment />;
      case 'notification':
        return <Notifications />;
      default:
        return <Notifications />;
    }
  };

  const getActivityColor = (type: Activity['type']) => {
    switch (type) {
      case 'order':
        return 'primary.main';
      case 'user':
        return 'success.main';
      case 'product':
        return 'warning.main';
      case 'payment':
        return 'info.main';
      case 'notification':
        return 'error.main';
      default:
        return 'grey.500';
    }
  };

  const getActivityChipColor = (type: Activity['type']) => {
    switch (type) {
      case 'order':
        return 'primary';
      case 'user':
        return 'success';
      case 'product':
        return 'warning';
      case 'payment':
        return 'info';
      case 'notification':
        return 'error';
      default:
        return 'default';
    }
  };

  return (
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h6" component="h2">
            Recent Activity
          </Typography>
          <IconButton size="small">
            <MoreVert />
          </IconButton>
        </Box>
        
        <List sx={{ p: 0 }}>
          {activities.map((activity, index) => (
            <ListItem
              key={activity.id}
              sx={{
                px: 0,
                py: 1.5,
                borderBottom: index < activities.length - 1 ? '1px solid #f0f0f0' : 'none',
              }}
            >
              <ListItemIcon sx={{ minWidth: 40 }}>
                <Avatar
                  sx={{
                    width: 32,
                    height: 32,
                    backgroundColor: getActivityColor(activity.type),
                  }}
                >
                  {getActivityIcon(activity.type)}
                </Avatar>
              </ListItemIcon>
              
              <ListItemText
                primary={
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                      {activity.title}
                    </Typography>
                    <Chip
                      label={activity.type}
                      size="small"
                      color={getActivityChipColor(activity.type)}
                      sx={{ fontSize: '0.7rem', height: 20 }}
                    />
                  </Box>
                }
                secondary={
                  <Box>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                      {activity.description}
                    </Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Typography variant="caption" color="text.secondary">
                        {activity.time}
                      </Typography>
                      {activity.user && (
                        <Typography variant="caption" color="primary">
                          {activity.user}
                        </Typography>
                      )}
                      {activity.amount && (
                        <Typography variant="caption" color="success.main" sx={{ fontWeight: 500 }}>
                          {activity.amount}
                        </Typography>
                      )}
                    </Box>
                  </Box>
                }
              />
            </ListItem>
          ))}
        </List>
        
        <Box sx={{ mt: 2, textAlign: 'center' }}>
          <Typography
            variant="body2"
            color="primary"
            sx={{ cursor: 'pointer', '&:hover': { textDecoration: 'underline' } }}
          >
            View All Activities
          </Typography>
        </Box>
      </CardContent>
    </Card>
  );
};

export default RecentActivity;

