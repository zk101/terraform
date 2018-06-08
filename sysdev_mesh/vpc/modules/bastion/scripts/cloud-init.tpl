#!/bin/bash

# Sysctl (ip_forward)
echo "net.ipv4.ip_forward = 1" >> /usr/lib/sysctl.d/50-default.conf
sysctl -w net.ipv4.ip_forward=1

# Yum
yum -y install epel-release
yum -y install tinc python-pip
yum -y update

# Install awscli - The CentOS native version currently has bugs
pip install awscli==1.15.19

# Tinc
if [[ -d "/etc/tinc" ]]; then
	rm -Rf /etc/tinc
fi
mkdir -p /etc/tinc/sysdev-mesh/hosts

cat << EOF > /etc/tinc/sysdev-mesh/hosts/${region}
Address = ${external_ip}
Subnet = 192.168.0.${mesh_ip_octet}/32
Subnet = ${vpc_supernet}
EOF

cat << EOF > /etc/tinc/sysdev-mesh/tinc-up
#!/bin/sh

ip link set \$INTERFACE up
ip addr add 192.168.0.${mesh_ip_octet}/32 dev \$INTERFACE
ip route add 192.168.0.0/24 dev \$INTERFACE
EOF

cat << EOF > /etc/tinc/sysdev-mesh/tinc-down
#!/bin/sh

ip route del 192.168.0.0/24 dev \$INTERFACE
ip addr del 192.168.0.${mesh_ip_octet}/32 dev \$INTERFACE
ip link set \$INTERFACE down
EOF

chmod +x /etc/tinc/sysdev-mesh/tinc-*

cat << EOF > /etc/tinc/sysdev-mesh/subnet-up
#!/bin/sh

if [[ "\$SUBNET" =~ ^192 ]]; then
	exit 0
fi

if [[ "\$SUBNET" == "${vpc_supernet}" ]]; then
	exit 0
fi

ip route add \$SUBNET dev \$INTERFACE
EOF

cat << EOF > /etc/tinc/sysdev-mesh/subnet-down
#!/bin/sh

if [[ "\$SUBNET" =~ ^192 ]]; then
	exit 0
fi

if [[ "\$SUBNET" == "${vpc_supernet}" ]]; then
	exit 0
fi

ip route del \$SUBNET dev \$INTERFACE
EOF

chmod +x /etc/tinc/sysdev-mesh/subnet-*

cat << EOF > /etc/tinc/sysdev-mesh/tinc.conf
Name = ${region}
AddressFamily = ipv4
Interface = tun0
EOF

cp -a /etc/tinc/sysdev-mesh/tinc.conf /etc/tinc/sysdev-mesh/tinc.conf.base

echo -e "\n" | tincd -n sysdev-mesh -K4096

systemctl enable tinc
systemctl enable tinc@sysdev-mesh
systemctl start tinc@sysdev-mesh

aws s3 cp /etc/tinc/sysdev-mesh/hosts/${region} s3://tinc-hosts-sysdev-mesh/

cat << EOF > /usr/local/bin/tinc_hosts.sh
#!/bin/bash

FORCE_RESTART=0
MYHOST=\$(cat /etc/tinc/sysdev-mesh/tinc.conf | grep ^Name | awk '{print \$3}')

mkdir -p /etc/tinc/sysdev-mesh/hosts.bak

cp -a /etc/tinc/sysdev-mesh/tinc.conf /etc/tinc/sysdev-mesh/tinc.conf.bak
cp -a /etc/tinc/sysdev-mesh/tinc.conf.base /etc/tinc/sysdev-mesh/tinc.conf

IFS=\$'\n'
for HOST_LIST in \$(aws s3 ls s3://tinc-hosts-sysdev-mesh); do
	HOST=\$(echo \$HOST_LIST | awk '{print \$4}')
	if [[ "\$MYHOST" == "\$HOST" ]]; then
		continue
	fi

	if [[ -f "/etc/tinc/sysdev-mesh/hosts/\$HOST" ]]; then
		cp -a /etc/tinc/sysdev-mesh/hosts/\$HOST /etc/tinc/sysdev-mesh/hosts.bak/\$HOST
	fi

	aws s3 cp s3://tinc-hosts-sysdev-mesh/\$HOST /etc/tinc/sysdev-mesh/hosts/
	echo "ConnectTo = \$HOST" >> /etc/tinc/sysdev-mesh/tinc.conf

	if [[ -f "/etc/tinc/sysdev-mesh/hosts.bak/\$HOST" ]]; then
		diff /etc/tinc/sysdev-mesh/hosts/\$HOST /etc/tinc/sysdev-mesh/hosts.bak/\$HOST
		if [[ \$? != 0 ]]; then
			FORCE_RESTART=1
		fi
	fi
done

diff /etc/tinc/sysdev-mesh/tinc.conf /etc/tinc/sysdev-mesh/tinc.conf.bak
if [[ \$FORCE_RESTART == 1 || \$? != 0 ]]; then
	systemctl reload tinc@sysdev-mesh
fi
EOF

chmod +x /usr/local/bin/tinc_hosts.sh

cat << EOF > /etc/cron.d/tinc_hosts
# Check for new Tinc hosts
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
* * * * *	root	/usr/local/bin/tinc_hosts.sh >/dev/null 2>&1
EOF

sync; sync; sync

shutdown -r now
