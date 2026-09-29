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
URLS=()

CMDMD5=$(which md5sum)
if [ -z "$CMDMD5" ]; then
    CMDMD5=$(which md5)
fi
if [ -z "$CMDMD5" ]; then
    echo "UNKNOWN - Could not find md5/md5sum command"
    exit $STATE_UNKNOWN
fi

print_help() {
    awk 'NR == 3,!/^#/ {print p} { p = substr($0,2) }' "$0"
}

for ARG in "$@"; do
    case $ARG in
        "-c")
            CRITICAL=true
            ;;
        "-h"|"--help")
            print_help
            exit $STATE_UNKNOWN
            ;;
        *)
            URLS+=("$ARG")
    esac
done

if [ ${#URLS[@]} -lt 2 ]; then
    echo "UNKNOWN - You need to specify at least two URLs"
    exit $STATE_UNKNOWN
fi

OTHERMD5=""
DIFFFOUND=false
DETAILS=""

for URL in "${URLS[@]}"; do
    # md5sum prints "<hash>  -", md5 only the hash; keep just the hash.
    # pipefail makes a failed download (curl -f) fail the whole pipeline.
    if ! MD5=$(set -o pipefail; curl -sf "$URL" | $CMDMD5 | awk '{print $1}'); then
        echo "UNKNOWN - Could not fetch $URL"
        exit $STATE_UNKNOWN
    fi
    DETAILS="$DETAILS
$URL : $MD5"
    if [ -z "$OTHERMD5" ]; then
        OTHERMD5=$MD5
    elif [ "$MD5" != "$OTHERMD5" ]; then
        DIFFFOUND=true
    fi
done

# the first line is the status, the per URL hashes follow as long output
if $DIFFFOUND; then
    if $CRITICAL; then
        echo "CRITICAL - The URLs deliver different content$DETAILS"
        exit $STATE_CRITICAL
    else
        echo "WARNING - The URLs deliver different content$DETAILS"
        exit $STATE_WARNING
    fi
fi

echo "OK - All URLs deliver the same content$DETAILS"
exit $STATE_OK

