# Use Node 18 with Alpine for smaller image
FROM node:18-alpine

WORKDIR /app

# Copy package files first for caching
COPY my-project/package*.json ./my-project/

WORKDIR /app/my-project

# Install dependencies with clean cache
RUN npm install --production && \
    npm cache clean --force

WORKDIR /app
COPY my-project ./my-project

# Build application
WORKDIR /app/my-project
RUN npm run build

# Runtime configuration
ENV NODE_ENV=production
EXPOSE 1337

# Use node user instead of root
USER node

CMD ["npm", "start"]
