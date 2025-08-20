# 🚀 Vite Migration Guide

## Overview

This document outlines the migration from Create React App (CRA) to Vite for both the **Frontend** and **Admin Dashboard** applications in our ecommerce microservices project.

## 🎯 Why Vite?

### Performance Benefits
- **Lightning-fast HMR**: Hot Module Replacement that's 10-100x faster than CRA
- **Instant server start**: No bundling during development
- **Optimized builds**: Faster production builds with better tree-shaking
- **ES modules**: Native ES modules for better development experience

### Developer Experience
- **Faster feedback loop**: Changes reflect immediately
- **Better error messages**: More precise error reporting
- **Modern tooling**: Built on modern web standards
- **Plugin ecosystem**: Rich ecosystem of plugins

## 📁 Project Structure

```
shopping_cart/
├── frontend/                 # Main ecommerce frontend (Vite)
│   ├── index.html           # Vite entry point
│   ├── vite.config.ts       # Vite configuration
│   ├── tsconfig.json        # TypeScript config
│   ├── tsconfig.node.json   # Node.js TypeScript config
│   ├── .eslintrc.cjs        # ESLint configuration
│   └── src/
│       ├── main.tsx         # React entry point (renamed from index.tsx)
│       └── ...
├── admin-dashboard/         # Admin dashboard (Vite)
│   ├── index.html           # Vite entry point
│   ├── vite.config.ts       # Vite configuration
│   ├── tsconfig.json        # TypeScript config
│   ├── tsconfig.node.json   # Node.js TypeScript config
│   ├── .eslintrc.cjs        # ESLint configuration
│   └── src/
│       ├── main.tsx         # React entry point (renamed from index.tsx)
│       └── ...
└── docker-compose.yml       # Updated for Vite
```

## 🔧 Configuration Changes

### Frontend Configuration

#### `vite.config.ts`
```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tsconfigPaths from 'vite-tsconfig-paths'
import { resolve } from 'path'

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3005,
    host: true,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        secure: false,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          mui: ['@mui/material', '@mui/icons-material'],
          router: ['react-router-dom'],
          redux: ['@reduxjs/toolkit', 'react-redux'],
        },
      },
    },
  },
})
```

#### `tsconfig.json`
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

### Admin Dashboard Configuration

#### `vite.config.ts`
```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tsconfigPaths from 'vite-tsconfig-paths'
import { resolve } from 'path'

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3008,
    host: true,
    proxy: {
      '/api/v1': {
        target: 'http://localhost:3001',
        changeOrigin: true,
        secure: false,
      },
      '/api/admin': {
        target: 'http://localhost:3009',
        changeOrigin: true,
        secure: false,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          router: ['react-router-dom'],
          charts: ['recharts'],
          icons: ['lucide-react'],
        },
      },
    },
  },
})
```

## 📦 Package.json Changes

### Dependencies Added
```json
{
  "devDependencies": {
    "@vitejs/plugin-react": "^4.0.3",
    "vite": "^4.4.5",
    "vite-tsconfig-paths": "^4.2.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint-plugin-react-refresh": "^0.4.3"
  }
}
```

### Dependencies Removed
```json
{
  "dependencies": {
    "react-scripts": "5.0.1"  // Removed
  }
}
```

### Scripts Updated
```json
{
  "scripts": {
    "dev": "vite",                    // Instead of "start": "react-scripts start"
    "build": "tsc && vite build",     // Instead of "build": "react-scripts build"
    "preview": "vite preview",        // New: preview production build
    "test": "vitest"                  // Instead of "test": "react-scripts test"
  }
}
```

## 🐳 Docker Configuration

### Frontend Dockerfile
```dockerfile
# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the app
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built app to nginx
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

### Admin Dashboard Dockerfile.dev
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Install Docker CLI for container management
RUN apk add --no-cache docker-cli

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Expose port for Vite dev server
EXPOSE 3008

# Start Vite development server
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
```

### Docker Compose Updates
```yaml
# Frontend React App (Vite)
frontend:
  build:
    context: ./frontend
    dockerfile: Dockerfile
  ports:
    - "3005:3005"
  environment:
    VITE_API_URL: http://localhost:3000
    VITE_ENV: development
    PORT: 3005
  command: sh -c "npm run dev -- --host 0.0.0.0 --port 3005"

# Admin Dashboard (Vite)
admin-dashboard:
  build:
    context: ./admin-dashboard
    dockerfile: Dockerfile.dev
  ports:
    - "3008:3008"
  environment:
    VITE_API_URL: http://localhost:3000
    VITE_ENV: development
    PORT: 3008
  command: sh -c "npm run dev -- --host 0.0.0.0 --port 3008"
```

## 🚀 Development Commands

### Local Development
```bash
# Frontend
cd frontend
npm install
npm run dev

# Admin Dashboard
cd admin-dashboard
npm install
npm run dev
```

### Docker Development
```bash
# Start all services with Vite
docker compose up

# Start specific services
docker compose up frontend admin-dashboard

# Rebuild after dependency changes
docker compose build frontend admin-dashboard
```

### Production Build
```bash
# Frontend
cd frontend
npm run build
npm run preview

# Admin Dashboard
cd admin-dashboard
npm run build
npm run preview
```

## 🔄 Migration Checklist

### ✅ Completed
- [x] Updated `package.json` with Vite dependencies
- [x] Created `vite.config.ts` for both applications
- [x] Updated TypeScript configuration
- [x] Created `index.html` entry points
- [x] Renamed `index.tsx` to `main.tsx`
- [x] Updated ESLint configuration
- [x] Updated Docker configurations
- [x] Updated Docker Compose
- [x] Created nginx configuration for production
- [x] Updated environment variables (REACT_APP_ → VITE_)

### 🔄 Environment Variables
**Before (CRA):**
```bash
REACT_APP_API_URL=http://localhost:3000
REACT_APP_ENV=development
```

**After (Vite):**
```bash
VITE_API_URL=http://localhost:3000
VITE_ENV=development
```

### 📝 Code Changes Required
1. **Environment Variables**: Update all `process.env.REACT_APP_*` to `import.meta.env.VITE_*`
2. **Import Statements**: Some imports may need adjustment for ES modules
3. **Public Assets**: Move from `public/` to `public/` (same location, different handling)

## 🎉 Benefits Achieved

### Performance
- **Development**: 10-100x faster HMR
- **Build**: Faster production builds
- **Startup**: Instant dev server startup

### Developer Experience
- **Hot Reload**: Near-instant feedback
- **Error Messages**: Better error reporting
- **Modern Tooling**: ES modules and modern standards

### Production
- **Bundle Size**: Optimized chunks
- **Tree Shaking**: Better dead code elimination
- **Caching**: Improved asset caching

## 🛠️ Troubleshooting

### Common Issues

#### 1. Environment Variables Not Working
```typescript
// ❌ Old way (CRA)
const apiUrl = process.env.REACT_APP_API_URL;

// ✅ New way (Vite)
const apiUrl = import.meta.env.VITE_API_URL;
```

#### 2. Import Errors
```typescript
// ❌ May not work in Vite
import { something } from './file.js';

// ✅ Use explicit extensions or let Vite resolve
import { something } from './file';
```

#### 3. Build Errors
```bash
# Clear cache and rebuild
rm -rf node_modules package-lock.json
npm install
npm run build
```

#### 4. Docker Issues
```bash
# Rebuild containers
docker compose down
docker compose build --no-cache
docker compose up
```

## 📚 Additional Resources

- [Vite Documentation](https://vitejs.dev/)
- [Vite React Plugin](https://github.com/vitejs/vite-plugin-react)
- [Vite Migration Guide](https://vitejs.dev/guide/migration.html)
- [Vite Configuration Reference](https://vitejs.dev/config/)

## 🎯 Next Steps

1. **Test thoroughly** in development and production
2. **Update CI/CD pipelines** for Vite builds
3. **Monitor performance** improvements
4. **Update documentation** for team members
5. **Consider additional Vite plugins** as needed

---

**Migration completed successfully! 🚀**

Both frontend applications now use Vite for faster development and optimized production builds.
