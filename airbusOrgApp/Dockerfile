FROM node:12.16

LABEL maintainer "Sudeep Sagar <sudeepjc@gmail.com>"

RUN apt-get update && apt-get install python

WORKDIR /app

COPY ./package*.json ./

RUN npm install

COPY . .

EXPOSE 4000

CMD ["npm","run","start"]