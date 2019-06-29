#!/usr/bin/env bash

[ "$#" -ne "3" ] && exit 1

rHost="127.0.0.1"
rPort="7666"

tf="$(tempfile)"

{ echo "$1"; sleep 10; } | ncat "$rHost" "$rPort" > "$tf"
#private key
< "$tf" sed -En -e '/###/ q;p' > "$2"
#public key
< "$tf" sed -En -e '/###/ bpri;bend' -e ':pri n;p;bpri' -e ':end' > "$3"

rm "$tf"
