#!/bin/bash

set -o nounset
set -o pipefail

sec2time () {
  local input=${1:-0}
  if (( input < 60 )); then
    echo "${input} seconds"
  else
    local days=$(( input/86400 ))
    input=$(( input%86400 ))
    local hours=$(( input/3600 ))
    input=$(( input%3600 ))
    local mins=$(( input/60 ))

    local dS="s" hS="s" mS="s"
    (( days == 1 )) && dS=""
    (( hours == 1 )) && hS=""
    (( mins == 1 )) && mS=""

    echo "${days} day${dS}, ${hours} hour${hS}, ${mins} minute${mS}"
  fi
}




# Distro
if [ -r /etc/os-release ]; then
  distro="$(. /etc/os-release; echo "${PRETTY_NAME}")"
else
  distro="$(uname -s)"
fi

kernel="$(uname -sr)"

# Updates: schneller, ohne Locks, mit Timeout
# Hinweis: Zählt nur Zeilen die mit "Inst " beginnen (simuliertes Upgrade)
updates="$(
  timeout 3s apt-get -o Debug::NoLocking=1 -q -s upgrade 2>/dev/null | grep -c '^Inst '
)"

hostnametxt="$(hostname)"

# Öffentliche IP (mit Timeout & Fallback-Text)
hostnameext="$(curl -s --max-time 2 ifconfig.me || true)"
[ -z "$hostnameext" ] && hostnameext="(no external IP)"

# Uptime + Boot-Time
uptime="$(sec2time "$(cut -d '.' -f 1 /proc/uptime)")"
boottime="$(date -d "@$(grep btime /proc/stat | awk '{print $2}')" +"%d-%m-%Y %H:%M:%S")"
uptime="${uptime} (${boottime})"

W="\e[0;39m"
G="\e[1;32m"




# Ausgabe
uname -snrvm
/usr/bin/env figlet "$(hostname)"
echo -e "
Server
  Distro...........: ${distro}
  Kernel...........: ${kernel}
  Hostname.........: ${hostnametxt} | ${hostnameext}
  Uptime...........: ${uptime}
  Updates..........: ${G}${updates}${W}
"
if [ -f /var/run/reboot-required ]; then
  echo "*** System restart required ***"
fi


# *** DOCKER ***

if command -v docker >/dev/null 2>&1; then
  # eigene Spalten-Anzahl, nicht COLUMNS!
  COLS=2
  # colors
  green="\e[1;32m"
  red="\e[1;31m"
  undim="\e[0m"

  mapfile -t containers < <(docker ps -a --format '{{.Names}}\t{{.Status}}' \
    | sort -k1,1 | awk '{ print $1,$2 }')

  out=""
  for i in "${!containers[@]}"; do
    IFS=' ' read -r name status <<< "${containers[i]}"
    if [[ "$status" == "Up" ]]; then
      out+="${name},${green}${status,,}${undim},"
    else
      out+="${name},${red}${status,,}${undim},"
    fi
    if (( ((i+1) % COLS) == 0 )); then
      out+="\n"
    fi
  done
  out+="\n"

  printf "\nDocker status:\n"
  #printf "%b" "$out" | awk -F, '{printf "  %-25s %-12s\n",$1,$2}'
  printf "\n"
fi



# *** PIHOLE ****

if which pihole >/dev/null; then
  
  echo "Pi-hole status:"
  echo ""
  pihole -v
  printf "\n"
  pihole status
  printf "\n"

fi
