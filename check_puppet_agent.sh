#!/bin/bash
#
# Check the functionality of puppet agent on current host.
#
# Usage:
# check_puppet_agent.sh [-c] [-a <min>]  [-A <min>]  [-d <min>]  [-D <min>]
#
# Options:
# -a <min>
#     Issue a warning if puppet agent is applying the configuration for more
#     that <min> minutes. Good for check if puppet is stuck.
# -A <min>
#     Same as -a, but to a critical warning. Can be used together with -a.
# -d <min>
#     Issue a warning if puppet agent is disabled for more that <min> minutes.
# -D <min>
#     Same as -d, but to a critical warning. Can be used together with -d.
# -c
#     If puppet daemon is not runnit, do a critical alarm instead of warning.
#
#
# Samuel Barabas <samuel@owee.de>, 7 April 2016
#

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4
RUNNING="warn"

print_help() {
    awk 'NR == 3,!/^#/ {print p} { p = substr($0,2) }' $0
}

while getopts "a:A:d:D:ch" OPT; do
    case $OPT in
        a)
            APPLYING_WARNING=$OPTARG
            ;;
        A)
            APPLYING_CRITICAL=$OPTARG
            ;;
        d)
            DISABLED_WARNING=$OPTARG
            ;;
        D)
            DISABLED_CRITICAL=$OPTARG
            ;;
        c)
            RUNNING="crit"
            ;;
        *|h)
            print_help
            exit $STATE_UNKOWN
            ;;
    esac
done

# check puppet runnnig
if ! pgrep -f /usr/bin/puppet > /dev/null; then
    if [ $RUNNING = "crit" ]; then
        echo "CRITICAL - puppet agent daemon not running"
        exit $STATE_CRITICAL
    else
        echo "WARNING - puppet agent daemon not running"
        exit $STATE_WARNING
    fi
fi

# check puppet disabled
if [ ! -z $DISABLED_WARNING ] || [ ! -z $DISABLED_CRITICAL ]; then
    if [ -f /var/lib/puppet/state/agent_disabled.lock ]; then
        MESSAGE=$(cat /var/lib/puppet/state/agent_disabled.lock | grep -Po '(?<="disabled_message":")[^"]*')
        CREATED=$(stat -c %Y /var/lib/puppet/state/agent_disabled.lock)
        NOW=$(date +%s)
        AGE=$[($NOW-$CREATED)/60]
        if [ ! -z $DISABLED_CRITICAL ] && [ $AGE -ge $DISABLED_CRITICAL ]; then
            echo "CRITICAL - puppet is disabled with message '$MESSAGE' since $AGE minutes"
            exit $STATE_CRITICAL
        elif [ ! -z $DISABLED_WARNING ] && [ $AGE -ge $DISABLED_WARNING ]; then
            echo "WARNING - puppet is disabled with message '$MESSAGE' since $AGE minutes"
            exit $STATE_WARNING
        fi
    fi
fi

# check if puppet is stuck
if [ ! -z $APPLYING_WARNING ] || [ ! -z $APPLYING_CRITICAL ]; then
    if [ -f /var/lib/puppet/state/agent_catalog_run.lock ]; then
        CREATED=$(stat -c %Y /var/lib/puppet/state/agent_catalog_run.lock)
        NOW=$(date +%s)
        AGE=$[($NOW-$CREATED)/60]
        if [ ! -z $APPLYING_CRITICAL ] && [ $AGE -ge $APPLYING_CRITICAL ]; then
            echo "CRITICAL - puppet is applying for $AGE minutes now. maybe it's stuck"
            exit $STATE_CRITICAL
        elif [ ! -z $APPLYING_WARNING ] && [ $AGE -ge $APPLYING_WARNING ]; then
            echo "WARNING - puppet is applying for $AGE minutes now. maybe it's stuck"
            exit $STATE_WARNING
        fi
    fi
fi

# if script reaches here, everything is ok
echo "OK - puppet agent looks good"
exit $STATE_OK
