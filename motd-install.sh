#!/bin/bash

clear

target_directory="/etc/update-motd.d"

while true; do
    echo "Bitte wählen Sie eine Option:"
    echo "1. File A herunterladen"
    echo "2. File B herunterladen"
    echo "3. File C herunterladen"
    echo "4. Skript beenden"
    read -p "Option auswählen (1-4): " option

    case $option in
        1)
            echo "Lade File A herunter..."
            wget -O "$target_directory/file_a.txt" <URL zum File A>
            echo "Download von File A abgeschlossen."
            ;;
        2)
            echo "Lade File B herunter..."
            wget -O "$target_directory/file_b.txt" <URL zum File B>
            echo "Download von File B abgeschlossen."
            ;;
        3)
            echo "Lade File C herunter..."
            wget -O "$target_directory/file_c.txt" <URL zum File C>
            echo "Download von File C abgeschlossen."
            ;;
        4)
            echo "Das Skript wird beendet."
            exit 0
            ;;
        *)
            echo "Ungültige Option ausgewählt."
            ;;
    esac

    echo "------------------------------"
done
