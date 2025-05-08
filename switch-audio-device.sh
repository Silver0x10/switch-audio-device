#!/bin/bash

sinks=($(pactl list sinks short | awk '{print $1}')) # get the list of audio output devices
active_sink=$(pactl list sinks short | grep -w "$(pactl info | grep 'Default Sink' | awk '{print $3}')" | awk '{print $1}') # get the index of the default sink

# create an array of available sinks (with available ports)
available_sinks=()
for sink in "${sinks[@]}"; do
    port_available=$(pactl list sinks | grep -A 100 "Sink #$sink" | grep -A 15 "Ports:" | grep -B 1 ", available\|availability unknown") # | grep -v "available")
    if [[ -n "$port_available" || "$sink" == "$active_sink" ]]; then
        available_sinks+=("$sink")
    fi
done

# find the index of the next device
current_index=-1
for i in "${!available_sinks[@]}"; do
    if [[ "${available_sinks[$i]}" == "$active_sink" ]]; then
        current_index=$i
        break
    fi
done
next_sink_index=$(( (current_index + 1) % ${#available_sinks[@]} ))
next_sink=${available_sinks[$next_sink_index]}

pactl set-default-sink $next_sink # Imposta il nuovo dispositivo come predefinito

notify-send "Audio device changed" "$(pactl list sinks | grep -A 10 "Sink #$next_sink" | grep Description | cut -d ' ' -f 2-)" # show a notification
