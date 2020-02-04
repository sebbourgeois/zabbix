#!/bin/bash
# Asterisk PJSIP Monitoring for Zabbix

# v1.0 -- Sebastien Bourgeois <sb@altho.st>
# This script is used for the discovery part of the template.

### Path of Asterisk binary
ASTERISK=/usr/sbin/asterisk

$ASTERISK -rx "pjsip show endpoints"|grep Contact|egrep -v "MaxContact|RTT\(ms\)"|awk '{print $2}'|cut -d "/" -f1 > /tmp/list
/usr/bin/jq -nR 'reduce inputs as $i ([]; .+[$i]) | map ({"{#TRUNKNAME}":.}) | {data: .}' /tmp/list