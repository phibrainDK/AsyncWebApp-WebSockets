FROM node:latest

# env environment
# ENV NODE_ENV=production

# file package.json and package-lock.json (or yarn.lock) in the current directory
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the files into the container
COPY . .

# run Node.js (customize)
CMD [ "node", "handler.js" ]