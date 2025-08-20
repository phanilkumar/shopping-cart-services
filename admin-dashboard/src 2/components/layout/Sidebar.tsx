import React from 'react';
import {
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Collapse,
  Box,
  Typography,
  Divider,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  People as PeopleIcon,
  Inventory as InventoryIcon,
  ShoppingCart as OrdersIcon,
  ShoppingBasket as CartsIcon,
  AccountBalanceWallet as WalletIcon,
  Notifications as NotificationsIcon,
  Analytics as AnalyticsIcon,
  Assessment as ReportsIcon,
  Settings as SettingsIcon,
  ExpandLess,
  ExpandMore,
  Person as UserIcon,
  Category as CategoryIcon,
  LocalShipping as ShippingIcon,
  Payment as PaymentIcon,
  Security as SecurityIcon,
  Store as StoreIcon,
} from '@mui/icons-material';
import { useLocation, useNavigate } from 'react-router-dom';

interface SidebarProps {
  onItemClick?: () => void;
}

interface MenuItem {
  text: string;
  icon: React.ReactNode;
  path: string;
  children?: MenuItem[];
}

const Sidebar: React.FC<SidebarProps> = ({ onItemClick }) => {
  const location = useLocation();
  const navigate = useNavigate();
  const [openSubmenus, setOpenSubmenus] = React.useState<{ [key: string]: boolean }>({});

  const menuItems: MenuItem[] = [
    {
      text: 'Dashboard',
      icon: <DashboardIcon />,
      path: '/admin/dashboard',
    },
    {
      text: 'Users',
      icon: <PeopleIcon />,
      path: '/admin/users',
      children: [
        { text: 'All Users', icon: <UserIcon />, path: '/admin/users' },
        { text: 'User Roles', icon: <SecurityIcon />, path: '/admin/users/roles' },
        { text: 'User Activity', icon: <AnalyticsIcon />, path: '/admin/users/activity' },
      ],
    },
    {
      text: 'Products',
      icon: <InventoryIcon />,
      path: '/admin/products',
      children: [
        { text: 'All Products', icon: <InventoryIcon />, path: '/admin/products' },
        { text: 'Categories', icon: <CategoryIcon />, path: '/admin/products/categories' },
        { text: 'Inventory', icon: <StoreIcon />, path: '/admin/products/inventory' },
      ],
    },
    {
      text: 'Orders',
      icon: <OrdersIcon />,
      path: '/admin/orders',
      children: [
        { text: 'All Orders', icon: <OrdersIcon />, path: '/admin/orders' },
        { text: 'Pending Orders', icon: <OrdersIcon />, path: '/admin/orders/pending' },
        { text: 'Shipping', icon: <ShippingIcon />, path: '/admin/orders/shipping' },
      ],
    },
    {
      text: 'Carts',
      icon: <CartsIcon />,
      path: '/admin/carts',
    },
    {
      text: 'Wallets',
      icon: <WalletIcon />,
      path: '/admin/wallets',
      children: [
        { text: 'All Wallets', icon: <WalletIcon />, path: '/admin/wallets' },
        { text: 'Transactions', icon: <PaymentIcon />, path: '/admin/wallets/transactions' },
        { text: 'Transfers', icon: <PaymentIcon />, path: '/admin/wallets/transfers' },
      ],
    },
    {
      text: 'Notifications',
      icon: <NotificationsIcon />,
      path: '/admin/notifications',
    },
    {
      text: 'Analytics',
      icon: <AnalyticsIcon />,
      path: '/admin/analytics',
    },
    {
      text: 'Reports',
      icon: <ReportsIcon />,
      path: '/admin/reports',
    },
    {
      text: 'Settings',
      icon: <SettingsIcon />,
      path: '/admin/settings',
    },
  ];

  const handleItemClick = (path: string) => {
    navigate(path);
    if (onItemClick) {
      onItemClick();
    }
  };

  const handleSubmenuToggle = (text: string) => {
    setOpenSubmenus(prev => ({
      ...prev,
      [text]: !prev[text],
    }));
  };

  const isActive = (path: string) => {
    return location.pathname === path || location.pathname.startsWith(path + '/');
  };

  const renderMenuItem = (item: MenuItem, level: number = 0) => {
    const hasChildren = item.children && item.children.length > 0;
    const isOpen = openSubmenus[item.text] || false;
    const active = isActive(item.path);

    return (
      <Box key={item.text}>
        <ListItem disablePadding>
          <ListItemButton
            onClick={() => {
              if (hasChildren) {
                handleSubmenuToggle(item.text);
              } else {
                handleItemClick(item.path);
              }
            }}
            sx={{
              pl: 2 + level * 2,
              backgroundColor: active ? 'primary.light' : 'transparent',
              color: active ? 'primary.contrastText' : 'inherit',
              '&:hover': {
                backgroundColor: active ? 'primary.main' : 'action.hover',
              },
            }}
          >
            <ListItemIcon
              sx={{
                color: active ? 'primary.contrastText' : 'inherit',
                minWidth: 40,
              }}
            >
              {item.icon}
            </ListItemIcon>
            <ListItemText
              primary={
                <Typography
                  variant="body2"
                  sx={{
                    fontWeight: active ? 600 : 400,
                  }}
                >
                  {item.text}
                </Typography>
              }
            />
            {hasChildren && (isOpen ? <ExpandLess /> : <ExpandMore />)}
          </ListItemButton>
        </ListItem>
        
        {hasChildren && (
          <Collapse in={isOpen} timeout="auto" unmountOnExit>
            <List component="div" disablePadding>
              {item.children!.map(child => renderMenuItem(child, level + 1))}
            </List>
          </Collapse>
        )}
      </Box>
    );
  };

  return (
    <Box sx={{ width: '100%', pt: 1 }}>
      <Box sx={{ px: 2, py: 1 }}>
        <Typography variant="h6" sx={{ fontWeight: 600, color: 'primary.main' }}>
          Admin Panel
        </Typography>
        <Typography variant="caption" color="text.secondary">
          E-commerce Management
        </Typography>
      </Box>
      <Divider sx={{ my: 1 }} />
      <List>
        {menuItems.map(item => renderMenuItem(item))}
      </List>
    </Box>
  );
};

export default Sidebar;



