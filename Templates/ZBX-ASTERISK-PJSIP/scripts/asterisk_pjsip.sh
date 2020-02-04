#!/bin/bash
# Asterisk PJSIP Monitoring for Zabbix

# v1.0 -- Sebastien Bourgeois <sb@altho.st>

### Path of Asterisk binary
ASTERISK=/usr/sbin/asterisk

# Warning
# -------
# This script is designed to work with our current scheme at work, one trunk
# for incoming calls, one trunk for outgoing calls.
#
# If you have only one trunk, you can deactivate the incoming/outgoing calls
# items as they won't be relevant in your case
QUEUEINC="ctt-inc"
QUEUEOUT="ctt-out"

if [ ! -n "$1" ]; then
    echo "Need an argument !"
    exit 1
fi

function calls.active(){
    CALL=`$ASTERISK -rx "core show channels" |grep "active call"|awk '{print$1}'`
    echo "$CALL"
}

function calls.processed(){
    CALL=`$ASTERISK -rx "core show channels" |grep "calls processed"|awk '{print$1}'`
    echo "$CALL"
}

function calls.longest(){
    CHANNEL="$($ASTERISK -rx 'core show channels concise' | cut -f12,1 -d'!' | sed 's/!/ /g' | sort -n -k 2 | tail -1)"
    CHANNEL_NAME=$(echo $CHANNEL |awk '{print$1}')
    CHANNEL_TIME=$(echo $CHANNEL |awk '{print$2}')
    CHANNEL_TIME=${CHANNEL_TIME:-"0"}

    if [ "$CHANNEL_TIME" -gt 7200 ]; then
        asterisk -rx "channel request hangup $CHANNEL_NAME" >> /var/log/asterisk/full
        sleep 1

        if [ "`$ASTERISK -rx 'core show channels concise' | grep $CHANNEL_NAME`" ]; then
            echo "$CHANNEL_NAME is $CHANNEL_TIME long"
        else
            echo 1
        fi
    else
        echo 1
    fi
}

function calls.incoming(){
    CALL=`$ASTERISK -rx "core show channels" |grep "$QUEUEINC"|wc -l`
    echo "$CALL"
}

function calls.outgoing(){
    CALL=`$ASTERISK -rx "core show channels" |grep "$QUEUEOUT"|wc -l`
    echo "$CALL"
}

function channels.active(){
    CHANNEL=`$ASTERISK -rx "core show channels" | grep "active channels" | awk '{print $1}'`
    echo "$CHANNEL"
}

function status(){
    proc_status='pidof asterisk'
    if [ -n "$proc_status" ]; then
        echo "1"
    else
        echo "0"
    fi
}

function status.crashes(){
    if [ -n "`find /tmp/ -type f -mtime -1 -name 'core*'`" ]; then
        echo 1
    else
        echo 0
    fi
}

function status.reload(){
    reload_time=`$ASTERISK -rx "core show uptime seconds" | awk -F": " '/Last reload/{print$2}'`
    if [ -z "$reload_time" ];then
        echo "Asterisk has not been reloaded yet"
    else
        printf '%dd:%dh:%dm:%ds\n' $(($reload_time/86400)) $(($reload_time%86400/3600)) $(($reload_time%3600/60)) $(($reload_time%60))
    fi
}

function status.uptime(){
    uptime=`$ASTERISK -rx "core show uptime seconds" | awk -F": " '/System uptime/{print$2}'`
    if [ -z "$uptime" ];then
        echo "Asterisk is not up"
    else
        printf '%dd:%dh:%dm:%ds\n' $(($uptime/86400)) $(($uptime%86400/3600)) $(($uptime%3600/60)) $(($uptime%60))
    fi
}

function status.version(){
    version=`$ASTERISK -rx "core show version" |grep "Asterisk"|awk '{print$2}'`
    echo "$version"
}

function sip.trunk.down(){
    TRUNK=`$ASTERISK -rx "pjsip show endpoints" | grep UNREACHABLE | awk '{print$1}'| grep [A-Za-z]`
    if [ -n "$TRUNK" ]; then
        echo $TRUNK
    else
        echo "1"
    fi
}

function sip.peers(){
    TRUNK=`$ASTERISK -rx "pjsip show endpoints" | grep Contact | egrep -v "<MaxContact|<Hash" | wc -l`
    echo $TRUNK
}

### Execute the argument
$1