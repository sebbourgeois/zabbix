#!/bin/bash
# Asterisk PJSIP Monitoring for Zabbix

# v1.0 -- Maksim Kuziev <maxrip@gmail.com>

### Path of Asterisk binary
ASTERISK=/usr/sbin/asterisk

if [ ! -n "$1" ]; then
    echo "Need an argument."
    exit 1
fi

$ASTERISK -rx "pjsip list endpoints"|grep "$1"| sed 's/Not in use/Not_in_use/' | sed 's/In use/In_use/' | awk '{print $4}'