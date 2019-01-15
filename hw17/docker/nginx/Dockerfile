FROM alpine:latest

MAINTAINER Pavel Konotopov

RUN apk update && apk upgrade && apk add nginx

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./default.conf /etc/nginx/conf.d/default.conf

WORKDIR /usr/share/nginx/html

RUN echo "New NGINX instance inside Docker" > /usr/share/nginx/html/index.html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
