#!/bin/bash

clear

target_directory="/etc/update-motd.d"

while true; do
    /usr/bin/env figlet "MOTD Updater"
    echo ""
    echo "0. Combined MotD"
    echo "1. uname & sysinfo"
    echo "2. pihole"
    echo "3. docker"
    echo "8. Disable Last Logon Message"
    echo "9. Enable Last Logon Message"
    echo "t. Test motd"
    echo "e. Exit"
    echo ""
    read -p "Choose an option and press enter: " option

    case $option in
        0)
            echo "Lade File 0 herunter..."
            curl -s -o "/etc/profile.d/10-custom-motd.sh" -f https://raw.githubusercontent.com/MajorTomDE/motd-scripts/main/10-custom-motd.sh
            chmod +x "/etc/profile.d/10-custom-motd.sh"
            echo "Download von File 0 abgeschlossen."
            ;;
        
        
        1)
            echo "Lade File A herunter..."
            sudo apt install figlet
            curl -s -o "$target_directory/10-uname" -f https://raw.githubusercontent.com/MajorTomDE/motd-scripts/main/10-uname
            curl -s -o "$target_directory/20-sysinfo" -f https://raw.githubusercontent.com/MajorTomDE/motd-scripts/main/20-sysinfo
            chmod +x "$target_directory/10-uname"
            chmod +x "$target_directory/20-sysinfo"
            echo "Download von File A abgeschlossen."
            ;;
        2)
            echo "Lade File B herunter..."
            curl -s -o "$target_directory/40-pihole" -f https://raw.githubusercontent.com/MajorTomDE/motd-scripts/main/40-pihole
            chmod +x "$target_directory/40-pihole"
            echo "Download von File B abgeschlossen."
            ;;
        3)
            echo "Lade File C herunter..."
            curl -s -o "$target_directory/30-docker" -f https://raw.githubusercontent.com/MajorTomDE/motd-scripts/main/30-docker
            chmod +x "$target_directory/30-docker"
            echo "Download von File C abgeschlossen."
            ;;
        8)
            sudo sed -i 's/^#PrintLastLog yes/PrintLastLog no/' /etc/ssh/sshd_config
            sudo sed -i 's/^PrintLastLog yes/PrintLastLog no/' /etc/ssh/sshd_config
            service ssh restart
            ;; 
        9)
            sudo sed -i 's/^#PrintLastLog no/PrintLastLog yes/' /etc/ssh/sshd_config
            sudo sed -i 's/^PrintLastLog no/PrintLastLog yes/' /etc/ssh/sshd_config
            service ssh restart
            ;;

        t)
            clear
            sudo run-parts /etc/update-motd.d
            read -p "Press enter to continue"
            clear
            ;;
        e)
            echo "Das Skript wird beendet."
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac

    echo "------------------------------"
done
