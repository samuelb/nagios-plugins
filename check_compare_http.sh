#!/bin/bash
#
# Compares the HTTP bodies of multiple URLs and alarms if they differs.
#
# Usage:
# check_compare_http.sh [-h] [-c] URL-1 URL-2 [... URL-n]
#
# Options:
# -h
#     Show this help text.
# -c
#     Raise a critical result instead of warning.
# URL
#     A http/https URL to compare content of.
#
#
# Samuel Barabas <samuel@owee.de>, 7 April 2016
#

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4
CRITICAL=false
URLS=""

CMDMD5=$(which md5sum)
if [ -z $CMDMD5 ]; then
    CMDMD5=$(which md5)
fi
if [ -z $CMDMD5 ]; then
    echo "Could not find md5/md5sum command" >&2
    exit $STATE_UNKNOWN
fi

print_help() {
    awk 'NR == 3,!/^#/ {print p} { p = substr($0,2) }' $0
}

ARGS="$*"

for ARG in $ARGS; do
    case $ARG in
        "-c")
            CRITICAL=true
            ;;
        "-h"|"--help")
            print_help
            exit $STATE_UNKOWN
            ;;
        *)
            URLS="$URLS $ARG"
    esac
done

if [ $(wc -w <<< "$URLS") -lt 2 ]; then
    echo "You need to specify at least two URLS" >&2
    exit $STATE_UNKNOWN
fi

OTHERMD5=""
DIFFFOUND=false

for URL in $URLS; do
    MD5=$(curl -s $URL | $CMDMD5)
    echo $URL : $MD5
    if [ -z $OTHERMD5 ]; then
        OTHERMD5=$MD5
    else
        if [ $MD5 != $OTHERMD5 ]; then
            DIFFFOUND=true
        fi
    fi
done

if $DIFFFOUND; then
    if $CRITICAL; then
        echo "CRITICAL - The URLs deliver different content"
        exit $STATE_CRITICAL
    else
        echo "WARNING - The URLs deliver different content"
        exit $STATE_WARNING
    fi
fi

echo "OK - All URLs deliver the same content"
exit $STATE_OK

