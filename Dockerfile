# Build stage: Install dependencies
FROM node:18-alpine3.17 AS build

# Set working directory
WORKDIR /usr/app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --only=production

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Run time stage
FROM node:18-alpine3.17

WORKDIR /usr/app

# Copy files from build stage
COPY --from=build /usr/app ./

# Set non-root user
USER appuser

# Expose port
EXPOSE 3000

# Start application
CMD [ "npm", "start" ]