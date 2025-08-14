import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Box,
  Divider,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Visibility as ViewIcon,
  Download as DownloadIcon,
  Upload as UploadIcon,
  Settings as SettingsIcon,
  Notifications as NotificationsIcon,
  Assessment as ReportsIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

interface QuickAction {
  id: string;
  title: string;
  description: string;
  icon: React.ReactNode;
  path: string;
  color: string;
}

const QuickActions: React.FC = () => {
  const navigate = useNavigate();

  const quickActions: QuickAction[] = [
    {
      id: '1',
      title: 'Add Product',
      description: 'Create a new product listing',
      icon: <AddIcon />,
      path: '/admin/products/new',
      color: 'primary.main',
    },
    {
      id: '2',
      title: 'Manage Orders',
      description: 'View and process orders',
      icon: <EditIcon />,
      path: '/admin/orders',
      color: 'success.main',
    },
    {
      id: '3',
      title: 'User Management',
      description: 'Manage user accounts and roles',
      icon: <ViewIcon />,
      path: '/admin/users',
      color: 'info.main',
    },
    {
      id: '4',
      title: 'Export Reports',
      description: 'Download sales and analytics reports',
      icon: <DownloadIcon />,
      path: '/admin/reports',
      color: 'warning.main',
    },
    {
      id: '5',
      title: 'Import Data',
      description: 'Bulk import products or users',
      icon: <UploadIcon />,
      path: '/admin/import',
      color: 'secondary.main',
    },
    {
      id: '6',
      title: 'System Settings',
      description: 'Configure system preferences',
      icon: <SettingsIcon />,
      path: '/admin/settings',
      color: 'error.main',
    },
    {
      id: '7',
      title: 'Send Notifications',
      description: 'Send bulk notifications to users',
      icon: <NotificationsIcon />,
      path: '/admin/notifications',
      color: 'info.main',
    },
    {
      id: '8',
      title: 'View Analytics',
      description: 'Check detailed analytics and insights',
      icon: <ReportsIcon />,
      path: '/admin/analytics',
      color: 'success.main',
    },
  ];

  const handleActionClick = (path: string) => {
    navigate(path);
  };

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" component="h2" gutterBottom>
          Quick Actions
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          Common tasks and shortcuts
        </Typography>
        
        <List sx={{ p: 0 }}>
          {quickActions.map((action, index) => (
            <Box key={action.id}>
              <ListItem disablePadding>
                <ListItemButton
                  onClick={() => handleActionClick(action.path)}
                  sx={{
                    borderRadius: 1,
                    mb: 0.5,
                    '&:hover': {
                      backgroundColor: 'action.hover',
                    },
                  }}
                >
                  <ListItemIcon
                    sx={{
                      color: action.color,
                      minWidth: 40,
                    }}
                  >
                    {action.icon}
                  </ListItemIcon>
                  <ListItemText
                    primary={
                      <Typography variant="body2" sx={{ fontWeight: 500 }}>
                        {action.title}
                      </Typography>
                    }
                    secondary={
                      <Typography variant="caption" color="text.secondary">
                        {action.description}
                      </Typography>
                    }
                  />
                </ListItemButton>
              </ListItem>
              {index < quickActions.length - 1 && <Divider />}
            </Box>
          ))}
        </List>
        
        <Box sx={{ mt: 2, textAlign: 'center' }}>
          <Typography
            variant="body2"
            color="primary"
            sx={{ cursor: 'pointer', '&:hover': { textDecoration: 'underline' } }}
            onClick={() => navigate('/admin/settings')}
          >
            View All Actions
          </Typography>
        </Box>
      </CardContent>
    </Card>
  );
};

export default QuickActions;

