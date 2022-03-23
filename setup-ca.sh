#! /bin/bash

# Hostname for certificates.  'localhost' is good for testing,
# especially if you are behind a NAT.  However, it won't allow access
# from a remote device.  In order for this to work, you'll need to set
# HOSTNAME to an actual DNS name that resolves to this host.  If
# everything is behind a NAT, the name can resolve to a local address.
: ${HOSTNAME:=localhost}

# Setup the Certificate Authority and server certificates.  In
# general, this should be run once, to create these initial
# certificates, for development.

if [ -f certs/CA.crt -o -f certs/CA.key -o -f CADB.db \
	-o -f certs/SERVER.crt -o -f certs/SERVER.key ];
then
	echo "Server/CA certificates seem to already be present."
	exit 1
fi

mkdir -p certs

# Build the application.
go build || exit 1

# The HTTP server requires a private key for TLS.
openssl ecparam -name secp256r1 -genkey -out certs/SERVER.key

# Generate a self-signed X.509 certificate, containing the public key.
# This certificate should be available on any device(s) connecting to
# the HTTPS server to verify that we are communicating with the
# intended CA.
openssl req -new -x509 -sha256 -days 3650 -key certs/SERVER.key \
	-out certs/SERVER.crt \
        -subj "/O=Linaro, LTD/CN=$HOSTNAME"

# This certificate can be viewed with
# openssl x509 -in certs/SERVER.crt -noout -text

# The certificate authority also requires a key to sign certificates,
# which can be generated by the app.
./linaroca cakey generate

# Extract the CA certificate as C strings for inclusion in the demo
# app.
sed 's/.*/"&\\r\\n"/' certs/CA.crt > certs/ca_crt.txt

# The CA key is not extracted, as the device should have no access to
# this.

# **NOTE**: Certain values are hard-coded in `linaroca` when
# generating the CA certificate.  This utility may be extended to
# expose those values in the future, but at the moment the hard-coded
# values are sufficient for the proof-of-concept nature of this app.
