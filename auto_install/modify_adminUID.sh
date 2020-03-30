#!/bin/bash
name=`id 1000|awk -F '(' '{print $2}'|awk -F ')' '{print $1}'`
echo $name
if [[ $name != "admin" ]]; then
	echo 111
	usermod  -u 1005 $name
	usermod  -u 1000 admin
	groupmod -g 1005 $name
	groupmod -g 1000 admin
	id admin
fi
	
