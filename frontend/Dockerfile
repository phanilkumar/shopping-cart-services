FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Start development server with host binding
CMD ["sh", "-c", "npm start -- --host 0.0.0.0 --port 3000"]



