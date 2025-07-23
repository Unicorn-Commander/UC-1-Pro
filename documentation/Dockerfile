# Stage 1: Build the static site
FROM python:3.11-slim as builder

WORKDIR /docs

# Install MkDocs and the Material theme
RUN pip install mkdocs-material

# Copy the documentation source files
COPY . .

# Build the static site
RUN mkdocs build

# Stage 2: Serve the static site with Nginx
FROM nginx:1.25-alpine

# Copy the built site from the builder stage
COPY --from=builder /docs/site /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
