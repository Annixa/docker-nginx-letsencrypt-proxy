#!/bin/bash

TERM="xterm"
export TERM

# Only run if this variable is set; local stacks should generate a fake certificate.
# https://github.com/Annixa/docker-nginx-letsencrypt-proxy/issues/4
# Reintroduce LE_ENABLED mode
if [ "$LE_ENABLED" = false ]; then
	echo "DOCKER NGINX LET'S ENCRYPT: Let's Encrypt is disabled according to the environment variable LE_ENABLED. Using self-signed certificates instead.";
	exit 0;
fi

cd /opt/letsencrypt
LE="./letsencrypt-auto --config /opt/letsencrypt.ini certonly -n --keep-until-expiring --agree-tos --email $LE_EMAIL "

if [ "$LE_TEST" = true ]; then
	echo "LET'S ENCRYPT: TESTING MODE";
	LE="$LE --staging "
else
	echo "LET'S ENCRYPT: PRODUCTION MODE";
fi

# Parse domains
IFS=',' read -ra DOMAINS <<< "$LE_DOMAIN"
for i in "${DOMAINS[@]}"; do
    # process "$i"
    LE="$LE -d $i "
done

LE_OUTPUT=$($LE);
LE_EXIT=$?;

if [ $LE_EXIT -eq 0 ]; then

	# Determine if the files have changed

	ORIG_KEY=`md5sum /etc/nginx/ssl/nginx.key | awk '{print $1 }'`
	ORIG_CERT=`md5sum /etc/nginx/ssl/nginx.crt | awk '{print $1 }'`
	NEXT_KEY=`md5sum /etc/letsencrypt/live/$DOMAINS/privkey.pem | awk '{print $1 }'`
	NEXT_CERT=`md5sum /etc/letsencrypt/live/$DOMAINS/fullchain.pem | awk '{print $1 }'`

	echo $ORIG_KEY
	echo $ORIG_CERT
	echo $NEXT_KEY
	echo $NEXT_CERT

	if [ "$ORIG_KEY" != "$NEXT_KEY" ] || [ "$ORIG_CERT" != "$NEXT_CERT" ]; then
		echo "LET'S ENCRYPT: certificates have been updated!"
		cp /etc/letsencrypt/live/$DOMAINS/fullchain.pem /etc/nginx/ssl/nginx.crt 
		cp /etc/letsencrypt/live/$DOMAINS/privkey.pem /etc/nginx/ssl/nginx.key
		# Restart nginx?
		supervisorctl restart nginx

		if [ -z "$SLACK_NOTIFICATIONS_INFRA_URL" ]; then
			echo "LET'S ENCRYPT: set the SLACK_NOTIFICATIONS_INFRA_URL env variable in docker-compose.yml to get automatic notifications."
		else
			SLACK_PAYLOAD="payload={\"username\": \"letsencrypt\", \"text\": \"A certificate has been updated on *$LE_DOMAIN*. NGINX has been restarted.\", \"icon_emoji\": \":closed_lock_with_key:\"}"
			curl -X POST --data-urlencode "$SLACK_PAYLOAD" $SLACK_NOTIFICATIONS_INFRA_URL
		fi
	else
		echo "LET'S ENCRYPT: certificates are unchanged."
	fi

else #If there was an error with the request
	echo "LET'S ENCRYPT: There was an error with the request."
	echo "$LE_OUTPUT"
	if [ -z "$SLACK_NOTIFICATIONS_INFRA_URL" ]; then
		echo "LET'S ENCRYPT: set the SLACK_NOTIFICATIONS_INFRA_URL env variable in docker-compose.yml to get automatic notifications."
	else
		SLACK_PAYLOAD="payload={\"username\": \"letsencrypt\", \"text\": \"An error occured when trying to update the Let's Encrypt certificates.\", \"icon_emoji\": \":closed_lock_with_key:\", \"attachments\": [{	\"fallback\":\"Could not update certificates.\", 	\"color\":\"#FF0000\",  	\"pretext\": \"Error Message:\",	\"text\": \"$LE_OUTPUT\"}] }"
		curl -X POST --data-urlencode "$SLACK_PAYLOAD" $SLACK_NOTIFICATIONS_INFRA_URL
	fi
fi

