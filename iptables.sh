#!/bin/bash

echo 1 > /proc/sys/net/ipv4/ip_forward

FW=198.178.126.190
GW=198.178.126.191
SQL1=199.167.149.62
SQL2=198.178.125.100
S1=96.31.73.229
S2=50.62.42.189
PSQL1=2340
PSQL2=18735
PS1=1650
PS2=16432

NTP1=
IFACE0=eth0
IFACE1=eth1

## FLUSH de reglas
iptables -F
iptables -X
iptables -Z
iptables -t nat -F

## Establecer política por defecto: DROP
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# Operar en localhost sin limitaciones
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#Permito entrada "SSH"
iptables -A INPUT -p tcp -m tcp -m multiport --dports 443,62222 -j ACCEPT
iptables -A OUTPUT -p tcp -m tcp -m multiport --sports 443,62222 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Permitimos que la maquina pueda salir a la web (Debian Install)
/sbin/iptables -A INPUT -p tcp -m tcp --sport 80 -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A OUTPUT -p tcp -m tcp --dport 80 -j ACCEPT

# Y a https
/sbin/iptables -A INPUT -p tcp -m tcp --sport 443 -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT

# Acepto paquetes de conexiones ya establecidas
iptables -A INPUT -p TCP -m state --state RELATED -j ACCEPT

# Dejo pasar los paquetes ICMP (Por Ahora)
iptables -A INPUT -i $IFACE0 -p ICMP -j ACCEPT
iptables -A OUTPUT -p ICMP -j ACCEPT

# Permitimos la consulta a un primer DNS
iptables -A INPUT -s 208.67.222.222 -p udp -m udp --sport 53 -j ACCEPT
iptables -A OUTPUT -d 208.67.222.222 -p udp -m udp --dport 53 -j ACCEPT

# Permitimos la consulta a un segundo DNS
iptables -A INPUT -s 208.67.220.220 -p udp -m udp --sport 53 -j ACCEPT
iptables -A OUTPUT -d 208.67.220.220 -p udp -m udp --dport 53 -j ACCEPT


# Magia Public to Public
iptables -A INPUT -p tcp -m tcp -d $FW --dport $PSQL1 -j ACCEPT
iptables -A OUTPUT -p tcp -m tcp --sport $PSQL1 -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -A INPUT -p tcp -m tcp -d $FW --dport $PSQL2 -j ACCEPT
iptables -A OUTPUT -p tcp -m tcp --sport $PSQL2 -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -A INPUT -p tcp -m tcp -d $FW --dport $PS1 -j ACCEPT
iptables -A OUTPUT -p tcp -m tcp --sport $PS1 -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -A INPUT -p tcp -m tcp -d $FW --dport $PS2 -j ACCEPT
iptables -A OUTPUT -p tcp -m tcp --sport $PS2 -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -t nat -A PREROUTING -p tcp -d $FW --dport $PSQL1 -j DNAT --to-destination $SQL1
iptables -t nat -A POSTROUTING -d $SQL1 -p tcp --dport $PSQL1 -j SNAT --to-source $FW

iptables -t nat -A PREROUTING -p tcp -d $FW --dport $PSQL2 -j DNAT --to-destination $SQL2
iptables -t nat -A POSTROUTING -d $SQL2 -p tcp --dport $PSQL2 -j SNAT --to-source $FW

iptables -t nat -A PREROUTING -p tcp -d $FW --dport $PS1 -j DNAT --to-destination $S1
iptables -t nat -A POSTROUTING -d $S1 -p tcp --dport $PS1 -j SNAT --to-source $FW

iptables -t nat -A PREROUTING -p tcp -d $FW --dport $PS2 -j DNAT --to-destination $S2
iptables -t nat -A POSTROUTING -d $S2 -p tcp --dport $PS2 -j SNAT --to-source $FW

#forward traffic
iptables -A FORWARD -i $IFACE0 -p tcp -m multiport --dports $PSQL1,$PSQL2,$PS1,$PS2 -j ACCEPT
#reply traffic
iptables -m state -A FORWARD -p tcp -m multiport --sports $PSQL1,$PSQL2,$PS1,$PS2 --state ESTABLISHED,RELATED -j ACCEPT
