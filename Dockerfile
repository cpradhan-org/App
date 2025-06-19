# Build stage: Install dependencies
FROM node:22-alpine3.21 AS build

# Set working directory
WORKDIR /usr/app

# Copy package files and install dependencies
COPY package*.json ./
COPY . .
RUN npm install --only=production

# Runtime stage
FROM node:22-alpine3.21

# Set working directory
WORKDIR /usr/app

# Copy built files from build stage
COPY --from=build /usr/app ./

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Run app
CMD [ "npm", "start" ]







# FROM node:18-alpine3.17
# WORKDIR /usr/app
# COPY package*.json /usr/app/
# RUN npm install
# COPY . .
# ENV MONGO_URI=uriPlaceholder
# ENV MONGO_USERNAME=usernamePlaceholder
# ENV MONGO_PASSWORD=passwordPlaceholder
# EXPOSE 3000
# CMD [ "npm", "start" ]