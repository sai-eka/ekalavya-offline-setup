# Stage 1: Build all workspaces
FROM node:20-alpine AS build

RUN apk add --no-cache git bash python3 g++ make cairo-dev pango-dev jpeg-dev giflib-dev

WORKDIR /app

RUN git clone --depth=1 --branch feature/no-ref/ekalavya https://github.com/ekalavya-io/ekalavya-scratch-editor.git .

# Install dependencies for all workspaces
RUN npm ci --legacy-peer-deps

# Build everything (this builds GUI, VM, renderers, etc.)
RUN npm run build

# Stage 2: Serve the Scratch GUI via Nginx
FROM nginx:alpine

# Copy the built GUI (the web entry point)
COPY --from=build /app/packages/scratch-gui/build /usr/share/nginx/html

EXPOSE 8601
CMD ["nginx", "-g", "daemon off;"]
