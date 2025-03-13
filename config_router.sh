#!/bin/bash

echo "Configurando red..."
cat <<EOF >> /etc/network/interfaces

auto    eth1
iface   eth1 inet static
   address      192.0.2.1
   network      192.0.2.0
   netmask      255.255.255.0
   broadcast    192.0.2.255

auto    eth2
iface   eth2 inet static
   address      175.25.0.1
   network      175.25.0.0
   netmask      255.255.0.0
   broadcast    175.25.0.255
EOF

cat <<EOF > /etc/network/interfaces.d/eth1

auto    eth1
iface   eth1 inet static
   address      192.0.2.1
   network      192.0.2.0
   netmask      255.255.255.0
   broadcast    192.0.2.255
EOF

cat <<EOF >> /etc/network/interfaces.d/eth2

auto    eth2
iface   eth2 inet static
   address      175.25.0.1
   network      175.25.0.0
   netmask      255.255.0.0
EOF

echo ""
echo "Status Interfaces"
cat /etc/network/interfaces
echo "*****************"
echo ""

echo "Iniciando Ifup"
ifup eth1
ifup eth2

