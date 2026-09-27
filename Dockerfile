# --- Production image: serves the pre-built React app on port 80 ---
FROM nginx:stable-alpine

# Remove default nginx static content
RUN rm -rf /usr/share/nginx/html/*

# Copy the already-built React app (the repo ships a ready 'build/' folder)
COPY build/ /usr/share/nginx/html/

# Optional: SPA-friendly nginx config so client-side routes don't 404 on refresh
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
