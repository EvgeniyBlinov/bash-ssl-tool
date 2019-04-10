#!/bin/bash
# vim: set noet ci pi sts=0 sw=4 ts=4 :
error_exit() {
	echo "Error: $1"
	exit 1
}

usage() {
	echo "Usage: ${0##*/} [-h?vtHPSC]"
cat<<EOF
arguments:
	-t	  - type (host|secret)
	-H	  - host
	-P	  - port
	-S	  - secret name 'secret/name'
	-C	  - CA cert fot verify
	-h	  - help
	-?	  - help
	-v	  - verbose
EOF
	exit 100
}
########################################################################
while getopts "?hvt:H:P:S:C:" opt; do
	case "$opt" in
	\?|h)
		usage
		exit 0
		;;
	v) export VERBOSE=1 ;;
	t) export TYPE="$OPTARG";;
	H)
		export HOST="$OPTARG"
		export TYPE="host"
		;;
	P) export PORT="$OPTARG";;
	S)
		export SECRET="$OPTARG"
		export TYPE="secret"
		;;
	C) export CACERT="$OPTARG";;
	esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift
########################################################################

TYPE=${TYPE:-host}
OPERATION="$1"

[ 'xhost' == "x$TYPE" ] &&
	[ -z "$HOST" ] &&
	[ -n "$OPERATION" ] &&
	export HOST="$OPERATION"

[ 'xsecret' == "x$TYPE" ] &&
	[ -z "$SECRET" ] &&
	[ -n "$OPERATION" ] &&
	export SECRET="$OPERATION"

PORT=${PORT:-443}
HOST="${HOST:-localhost}"
VERBOSE=${VERBOSE:-0}

#echo "TYPE=$TYPE"
#echo "HOST=$HOST"
#echo "PORT=$PORT"
#echo "OPERATION=$OPERATION"
#echo "SECRET=$SECRET"
########################################################################

case "$TYPE" in
	host)
		CMD="timeout 3 openssl s_client -connect ${HOST}:${PORT} 2>/dev/null |
			openssl x509 -text"
		;;
	secret)
		CMD="kubectl get ${SECRET} -o jsonpath='{.data.tls\.crt}' |
			base64 -d -w0 - |
			openssl x509 -text"
		;;
esac

[ -n "$CACERT" ] &&
	CMD="$CMD | openssl verify -verbose -CAfile ${CACERT} /dev/stdin"

bash -c "$CMD"
