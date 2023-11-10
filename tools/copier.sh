#!/bin/bash
# by DSR! from https://github.com/xchwarze/wifi-pineapple-cloner

FILE_LIST="$1"
FROM_FOLDER="$2"
TO_FOLDER="$3"
COUNTER=0
if [[ ! -f "$FILE_LIST" || ! -d "$FROM_FOLDER" || "$TO_FOLDER" == "" ]]; then
    echo "Run with \"copier.sh [FILE_LIST] [FROM_FOLDER] [TO_FOLDER]\""
    echo "    FILE_LIST   -> flavor file list"
    echo "    FROM_FOLDER -> path to base fs"
    echo "    TO_FOLDER   -> path to new fs"

    exit 1
fi



FILE_LIST="$(realpath $FILE_LIST)"
FROM_FOLDER="$(realpath $FROM_FOLDER)"
TO_FOLDER="$(realpath $TO_FOLDER)"

echo "Filelist2Copy - by DSR!"
echo "******************************"
echo ""

echo "[*] Start copy loop"
rm -rf "$TO_FOLDER"
mkdir "$TO_FOLDER"

for FILE in $(cat "$FILE_LIST")
do
    if [[ "${FILE:0:1}" != '/' ]]; then
        continue
    fi
    
    # fix name chars
    FILE=$(echo $FILE | sed $'s/\r//')

    # check exist
    if [[ ! -f "$FROM_FOLDER$FILE" ]] && [[ ! -d "$FROM_FOLDER$FILE" ]]; then
        echo "[!] File does not exist: ${FROM_FOLDER}${FILE}"
        continue
    fi

    # check file type
    #TYPE_CHECK=$(file "$FROM_FOLDER$FILE" | grep "ELF")
    #if [[ $TYPE_CHECK != "" ]]; then
    #    echo "[+] ELF: $FILE"
    #    continue
    #fi

    let COUNTER++

    FOLDER=$(dirname $FILE)
    mkdir -p "$TO_FOLDER$FOLDER"

    # if folder...
    if [[ -d "$FROM_FOLDER$FILE" ]]; then
        cp -R "$FROM_FOLDER$FILE" "$TO_FOLDER$FILE"
    else
        cp -P "$FROM_FOLDER$FILE" "$TO_FOLDER$FILE"
    fi
done

if [ $COUNTER -eq 0 ]; then
    echo "[!] No files were copied. Verify that the paths are correct."
    exit 1
fi

echo "[+] Files copied: $COUNTER"
echo ""
