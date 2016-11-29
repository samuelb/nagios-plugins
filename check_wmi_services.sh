#!/bin/bash
#
# Check if all Windows services, which are configured to start
# automatically, are running.
#
# Require  wmic - Windows Management Interface implementatio for Linux.
#  - http://www.orvant.com/packages/
#  - http://dev.zenoss.com/trac/browser/trunk/wmi
#
#
# Samuel Barabas <samuel@owee.de>, 27 Januar 2014
#

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

STATE=$STATE_OK
MESSAGE=""

usage() {
    echo "Usage: $0 -H host -u [domain\\]user -p password [-i service1[,servic*]]"
}

while getopts "H:u:p:i:" OPT; do
    case $OPT in
        H) HOST=$OPTARG;;
        u) USERNAME=$OPTARG;;
        p) PASSWORD=$OPTARG;;
        i) IGNORE=$OPTARG;;
        *) usage; exit $STATE_UNKNOWN;;
    esac
done

if [ -z "$HOST" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    usage
    exit $STATE_UNKNOWN
fi

# building WQL query
QUERY="select Name, DisplayName
        from Win32_Service where startmode = 'auto' and state != 'running'"
for service in ${IGNORE//,/ }; do
    QUERY="$QUERY and not name like '${service/\*/%}'"
done

# run wmi query
WMICSTR=$(wmic --user=$USERNAME --password=$PASSWORD //$HOST "$QUERY" 2>&1)

# test if a error occured
if [ ! $? -eq 0 ]; then
    echo "UNKOWN - $WMICSTR"
    exit $STATE_UNKNOWN
fi

IFS=$'\n'
for line in $WMICSTR; do
    if [ $line = "CLASS: Win32_Service" ] || [ $line = "DisplayName|Name" ]; then
        continue
    fi
    SVC_NAME=${line##*|}
    SVC_DESC=${line%%|*}
    STATE=$STATE_CRITICAL
    MESSAGE="$MESSAGE Service $SVC_DESC ($SVC_NAME) is not running."
done

case $STATE in
    $STATE_OK)
        echo "OK - All services are running"
        ;;
    $STATE_WARNING)
        echo "WARNING - $MESSAGE"
        ;;
    $STATE_CRITICAL)
        echo "CRITICAL - $MESSAGE"
        ;;
    $STATE_UNKOWN)
        echo "UNKNOWN - $MESSAGE"
        ;;
    $STATE_DEPENDENT)
        echo "DEPENDENT - $MESSAGE"
        ;;
esac

exit $STATE
