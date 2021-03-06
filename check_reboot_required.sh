#!/bin/bash
#
# Check if a reboot is required after a debian/ubuntu package was upgraded.
#
# Usage:
#  check_puppet_agent.sh [-w <min>] [-c <min>]
#
# Options:
#  -w <min>
#     Do warn if a reboot is required since this ammount of minutes. Default 0.
#  -c <min>
#     Do critical if a reboot is required since this amount of minutes
#  -f <file>
#     Path to file which exstence indicates that a reboot is require.
#     Default /var/run/reboot-required
#
# Samuel Barabas <samuel@owee.de>, 29 November 2016
#

state_ok=0
state_warning=1
state_critical=2
state_unknown=3
state_dependent=4

reboot_file="/var/run/reboot-required"
warning=-1
critical=-1
text="no reboot required"

print_help() {
    awk 'NR == 3,!/^#/ {print p} { p = substr($0,2) }' $0
}

while getopts "w:c:f:h" opt; do
  case $opt in
    w)
      warning=$OPTARG
      ;;
    c)
      critical=$OPTARG
      ;;
    f)
      reboot_file=$OPTARG
      ;;
    *|h)
      print_help
      exit $state_unkown
      ;;
  esac
done

if [[ -e $reboot_file ]]; then
  created=$(stat -c %Y $reboot_file)
  now=$(date +%s)
  age=$(( ($now - $created) / 60)) # in minutes
  text="reboot is required since $age minutes"

  if [[ $critical -ge 0 && $age -gt $critical ]]; then
    echo "ERROR - $text"
    exit $state_critical
  elif [[ $warning -ge 0 && $age -gt $warning ]]; then
    echo "WARNING - $text"
    exit $state_warning
  fi

fi

echo "OK - $text"
