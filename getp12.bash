#!/bin/bash

client=$1

if [ x$client = x ]; then
	echo "Usage: $0 clientname"
	exit 1
fi

if [ ! -e keys/$client.key ]; then
	echo "Generating keys and p12..."
	. vars
	./pkitool $client
	cd keys
	openssl pkcs12 -export -inkey $client.key -in $client.crt -certfile ca.crt -out $client.p12 -password pass:
	echo "...keys and p12 generated."
fi

