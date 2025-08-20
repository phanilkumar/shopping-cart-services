# Microservices Admin Dashboard

A modern React-based admin dashboard for monitoring and managing microservices infrastructure.

## Features

- **Real-time Service Monitoring**: Monitor the health and status of all microservices
- **Service Management**: Restart services directly from the dashboard
- **Live Logs**: View real-time logs from each service
- **System Overview**: Comprehensive statistics and metrics
- **Responsive Design**: Works on desktop and mobile devices
- **Auto-refresh**: Automatically updates service status and logs

## Supported Services

- **Auth Service** (Port 3001)
- **OAuth Service** (Port 3002) 
- **User Service** (Port 3003)

## Getting Started

### Prerequisites

- Node.js 16+ 
- npm or yarn
- Running microservices on their respective ports

### Installation

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm start
```

3. Open [http://localhost:3000](http://localhost:3000) to view the dashboard

### Building for Production

```bash
npm run build
```

## Configuration

The dashboard automatically detects microservices on the following ports:
- Auth Service: `http://localhost:3001`
- OAuth Service: `http://localhost:3002`
- User Service: `http://localhost:3003`

To customize the configuration, edit `src/services/api.ts` and modify the `MICROSERVICES` array.

## API Endpoints

The dashboard expects the following endpoints from each microservice:

### Health Check
- **GET** `/health` - Returns service health status
- Response: `{ health: number, uptime: string, version: string }`

### Metrics (Optional)
- **GET** `/metrics` - Returns service metrics
- Response: `{ requestsPerMinute, averageResponseTime, errorRate, activeConnections, memoryUsage, cpuUsage }`

### Logs (Optional)
- **GET** `/logs?limit=50` - Returns service logs
- Response: `{ logs: LogEntry[] }`

## Docker Deployment

Build the Docker image:
```bash
docker build -t microservices-admin-dashboard .
```

Run the container:
```bash
docker run -p 3000:3000 microservices-admin-dashboard
```

## Development

### Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── ServiceCard.tsx  # Individual service display
│   ├── StatsCard.tsx    # System overview statistics
│   └── ServiceLogs.tsx  # Service logs display
├── pages/              # Page components
│   └── DashboardPage.tsx # Main dashboard page
├── services/           # API and external services
│   └── api.ts          # Microservices API client
├── types/              # TypeScript type definitions
│   └── index.ts        # Interface definitions
└── utils/              # Utility functions
```

### Adding New Services

1. Add the service configuration to `MICROSERVICES` array in `src/services/api.ts`
2. Ensure the service implements the required health check endpoint
3. Optionally implement metrics and logs endpoints for enhanced monitoring

## Troubleshooting

### Services Not Showing
- Ensure all microservices are running on their configured ports
- Check that health endpoints are accessible
- Verify network connectivity between dashboard and services

### Logs Not Loading
- Ensure the service implements the `/logs` endpoint
- Check CORS configuration on the service
- Verify the logs endpoint returns the expected format

### Performance Issues
- Increase the refresh interval in `DashboardPage.tsx`
- Reduce the number of log entries fetched
- Optimize service health check endpoints

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details
