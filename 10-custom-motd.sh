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

# Kernel Version
kernel="$(uname -sr)"

# Hostname
hostnametxt="$(hostname)"

# Public IP (with Timeout & Fallback-Text)
hostnameext="$(curl -s --max-time 2 ifconfig.me || true)"
[ -z "$hostnameext" ] && hostnameext="(no external IP)"

# Uptime + Boot-Time
uptime="$(sec2time "$(cut -d '.' -f 1 /proc/uptime)")"
boottime="$(date -d "@$(grep btime /proc/stat | awk '{print $2}')" +"%d-%m-%Y %H:%M:%S")"

W="\e[0;39m"
G="\e[1;32m"




# Ausgabe
/usr/bin/env figlet "$(hostname)"
echo -e "
Server
  Distro...........: ${distro}
  Kernel...........: ${kernel}
  Hostname.........: ${hostnametxt}
  Public IP........: ${hostnameext}
  Uptime...........: ${uptime} (${boottime})
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
\n
  count=${#names[@]}
  half=$(( (count + 1) / 2 ))   # bei ungerader Zahl eine Zeile mehr links

  printf "\nDocker Status\n"

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




# *** Pi-Hole Status ****

if command -v pihole >/dev/null 2>&1; then

# Farben
green="\e[1;32m"; red="\e[1;31m"; yellow="\e[1;33m"; reset="\e[0m"

# --- Status (FTL / Blocking) ---
status_out=$(LC_ALL=C timeout 2s pihole status 2>/dev/null)

# FTL aktiv, wenn "FTL is listening on port 53" vorkommt
if printf '%s\n' "$status_out" | grep -q "FTL is listening on port 53"; then
  svc="${green}active${reset}"
else
  svc="${red}inactive${reset}"
fi

# Blocking enabled/disabled auslesen (genaue Textteile)
if printf '%s\n' "$status_out" | grep -q "Pi-hole blocking is enabled"; then
  block="enabled"
elif printf '%s\n' "$status_out" | grep -q "Pi-hole blocking is disabled"; then
  block="disabled"
else
  block="unknown"
fi

# --- Update-Check via `pihole -v` (ohne Netz-Fetch) ---
ver_out=$(LC_ALL=C timeout 4s pihole -v 2>/dev/null)

upd_state="unknown"
if [[ -n "$ver_out" ]]; then
  # „Latest:“ wird pro Zeile eingeblendet, wenn Vergleich möglich ist
  need_update=0
  while IFS= read -r line; do
    inst=$(printf '%s' "$line" | sed -n 's/.* is \([^ ]*\).*/\1/p')
    last=$(printf '%s' "$line" | sed -n 's/.*Latest: \([^)]*\)).*/\1/p')
    if [[ -n "$last" && -n "$inst" && "$last" != "$inst" ]]; then
      need_update=1; break
    fi
  done <<< "$ver_out"
  if (( need_update )); then
    upd_state="available"
  else
    # wenn Latest vorhanden und überall gleich, dann up-to-date
    if printf '%s' "$ver_out" | grep -q "Latest:"; then
      upd_state="up-to-date"
    fi
  fi
fi

case "$upd_state" in
  up-to-date) upd="${green}up-to-date${reset}" ;;
  available)  upd="${yellow}available${reset}" ;;
  *)          upd="${yellow}unknown${reset}" ;;
esac

# --- Ausgabe ---
printf "\nPi-hole Status\n"
printf "  Service:             %b (blocking: %s)\n" "$svc" "$block"
printf "  Update:              %b\n\n" "$upd"

fi
