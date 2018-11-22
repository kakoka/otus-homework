FROM centos:latest
MAINTAINER Pavel Konotopov <kakoka@gmail.com>

COPY vts.repo /etc/yum.repos.d

RUN yum install -y nginx && yum clean all

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

WORKDIR /usr/share/nginx/html
RUN echo "NGINX with vts on CentOS 7 inside Docker" > /usr/share/nginx/html/index.html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
