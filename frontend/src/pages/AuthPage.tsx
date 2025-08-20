import React, { useState } from 'react';
import { Box, Container, Paper, Tabs, Tab } from '@mui/material';
import LoginForm from '../components/auth/LoginForm';
import RegisterForm from '../components/auth/RegisterForm';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`auth-tabpanel-${index}`}
      aria-labelledby={`auth-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
    </div>
  );
}

const AuthPage: React.FC = () => {
  const [tabValue, setTabValue] = useState(0);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleSwitchToRegister = () => {
    setTabValue(1);
  };

  const handleSwitchToLogin = () => {
    setTabValue(0);
  };

  const handleAuthSuccess = () => {
    // Redirect to dashboard or home page
    window.location.href = '/dashboard';
  };

  return (
    <Container maxWidth="sm">
      <Box
        sx={{
          marginTop: 4,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <Paper elevation={3} sx={{ width: '100%' }}>
          <Tabs
            value={tabValue}
            onChange={handleTabChange}
            variant="fullWidth"
            sx={{ borderBottom: 1, borderColor: 'divider' }}
          >
            <Tab label="Sign In" />
            <Tab label="Sign Up" />
          </Tabs>

          <TabPanel value={tabValue} index={0}>
            <LoginForm
              onSuccess={handleAuthSuccess}
              onSwitchToRegister={handleSwitchToRegister}
            />
          </TabPanel>

          <TabPanel value={tabValue} index={1}>
            <RegisterForm
              onSuccess={handleAuthSuccess}
              onSwitchToLogin={handleSwitchToLogin}
            />
          </TabPanel>
        </Paper>
      </Box>
    </Container>
  );
};

export default AuthPage;
