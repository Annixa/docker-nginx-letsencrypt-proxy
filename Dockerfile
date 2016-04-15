# Dockerfile for nginx letsencrypt proxy

FROM ubuntu:16.04
MAINTAINER Cristoffer Fairweather <cfairweather@annixa.com>

ENV DEBIAN_FRONTEND noninteractive

RUN usermod -u 1000 www-data
RUN groupmod -g 1000 www-data

RUN apt-get update && \
    apt-get install -y \
    nginx \
    supervisor \
    npm \
    curl \
    git && \
    apt-get clean

# configure nginx
RUN rm -f /etc/nginx/sites-enabled/default && \
    rm -f /etc/nginx/sites-available/default
COPY config/nginx/webapp.1.conf /etc/nginx/sites-available/webapp.1.conf
COPY config/nginx/webapp.2.conf /etc/nginx/sites-available/webapp.2.conf
# RUN ln -s /etc/nginx/sites-available/webapp.conf /etc/nginx/sites-enabled/webapp.conf

# config supervisor
RUN mkdir -p /var/log/supervisor
COPY config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create ssl directory
RUN mkdir -p /etc/nginx/ssl
RUN chmod 400 -R /etc/nginx/ssl

# Add entrypoint
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Let's Encrypt Support
WORKDIR /opt
RUN git clone https://github.com/letsencrypt/letsencrypt
COPY letsencrypt-run.py /opt/
COPY letsencrypt-run.sh /opt/
COPY letsencrypt.ini /opt/
RUN chmod +x letsencrypt-run.*
RUN mkdir -p /var/www/challenges && chmod 777 -R /var/www/challenges
RUN cd /opt/letsencrypt && ./letsencrypt-auto --help
VOLUME /etc/letsencrypt


WORKDIR /opt
EXPOSE 80 443
CMD ["/docker-entrypoint.sh"]
