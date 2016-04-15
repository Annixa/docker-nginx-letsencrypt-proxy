#!/bin/bash

set -e


# Check to see if let's encrypt has certificates already issued to a volume. 
# If so, immediately overwrite fake certificates.
if [ -z "$LE_DOMAIN" ] && [ -z "$LE_EMAIL" ]; then 
	echo "NGINX LET'S ENCRYPT: The env variables LE_DOMAIN and LE_EMAIL are required for automation";
	exit 1;
else 
	# Generate a local fake cert so nginx will start regardless of the success of LE, if it's configured to run.
	echo "NGINX LET'S ENCRYPT: Generate temporary certificate";
	# Parse domains
	IFS=',' read -ra DOMAINS <<< "$LE_DOMAIN"

	openssl req -passout pass: -subj "/C=US/ST=CA/L=San Diego/O=$DOMAINS/OU=TS/CN=$DOMAINS/emailAddress=support@$DOMAINS" -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt

	echo "NGINX LET'S ENCRYPT: Checking for previous certificate existence";
	LE_CERT="/etc/letsencrypt/live/$LE_DOMAIN/fullchain.pem"
	LE_KEY="/etc/letsencrypt/live/$LE_DOMAIN/privkey.pem"
	if [ -e $LE_CERT ] && [ -e $LE_KEY ]; then
		cp /etc/letsencrypt/live/$DOMAINS/fullchain.pem /etc/nginx/ssl/nginx.crt 
		cp /etc/letsencrypt/live/$DOMAINS/privkey.pem /etc/nginx/ssl/nginx.key
		echo "NGINX LET'S ENCRYPT: Previous keys found. Moved to nginx ssl directory";
	else
		echo "NGINX LET'S ENCRYPT: No certificates found.";
	fi
fi


# start up supervisor
/usr/bin/supervisord
