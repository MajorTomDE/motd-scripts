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
  # Farben
  green="\e[1;32m"
  red="\e[1;31m"
  undim="\e[0m"

  # Containername + Status sammeln
  mapfile -t names   < <(docker ps -a --format '{{.Names}}'   | sort -k1,1)
  mapfile -t status  < <(docker ps -a --format '{{.Status}}'  | sort -k1,1 | awk '{print $1}')

  count=${#names[@]}
  half=$(( (count + 1) / 2 ))   # bei ungerader Zahl eine Zeile mehr links

  printf "\nDocker status:\n"

  for ((i=0; i<half; i++)); do
      # linke Spalte
      n1="${names[i]}"
      s1="${status[i]}"
      if [[ "$s1" == "Up" ]]; then
          s1_col="${green}${s1,,}${undim}"
      else
          s1_col="${red}${s1,,}${undim}"
      fi

      # rechte Spalte (wenn vorhanden)
      idx2=$((i+half))
      if (( idx2 < count )); then
          n2="${names[idx2]}"
          s2="${status[idx2]}"
          if [[ "$s2" == "Up" ]]; then
              s2_col="${green}${s2,,}${undim}"
          else
              s2_col="${red}${s2,,}${undim}"
          fi
          printf "  %-20s %-12b   %-20s %-12b\n" "$n1" "$s1_col" "$n2" "$s2_col"
      else
          # falls keine rechte Spalte mehr
          printf "  %-20s %-12b\n" "$n1" "$s1_col"
      fi
  done

  echo
fi




# *** PIHOLE ****

if ! command -v pihole >/dev/null 2>&1; then
    exit 0
fi

# Farben
green="\e[1;32m"
red="\e[1;31m"
yellow="\e[1;33m"
undim="\e[0m"

# Status prüfen (Dienst aktiv?)
if systemctl is-active --quiet pihole-FTL; then
    status="${green}active${undim}"
else
    status="${red}inactive${undim}"
fi

# Update prüfen
# „pihole -up“ zeigt Updates an, aber wir wollen das non-interaktiv checken:
update_status=$(pihole -up --check 2>/dev/null)

if echo "$update_status" | grep -q "Everything is up to date"; then
    update="${green}up-to-date${undim}"
else
    update="${yellow}available${undim}"
fi

# Anzeige
echo
echo -e "📡 Pi-hole Status:   $status"
echo -e "⬆️  Update:          $update"
echo
