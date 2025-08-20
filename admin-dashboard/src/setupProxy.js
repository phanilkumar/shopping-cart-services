const { createProxyMiddleware } = require('http-proxy-middleware');

module.exports = function(app) {
  // Proxy user-service API calls
  app.use(
    '/api/v1',
    createProxyMiddleware({
      target: 'http://localhost:3001',
      changeOrigin: true,
      secure: false,
      logLevel: 'debug',
    })
  );

  // Proxy admin API calls to the admin dashboard API server
  app.use(
    '/api/admin',
    createProxyMiddleware({
      target: 'http://localhost:3009',
      changeOrigin: true,
      secure: false,
      logLevel: 'debug',
    })
  );
};
