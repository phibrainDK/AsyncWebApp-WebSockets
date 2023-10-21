FROM public.ecr.aws/lambda/nodejs:16


COPY handler.js package*.json ./
RUN npm install --omit=dev

# Set the command to run Lambda function
CMD [ "handler.handler" ]
