# FROM node:18-alpine
FROM node:18

WORKDIR /app

# Copy only package files first for caching
COPY my-project/package*.json ./my-project/

WORKDIR /app/my-project
RUN npm install

WORKDIR /app
COPY my-project ./my-project

WORKDIR /app/my-project
RUN npm run build

EXPOSE 1337

CMD ["npm", "start"]
