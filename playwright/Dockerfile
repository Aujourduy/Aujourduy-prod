# Dockerfile
FROM mcr.microsoft.com/playwright:focal

WORKDIR /app

COPY package*.json ./
RUN npm install && npx playwright install --with-deps

COPY . .

EXPOSE 3000
CMD ["node", "index.js"]
