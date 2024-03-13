FROM php:8.2-fpm-alpine3.19

WORKDIR /app
ENV TZ=Europe/Warsaw

RUN echo "hello world"
