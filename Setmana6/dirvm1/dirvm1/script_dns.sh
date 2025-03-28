#!/bin/bash

sudo echo "dns" > /etc/hostname
hostname -F /etc/hostname
# Instalar BIND9

ifdown eth0; ifup eth0
ifdown eth1; ifup eth1


#Check if the package is installed
if ! dpkg -l | grep -q "ii  bind9 "; then                                            # If result is 0 then exist
	apt-get update
	apt-get install -y bind9
fi

#Check if the p>
if ! dpkg -l | grep -q "ii  bind9-utils "; then                                            # If result is >
        apt-get update
        apt-get install -y bind9-utils

fi

#1. Configurar /etc/resolv.conf
#cat <<EOF > /etc/resolv.conf
#nameserver 127.0.0.1
#search intranet.gsx dmz.gsx
#domain dmz.gsx
#EOF

cp /etc/bind/named* ./

# 2. Configurar named.conf.options
cat <<EOF > ./named.conf.options
options {
    directory "/var/lib/bind";
    forwarders {
        8.8.8.8;  # Servidor DNS de Google
    };
    allow-recursion {
        172.25.0.0/16;  # Intranet
        192.0.2.0/24;   # DMZ
    };
    allow-transfer {
        127.0.0.1;  # Solo permitir transferencias de zona desde localhost
    };
    dnssec-validation auto;

   listen-on-v6 { none; };
};
EOF


cat <<EOF > /etc/default/named
#
# run resolvconf?
RESOLVCONF=no

# startup options for the server
OPTIONS="-u bind -4"
EOF


# 3. Configurar named.conf.local
cat <<EOF > ./named.conf.local
zone "intranet.gsx" {
    type master;
    file "/etc/bind/db.intranet.gsx";
};

zone "dmz.gsx" {
    type master;
    file "/etc/bind/db.dmz.gsx";
};

zone "25.172.in-addr.arpa" {
    type master;
    file "/etc/bind/db.172.25";
};

zone "2.0.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.0.2";
};
EOF

# 4. Crear archivos de zona directa e inversa

# Zona directa para intranet.gsx
cat <<EOF > /etc/bind/db.intranet.gsx
\$TTL    604800
@       IN      SOA     ns.intranet.gsx. root.ns.intranet.gsx. (
                        202503012      ;Serial
                        604800         ; Refresh
                        86400          ; Retry
                        2419200        ; Expire
                        604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.intranet.gsx.
ns      IN      A       192.0.2.2
router  IN	A	172.25.0.1

; Listado de otros ordenadores
PC2     IN      A       172.25.0.2
PC3     IN      A       172.25.0.3
PC4	IN	A	172.25.0.4
PC5     IN      A       172.25.0.5
PC6     IN      A       172.25.0.6
PC7     IN      A       172.25.0.7
PC8     IN      A       172.25.0.8
PC9     IN      A       172.25.0.9
PC10    IN      A       172.25.0.10
PC11	IN	A	172.25.0.11
EOF

# Zona directa para dmz.gsx
cat <<EOF > /etc/bind/db.dmz.gsx
\$TTL    604800
@       IN      SOA     ns.dmz.gsx. root.ns.dmz.gsx. (
                        202503012      ; Serial
                        604800         ; Refresh
                        86400          ; Retry
                        2419200        ; Expire
                        604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.dmz.gsx.
ns      IN      A       192.0.2.2

; Listado de otros ordenadores
router  IN      A       192.0.2.1
dns	IN	A	192.0.2.2
www     IN      A       192.0.2.254
correu  IN      A       192.0.2.254
correu	IN      MX 10   correu.dmz.gsx.
server  IN      CNAME   www.
EOF

# Zona inversa para 172.25.0.0/16
cat <<EOF > /etc/bind/db.172.25
\$TTL    604800
@       IN      SOA     ns.intranet.gsx. admin.intranet.gsx. (
                        202503012      ; Serial
                        604800         ; Refresh
                        86400          ; Retry
                        2419200        ; Expire
                        604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.intranet.gsx.
ns	IN	PTR	ns.intranet.gsx.
1.0    	IN      PTR     router.intranet.gsx.
2.0    	IN      PTR     PC2.intranet.gsx.
3.0    	IN      PTR     PC3.intranet.gsx.
4.0    	IN      PTR     PC4.intranet.gsx.
5.0    	IN      PTR     PC5.intranet.gsx.
6.0    	IN      PTR     PC6.intranet.gsx.
7.0    	IN      PTR     PC7.intranet.gsx.
8.0   	IN      PTR     PC8.intranet.gsx.
9.0	IN      PTR     PC9.intranet.gsx.
10.0	IN      PTR     PC10.intranet.gsx.
11.0	IN      PTR     PC11.intranet.gsx.
EOF

# Zona inversa para 192.0.2.0/24
cat <<EOF > /etc/bind/db.192.0.2
\$TTL    604800
@       IN      SOA     ns.dmz.gsx. admin.dmz.gsx. (
                        2023101001      ; Serial
                        604800         ; Refresh
                        86400          ; Retry
                        2419200        ; Expire
                        604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.dmz.gsx.
ns 	IN 	PTR	ns.dmz.gsx.
1       IN      PTR     router.dmz.gsx.
2 	IN      PTR     dns.dmz.gsx.
254     IN      PTR     www.dmz.gsx.
EOF
cp ./named* /etc/bind/
chmod 644 /etc/bind/*

# 5. Verificar la sintaxis de los archivos de configuración
/usr/bin/named-checkconf -z /etc/bind/named.conf.local

/usr/bin/named-checkzone intranet.gsx /etc/bind/db.intranet.gsx
/usr/bin/named-checkzone dmz.gsx /etc/bind/db.dmz.gsx
/usr/bin/named-checkzone 25.172.in-addr.arpa /etc/bind/db.172.25
/usr/bin/named-checkzone 2.0.192.in-addr.arpa /etc/bind/db.192.0.2
# 6. Reiniciar BIND9
systemctl restart bind9

# 7. Verificar logs
#journalctl -u bind9 -e
