## Autor: Raul Odria
## Fecha: 17/06/2013 - 06/17/2013

#!/bin/bash

echo 1 > /proc/sys/net/ipv4/ip_forward

FW="190.190.190.190"
GW="190.190.190.1"
SQL1="190.190.190.50"
SQL2="190.190.190.51"
S1="190.190.190.60"
S2="190.190.190.61"
PSQL1=2340
PSQL2=2341
PS1=1650
PS2=1651
IFACE0="eth0"
IFACE1="eth1"
NTP1="0.debian.pool.ntp.org"
NTP2="1.debian.pool.ntp.org"



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

# Acceso Ilimitado a la propias máquina 
#iptables -A INPUT -i $IFACE0 -s $FW -j ACCEPT
#iptables -A OUTPUT -o $IFACE0 -s $FW -j ACCEPT


#Permito entrada "SSH"
iptables -A INPUT -p tcp -m tcp -m multiport --dports 22 -j ACCEPT
iptables -A OUTPUT -p tcp -m tcp -m multiport --sports 22 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Permitimos que la maquina pueda salir a la web (Debian Install)
iptables -A INPUT -p tcp -m tcp --sport 80 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m tcp --dport 80 -j ACCEPT

# Y a https
iptables -A INPUT -p tcp -m tcp --sport 443 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT

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

# Permitimos consultas Servidor de tiempo NTP
iptables -A INPUT -s $NTP1,$NTP2 -i eth0 -p udp --dport 123 -j ACCEPT
iptables -A OUTPUT -d $NTP1,$NTP2 -p udp --sport 123 -j ACCEPT

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
iptables -A FORWARD -i $IFACE0 -p tcp --dport $PSQL1 -j ACCEPT
iptables -A FORWARD -i $IFACE0 -p tcp --dport $PSQL2 -j ACCEPT
iptables -A FORWARD -i $IFACE0 -p tcp --dport $PS1 -j ACCEPT
iptables -A FORWARD -i $IFACE0 -p tcp --dport $PS2 -j ACCEPT
#reply traffic
iptables -m state -A FORWARD -p tcp -m multiport --sports $PSQL1,$PSQL2,$PS1,$PS2 --state ESTABLISHED,RELATED -j ACCEPT


# LOG Iptables 
#iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7
iptables -A INPUT  -j LOG --log-prefix "iptables denied: " --log-level 7


## Servidor MAIL $FW
# Acceso a puerto 25, 110 y 143
#iptables -A INPUT -p tcp --dport 25 -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 25 -j ACCEPT

#iptables -A INPUT -p tcp --dport 110 -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 110 -j ACCEPT

#iptables -A INPUT -p tcp --dport 143 -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 143 -j ACCEPT
