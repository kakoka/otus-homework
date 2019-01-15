FROM alpine:latest

MAINTAINER Pavel Konotopov

ENV PHP_VERSION=7 \
    PHP_FPM_USER=www-data

RUN apk update \
    && apk upgrade \
    && apk add php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-gd \
    && mkdir -p /run/php/ \
    && sed -i 's/^listen = .*/listen = 0.0.0.0:9000/' /etc/php${PHP_VERSION}/php-fpm.d/www.conf

EXPOSE 9000

CMD ["/usr/sbin/php-fpm7", "-F"]
