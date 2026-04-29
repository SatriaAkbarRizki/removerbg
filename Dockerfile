# Stage 1: Build
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:22-alpine
WORKDIR /app
RUN npm install -g serve
# Copy only the built files from the build stage
COPY --from=build /app/dist ./dist

EXPOSE 5173

# Serve the production build
CMD ["serve", "-s", "dist", "-l", "5173"]
