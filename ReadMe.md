# Docker Nginx Proxy with Let's Encrypt
Docker Nginx Proxy with Let's Encrypt simplifies application integration with Let's Encrypt.

This project provides a simple nginx configuration and auto-updating Let's Encrypt for integration with existing services. 

##Configuration:
The following docker environment variables are required for proper usage:
- `LE_DOMAIN`, a comma separated list of domains current configured to point at your server
- `LE_EMAIL`, the email address for use with Let's Encrypt (simply registers your public key for retrieval).
- `PROXY_DEST`, the destination for the proxied service; along the lines of `http://mydestination.com` or `http://localhost:8000`
- `SLACK_NOTIFICATIONS_INFRA_URL` (optional), the slack webhook integration URL to receive slack notifications upon certificate update or `letsencrypt-auto` error.

### When certificates are updated, the event handler will:
- Move the resulting certificates to `/etc/nginx/ssl`
- Tell `supervisor` to restart nginx: `supervisorctl restart nginx`
- If `SLACK_NOTIFICATIONS_INFRA_URL` is set, send a notification to your slack channel.


### The premise is simple:
- The image is configured to request a Let's Encrypt certificate for each of the (comma separated) domains listed in the `LE_DOMAIN` env variable provided in `docker-compose.yml`
  - Since Let's Encrypt is rate limited, an env variable of `LE_TEST=true` can be provided during testing (in `docker-compose.yml`).
- `supervisor` handles the running of nginx and the letsencrypt event handler, which is run every hour.
- If the hourly Let's Encrypt script yields an updated certificate, files are copied and `nginx` is restarted using the supervisor control call.
  - Provide a `SLACK_NOTIFICATIONS_INFRA_URL` in the `docker-compose.yml` to get a Slack notification of a certificate update!
