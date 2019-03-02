#!/bin/bash
###############################################################
# setup scripts:
# 	
#  - This feature originally built for MySQL 5.7
#  - create '.my.cnf' file on home directory
#    $ cat /etc/.my.cnf
#    [mysql]	
#    user=root
#    password=
#   	
###############################################################

comp_version='5.7.0'


if test -x /usr/bin/mysql 
then
	cur_version="$(/usr/bin/mysql --version | awk '{print $5}' | sed 's/,//')"
fi

echo $cur_version

for f in $(ls *.sql);
do
	echo "running $f"
	mysql -A --verbose --comments < $f | 2>/dev/null
done
