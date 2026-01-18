#!/bin/bash
#

#Log for events filter debug
#echo "$(date '+%F %T') | $0 | args: $*" >> /recalbox/share/userscripts/Debug_args.log

# workaround to avoid conigurationchanged when reboot/shutdown event
touch /tmp/recalbox_rebooting