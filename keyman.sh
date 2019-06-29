#!/usr/bin/env bash
set -e

home_path="/opt/keyman"

SQLITE=/usr/bin/sqlite
DB="$home_path/keys.db"

if [ ! -e "$SQLITE" ]; then 
	echo "SQLITE does not exist!" >&2
	exit 1
fi


function init_db(){
	$SQLITE -init "$home_path/sql/init_db.sql" $DB ".exit" >/dev/null 2>&1
}

function insert_key(){
	$SQLITE $DB "INSERT INTO ssh_key VALUES('${1//\'/\'\'}','${2//\'/\'\'}','${3//\'/\'\'}');" >/dev/null 2>&1
	
}

function search_key(){
	$SQLITE $DB "SELECT private_key FROM ssh_key WHERE mac LIKE '${1//\'/\'\'}'"
	echo "###"
	$SQLITE $DB "SELECT public_key FROM ssh_key WHERE mac LIKE '${1//\'/\'\'}'"
}

function delete_key(){
	$SQLITE $DB "delete FROM ssh_key WHERE mac LIKE '${1//\'/\'\'}'" >/dev/null 2>&1
}

function valid_mac(){
	grep -Eqi '^([a-f0-9]{2}:){5}[a-f0-9]{2}$' <<<"$1"	
}

function gen_key(){
	local tf="$(tempfile)"	
	rm "$tf"
	ssh-keygen -b2048 -f "$tf" -P "" -C "" >/dev/null 2>&1
	insert_key "$1" "$(cat "$tf")" "$(cat "$tf.pub")"
	cat "$tf"
	echo "###"
	cat "${tf}.pub"
	rm ${tf}*
}

function sleep_read(){
	timeout 2s head -n1 
}

[ ! -e "$DB" ] && init_db

line="$(sleep_read)"
[ -z "$line" ] && exit 0

if valid_mac "$line"; then
	search_res="$(search_key "$line")"
	
	[ "$search_res" != "###" ] && echo "$search_res" || gen_key "$line"
fi
