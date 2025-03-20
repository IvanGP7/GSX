#!/bin/sh

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 2025-1.0

# Descripció:
# Comprova la configuració actual i la guarda a un fitxer .tar
# Aquest fitxer l'adjuntareu al moodle
# per a comprovar si ho heu començat a fet bé
# i no arrossegar problemes a les properes sessions.

# Execució:
# Al final, a la vm0, quan ja us funcionin els scripts.

# Important:
############
# no modifiqueu aquest script ni els seus resultats,

out="./sortida_vm0_labx1.txt"

# comprovar les interfícies de vm0
ip link > $out
ifquery eth0 >> $out
ifquery --state eth0 >> $out
ifquery eth1 >> $out
ifquery eth2 >> $out
echo >> $out

# comprovar el forwarding
sysctl net.ipv4.ip_forward >> $out
echo >> $out

# comprovar les regles SNAT
iptables-save | grep POSTROUTING | grep -o "\-s [^ ]\+ " | cut -f2 -d' ' >> $out
echo >> $out
# comprovar l'estat del dnsmasq
systemctl is-active dnsmasq >> $out
systemctl --no-pager status dnsmasq | grep "IP range" >> $out
ss -4lntup | grep dnsmasq >> $out
echo >> $out

# resol els noms?
host -W1 vm1 >> $out 2>&1
host -W1 vm2 >> $out 2>&1
host -W1 vm3 >> $out 2>&1
dig +timeout=1 +short urv.cat @127.0.0.1 >> $out
echo >> $out

# comprovar connectivitat
dgw=$(ip route | grep default | cut -f3 -d' ')
ping -W1 -c3 $dgw >> $out 2>&1
echo >>$out
ping -W1 -c3 vm1 >> $out 2>&1
echo >>$out
ping -W1 -c3 vm2 >> $out 2>&1
echo >>$out
ping -W1 -c1 1.1.1.1 >> $out 2>&1
echo >>$out

# comprovar continguts i permisos
cat /etc/resolv.conf  >> $out
grep gsx /etc/hosts >> $out
ls -l /etc/resolv.conf /etc/hosts /etc/dnsmasq.conf >> $out
echo >> $out

# generar el fitxer per a pujar al moodle
tar -cf $out.tar $out

