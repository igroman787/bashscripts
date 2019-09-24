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

port=$6
#port="800"

if [[ "$#" -ne "6" ]]
then
echo "Неправильный синтаксис команды. Пример:"
echo "iptables.addbgige eth0 tap0 10.8.0.1 10.8.0.2 tcp 800"
echo "Где eth0 - интерфейс приема пакетов, tap0 - интерфейс передачи пакетов, 10.8.0.1 - шлюз интерфейса передачи пакетов, 10.8.0.2 - адрес сервера куда будут перенаправляться пакеты, tcp - протокол передачи данных (tcp | udp), 800 - порт на который будут перенаправляться пакеты"
else

# Если входящий пакет пришёл извне на шлюз (eth0), но предназначен веб-серверу (порт 800), то адрес назначения подменяется на локальный адрес 10.8.0.2. И впоследствии маршрутизатор передаст пакет в виртуальную сеть.
iptables -t nat -A PREROUTING -i "$source_interface" -p "$protocol" --dport "$port" -j DNAT --to-destination "$destination_ip":"$port"

# Пропустить пакет, который пришёл на внешний интерфейс, уходит с внутреннего интерфейса и предназначен веб-серверу (10.8.0.2:800) локальной сети.
iptables -I FORWARD -i "$source_interface" -o "$destination_interface" -d "$destination_ip" -p "$protocol" -m "$protocol" --dport "$port" -j ACCEPT

#Если пакет предназначен веб-серверу, то обратный адрес клиента заменяется на внутренний адрес шлюза. Этим мы гарантируем, что ответный пакет тоже пойдёт через шлюз.
iptables -t nat -A POSTROUTING --dst "$destination_ip" -p "$protocol" --dport "$port" -j SNAT --to-source "$destination_gateway_ip"

#Логируем наши новосозданные правила перенаправления пакетов
iptables -t nat -I PREROUTING -i "$source_interface" -p "$protocol" --dport "$port" -j LOG --log-prefix "[iptables: brige-$port-$protocol] "

echo "Перенаправление пакетов успешно настроено."
echo "$source_interface --> $destination_interface [$destination_ip:$port]     {Protocol: $protocol, Gateway: $destination_gateway_ip}"
fi

