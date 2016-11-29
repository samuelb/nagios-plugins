nagios-plugins
==============

Collection self written scripts for Nagios/Icinga/Shinken/Sensu/LibreNMS.

I wrote this plugins to be used on Debian server. It's not said, that those
scripts work flawless on other Linux distributions.


Scripts
-------

### check_compare_http.sh

Compares the HTTP bodies of multiple URLs and alarms if they differs.
Useful for eg. check if multiple servers of a cluster have all the same
software version of you application deployed.

    check_compare_http.sh [-h] [-c] URL-1 URL-2 [... URL-n]

### check_puppet_agent.sh

Check the functionality of puppet agent on a host. Alarms if the puppet
agent daemon is not running for disabled for a longer time.

    check_puppet_agent.sh [-c] [-a <min>]  [-A <min>]  [-d <min>]  [-D <min>]


### check_reboot_required.sh

Check if a reboot is required after a Debian/Ubuntu package was upgraded.

    check_puppet_agent.sh [-w <min>] [-c <min>]

### check_wmi_services.sh

Check if a service on a windows machine is running using WMI. This scripts
requires the program *wmic* to be installed.

    check_wmi_services.sh -H host -u [domain\]user -p password [-i service[,service,..]]

You can get wmic here:
* http://www.orvant.com/packages/
* http://dev.zenoss.com/trac/browser/trunk/wmi


License Notice
--------------

You can redistribute and/or modify this software under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version; with the additional exemption that compiling, linking, and/or using OpenSSL is allowed.

This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the COPYING file for the complete text of the GNU General Public License, version 3.
