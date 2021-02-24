#!/bin/bash

source_interface=$1
#source_interface="eth0"


destination_interface=$2
#destination_interface="tap0"

destination_gateway_ip=$3
#gateway_ip="10.8.0.1"

destination_ip=$4
#destination_ip="10.8.0.2"

protocol=$5
#protocol="tcp"

port1=$6
#port="8080"

port2=$7
#port="80"


if [[ "$#" -ne "7" ]]
then
echo "Неправильный синтаксис команды. Пример:"
echo "bash $0 eth0 tap0 10.8.0.1 10.8.0.2 tcp 8080 80"
echo "Где eth0 - интерфейс приема пакетов, tap0 - интерфейс передачи пакетов, 10.8.0.1 - шлюз интерфейса передачи пакетов, 10.8.0.2 - адрес сервера куда будут перенаправляться пакеты, tcp - протокол передачи данных (tcp | udp), 8080 - порт с которого будут перенаправляться пакеты, 80 - порт на который будут перенаправляться пакеты"
else

# Если входящий пакет пришёл извне на шлюз (eth0), но предназначен веб-серверу (порт 80), то адрес назначения подменяется на локальный адрес 10.8.0.2. И впоследствии маршрутизатор передаст пакет в виртуальную сеть.
iptables -t nat -A PREROUTING -i "$source_interface" -p "$protocol" --dport "$port1" -j DNAT --to-destination "$destination_ip":"$port2"

# Пропустить пакет, который пришёл на внешний интерфейс, уходит с внутреннего интерфейса и предназначен веб-серверу (10.8.0.2:80) локальной сети.
iptables -I FORWARD -i "$source_interface" -o "$destination_interface" -d "$destination_ip" -p "$protocol" -m "$protocol" --dport "$port2" -j ACCEPT

#Если пакет предназначен веб-серверу, то обратный адрес клиента заменяется на внутренний адрес шлюза. Этим мы гарантируем, что ответный пакет тоже пойдёт через шлюз.
iptables -t nat -A POSTROUTING --dst "$destination_ip" -p "$protocol" --dport "$port1" -j SNAT --to-source "$destination_gateway_ip"

#Логируем наши новосозданные правила перенаправления пакетов
iptables -t nat -I PREROUTING -i "$source_interface" -p "$protocol" --dport "$port1" -j LOG --log-prefix "[iptables: brige-$port-$protocol] "

echo "Перенаправление пакетов успешно настроено."
echo "$source_interface [:$port1] --> $destination_interface [$destination_ip:$port2]     {Protocol: $protocol, Gateway: $destination_gateway_ip}"
fi
