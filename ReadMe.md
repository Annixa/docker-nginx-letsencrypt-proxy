Docker Nginx Proxy with Let's Encrypt
=====================================

![GitHub Release Version](https://img.shields.io/github/release/annixa/docker-nginx-letsencrypt-proxy.svg)
![Docker Hub Pulls](https://img.shields.io/docker/pulls/annixa/docker-nginx-letsencrypt-proxy.svg)
![Docker Hub Stars](https://img.shields.io/docker/stars/annixa/docker-nginx-letsencrypt-proxy.svg)
![GitHub Open Issues](https://img.shields.io/github/issues/annixa/docker-nginx-letsencrypt-proxy.svg)

Docker Nginx Proxy with Let's Encrypt simplifies application integration with Let's Encrypt.

This project provides a simple nginx configuration and auto-updating Let's Encrypt for integration with existing services. 

Docker Hub image: [docker-nginx-letsencrypt-proxy](https://hub.docker.com/r/annixa/docker-nginx-letsencrypt-proxy/)

Quick Deploy (`docker-compose.yml`)
-----------------------------------
> _"Put this in your stack and deploy it."_
```
version: '2'
docker-nginx-letsencrypt-proxy:
    build: .
    ports:
        - 80:80
        - 443:443
    container_name: docker-nginx-letsencrypt-proxy
    log_opt:
         max-size: 50k
    environment:
        - LE_ENABLED=true
        # - LE_TEST=true # LE is rate limited. While doing development, be sure to set testing mode so requests don't count against our quota.
        - LE_EMAIL=test@test.com # Your email, here
        - LE_DOMAIN=domain.com #A comma separated list of your domains, here
        - PROXY_DEST=https://www.google.com #A comma separated list of destinations for the proxied services
        # - PROXY_PORT=8443
        # - SLACK_NOTIFICATIONS_INFRA_URL=https://hooks.slack.com/services/???????? # Be sure to fill this in using your URL for the slack webhook integration
    volumes:
      - "/etc/letsencrypt"
    # links:
    #   - mycontainer
    # If using version 1, link to your container
```

Configuration
-------------

The following docker environment variables are required for proper usage:
- `LE_EMAIL`, the email address for use with Let's Encrypt (simply registers your public key for retrieval).
- `LE_DOMAIN`, a comma separated list of domains current configured to point at your server
- `PROXY_DEST`, a comma separated list of destinations for the proxied services; along the lines of `http://mydestination.com` or `http://localhost:8000`. There should be as many destinations as `LE_DOMAIN`s; however, for each without a corresponding destination, the first destination will be used for the remaining `LE_DOMAIN`s.
- `PROXY_PORT`, the port on which the https connections will be served. Defaults to 443
- `SLACK_NOTIFICATIONS_INFRA_URL` (optional), the slack webhook integration URL to receive slack notifications upon certificate update or `letsencrypt-auto` error.
- `LE_ENABLED` (optional, defaults to true), For local, non-public development stacks, set to `false`. This will disable requests to Let's Encrypt for certificates and use self signed certificates instead.
- `LE_TEST` (optional), LE is rate limited. While testing your stack, be sure to set testing mode so requests don't count against your domain quota. Such certificates will not be valid, but are sufficient to test your setup.
  - See [https://community.letsencrypt.org/t/rate-limits-for-lets-encrypt/6769](https://community.letsencrypt.org/t/rate-limits-for-lets-encrypt/6769) for more information.
- `TLS_SETTING` (optional), one of `MODERN`, `INTERMEDIATE`, OR `OLD`. All other values will be igored. `MODERN` is default to allow for the best security setting.
  - See [https://wiki.mozilla.org/Security/Server_Side_TLS](https://wiki.mozilla.org/Security/Server_Side_TLS) for more details
  - See [docker-entrypoint.sh](https://github.com/Annixa/docker-nginx-letsencrypt-proxy/blob/master/docker-entrypoint.sh) for the suites used
  - Updated August 6, 2017
  - This setting will correspond to the following browser compatibilities:
  
| Configuration | Oldest compatible client | 
| ------------- |:------------------------|
| `MODERN` | Firefox 27, Chrome 30, IE 11 on Windows 7, Edge, Opera 17, Safari 9, Android 5.0, Java 8 |
| `INTERMEDIATE` |	Firefox 1, Chrome 1, IE 7, Opera 5, Safari 1, Windows XP IE8, Android 2.3, Java 7 |
| `OLD` |	Windows XP IE6, Java 6 | 

How It Works
------------

When certificates are updated, the event handler will:

1. Move the resulting certificates to `/etc/nginx/ssl`
1. Tell `supervisor` to restart nginx: `supervisorctl restart nginx`
1. If `SLACK_NOTIFICATIONS_INFRA_URL` is set, send a notification to your slack channel.

The premise is simple:

- The image is configured to request a Let's Encrypt certificate for each of the (comma separated) domains listed in the `LE_DOMAIN` env variable provided in `docker-compose.yml`
  - Since Let's Encrypt is rate limited, an env variable of `LE_TEST=true` can be provided during testing (in `docker-compose.yml`).
- `supervisor` handles the running of nginx and the letsencrypt event handler, which is run every hour.
- If the hourly Let's Encrypt script yields an updated certificate, files are copied and `nginx` is restarted using the supervisor control call.
  - Provide a `SLACK_NOTIFICATIONS_INFRA_URL` in the `docker-compose.yml` to get a Slack notification of a certificate update!
