#!/bin/bash

clear

target_directory="/etc/update-motd.d"

while true; do
    echo "Please choose your option:"
    echo "1. uname & sysinfo"
    echo "2. pihole"
    echo "3. docker"
    echo "4. Skript beenden"
    read -p "Choose option (1-4): " option

    case $option in
        1)
            echo "Lade File A herunter..."
            curl -o "$target_directory/10-uname" -f https://raw.githubusercontent.com/MajorTomDE/motd-scripts/main/10-uname
            curl -o "$target_directory/20-sysinfo" -f https://raw.githubusercontent.com/MajorTomDE/motd-scripts/main/20-sysinfo
            chmod +x "$target_directory/10-uname"
            chmod +x "$target_directory/20-sysinfo"
            echo "Download von File A abgeschlossen."
            ;;
        2)
            echo "Lade File B herunter..."
            curl -o "$target_directory/30-docker" -f https://raw.githubusercontent.com/MajorTomDE/motd-scripts/main/30-docker
            chmod +x "$target_directory/30-docker"
            echo "Download von File B abgeschlossen."
            ;;
        3)
            echo "Lade File C herunter..."
            curl -o "$target_directory/40-pihole" -f https://raw.githubusercontent.com/MajorTomDE/motd-scripts/main/40-docker
            chmod +x "$target_directory/40-docker"
            echo "Download von File C abgeschlossen."
            ;;
        4)
            echo "Das Skript wird beendet."
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac

    echo "------------------------------"
done
