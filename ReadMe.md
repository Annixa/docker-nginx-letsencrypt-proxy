# Docker Nginx with Let's Encrypt
Docker Nginx with Let's Encrypt uses the same nginx configuration for running (or proxying) your application and for handling acme-challenges from LE. 

This project provides a simple nginx configuration and auto-updating Let's Encrypt for integration with existing services. 

## When certificates are updated, the event handler will:
- Move the resulting certificates to `/etc/nginx/ssl`
- Tell `supervisor` to restart nginx: `supervisorctl restart nginx`
- If `SLACK_NOTIFICATIONS_INFRA_URL` is set, send a notification to your slack channel.


## The premise is simple:
- The image is configured to request a Let's Encrypt certificate for each of the (comma separated) domains listed in the `LE_DOMAIN` env variable provided in `docker-compose.yml`
  - Since Let's Encrypt is rate limited, an env variable of `LE_TEST=true` can be provided during testing (in `docker-compose.yml`).
- `supervisor` handles the running of nginx and the letsencrypt event handler, which is run every hour.
- If the hourly Let's Encrypt script yields an updated certificate, files are copied and `nginx` is restarted using the supervisor control call.
  - Provide a `SLACK_NOTIFICATIONS_INFRA_URL` in the `docker-compose.yml` to get a Slack notification of a certificate update!
