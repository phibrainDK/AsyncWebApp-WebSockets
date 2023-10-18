FROM node:14-alpine

# env environment
# ENV NODE_ENV=production

# file package.json and package-lock.json (or yarn.lock) in the current directory
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the files into the container
COPY . .

RUN npm install --production
# run Node.js (customize)
CMD [ "node", "handler.js" ]
