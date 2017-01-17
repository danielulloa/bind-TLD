#!/bin/bash
action=$1
tld=$2
db="db.$tld"
bind9='/etc/bind/named.conf.local'
cache='/var/cache/bind/'
server_ip=$(hostname -I | awk '{print $1}')
if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'delete' ]
	then
		echo $"This script creates DNS Zones binding custom Top Level Domains (.com .net .pwn) for your homelab. Usage: bindtld create  TLD"
		exit 1;
fi

if [ "$action" == 'create' ]
		then
				if [ -f $cache$db ]; then
					echo -e $"TLD $tld exists, nothing to do here..."
					exit;
				else
					echo $"Configuring Bind9..."
					echo "zone "$'\x22'"$tld"$'\x2E\x22'"{
		type master;
		file "$'\x22'"$db"$'\x22'";
};">>$bind9

					echo ""$'\x24'"TTL 604800
@ IN SOA $tld. admin.$tld. (
                2      ;serial
                604800           ;refresh
                86400           ;retry
                2419200         ;expire
                604800          ;negative cache TTL
                )
@       IN      NS      ns1.$tld.
@       IN      A       $server_ip
@       IN      MX      10      $tld.
ns1     IN      A       $server_ip" > $cache$db
echo $"Restarting Bind9"
/etc/init.d/bind9 restart
echo $"Checking if ns1 works"
nslookup ns1.$tld
echo -e $"Success! Your TLD is working. Now you can run virtualhosts script to create virutal hosts for Apache2"
exit;
fi
else
		if [ -f $cache$db ]; then
			echo $"Delete db"
			rm $cache$db
			echo  $"Deleting zone"
			sed -i "/\"$tld.\"/,/\};/d" $bind9
			echo  $"Restarting Bind9"
			/etc/init.d/bind9 restart
			exit 1;
		else
			echo -e $".$tld doesn't exist, nothing to do here..."
			exit 1;
		fi


fi
