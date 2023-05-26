#!/bin/bash

target_directory="/pfad/zum/zielverzeichnis"

function download_file_a() {
    dialog --infobox "Lade File A herunter..." 5 40
    curl -s -o "$target_directory/file_a.txt" -f <URL zum File A>
    dialog --msgbox "Download von File A abgeschlossen." 7 40
}

function download_file_b() {
    dialog --infobox "Lade File B herunter..." 5 40
    curl -s -o "$target_directory/file_b.txt" -f <URL zum File B>
    dialog --msgbox "Download von File B abgeschlossen." 7 40
}

function download_file_c() {
    dialog --infobox "Lade File C herunter..." 5 40
    curl -s -o "$target_directory/file_c.txt" -f <URL zum File C>
    dialog --msgbox "Download von File C abgeschlossen." 7 40
}

function run_apt_upgrade() {
    dialog --infobox "Führe apt upgrade aus..." 5 40
    apt-get update &>/dev/null

    # Paketliste abrufen
    package_list=$(apt-get -s upgrade | awk '/^Inst/ { print $2 }')

    # Fortschrittsanzeige mit Paketnamen aktualisieren
    count=0
    for package in $package_list; do
        count=$((count+1))
        echo "$count"
        echo "XXX"
        echo "Aktualisiere Paket: $package"
        sleep 0.1
    done | dialog --title "APT Upgrade" --progressbox 20 70

    dialog --infobox "Führe apt autoremove aus..." 5 40
    apt-get autoremove -y &>/dev/null
    dialog --msgbox "apt upgrade und autoremove abgeschlossen." 7 40
}

while true; do
    choice=$(dialog --clear --backtitle "DATEI-DOWNLOADER" --title "Optionen" --menu "Bitte wählen Sie eine Option:" 14 60 5 \
        1 "File A herunterladen" \
        2 "File B herunterladen" \
        3 "File C herunterladen" \
        4 "APT Upgrade" \
        5 "Skript beenden" 2>&1 >/dev/tty)

    case $choice in
        1)
            download_file_a &
            ;;
        2)
            download_file_b &
            ;;
        3)
            download_file_c &
            ;;
        4)
            run_apt_upgrade &
            ;;
        5)
            dialog --infobox "Das Skript wird beendet." 5 40
            sleep 2
            clear
            exit 0
            ;;
        *)
            dialog --msgbox "Ungültige Option ausgewählt." 7 40
            ;;
    esac
done
