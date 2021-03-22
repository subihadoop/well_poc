#!/bin/bash

#
# Script to create MySQL db + user
#

################################################################################
# CORE FUNCTIONS - Do not edit (Utility)
################################################################################
#
# VARIABLES
#
_bold=$(tput bold)
_underline=$(tput sgr 0 1)
_reset=$(tput sgr0)

_purple=$(tput setaf 171)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_tan=$(tput setaf 3)
_blue=$(tput setaf 38)

#
# HEADERS & LOGGING
#
function _debug()
{
    [ "$DEBUG" -eq 1 ] && $@
}

function _header()
{
    printf "\n${_bold}${_purple}==========  %s  ==========${_reset}\n" "$@"
}

function _arrow()
{
    printf "➜ $@\n"
}

function _success()
{
    printf "${_green}✔ %s${_reset}\n" "$@"
}

function _error() {
    printf "${_red}✖ %s${_reset}\n" "$@"
}

function _warning()
{
    printf "${_tan}➜ %s${_reset}\n" "$@"
}

function _underline()
{
    printf "${_underline}${_bold}%s${_reset}\n" "$@"
}

function _bold()
{
    printf "${_bold}%s${_reset}\n" "$@"
}

function _note()
{
    printf "${_underline}${_bold}${_blue}Note:${_reset}  ${_blue}%s${_reset}\n" "$@"
}

function _die()
{
    _error "$@"
    exit 1
}

function _safeExit()
{
    exit 0
}

#
# UTILITY HELPER
#
function _seekConfirmation()
{
  printf "\n${_bold}$@${_reset}"
  read -p " (y/n) " -n 1
  printf "\n"
}

# Test whether the result of an 'ask' is a confirmation
function _isConfirmed()
{
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}


function _typeExists()
{
    if [ $(type -P $1) ]; then
        return 0
    fi
    return 1
}

function _isOs()
{
    if [[ "${OSTYPE}" == $1* ]]; then
      return 0
    fi
    return 1
}

function _checkRootUser()
{
    #if [ "$(id -u)" != "0" ]; then
    if [ "$(whoami)" != 'root' ]; then
        echo "You have no permission to run $0 as non-root user. Use sudo"
        exit 1;
    fi

}

function _printPoweredBy()
{
    cat <<"EOF"
Powered By:
   __  ___              
  CDF Team

################################################################
EOF
}
################################################################################
# SCRIPT FUNCTIONS
################################################################################
function generatePassword()
{
    echo "$(openssl rand -base64 12)"
}

function _printUsage()
{
    echo -n "$(basename $0) [OPTION]...
Create MySQL db & user.
Version $VERSION
    Options:
        -h, --host        MySQL Host
        -d, --database    MySQL Database
        -u, --user        MySQL User
        -p, --pass        MySQL Password (If empty, auto-generated)
        -h, --help        Display this help and exit
        -v, --version     Output version information and exit
    Examples:
        $(basename $0) --help
        $(basename $0) [--host="localhost"] --database="anemp" [--user="root"] [--pass="Monu@1234"]
"
    _printPoweredBy
    exit 1
}

function processArgs()
{
    # Parse Arguments
    for arg in "$@"
    do
        case $arg in
            -h=*|--host=*)
                DB_HOST="${arg#*=}"
            ;;
            -d=*|--database=*)
                DB_NAME="${arg#*=}"
            ;;
            -u=*|--user=*)
                DB_USER="${arg#*=}"
            ;;
             -p=*|--pass=*)
                DB_PASS="${arg#*=}"
            ;;
            --debug)
                DEBUG=1
            ;;
            -h|--help)
                _printUsage
            ;;
            *)
                _printUsage
            ;;
        esac
    done
    [[ -z $DB_NAME ]] && _error "Database name cannot be empty." && exit 1
    [[ $DB_USER ]] || DB_USER=$DB_NAME
}

################################################################################
# Business Logics
################################################################################

function createMysqlDbUser()
{
    SQL1="CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
    SQL2="CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';"
    SQL3="GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';"
    SQL5="FLUSH PRIVILEGES;"

    if [ -f /root/.my.cnf ]; then
        "$BIN_MYSQL" -e "${SQL1}${SQL2}${SQL3}${SQL4}"
    else
        # If /root/.my.cnf doesn't exist then it'll ask for root password
        _arrow "Please enter root user MySQL password!"
        read rootPassword
        "$BIN_MYSQL" -h $DB_HOST -u root -p${rootPassword} -e "${SQL1}${SQL2}${SQL3}${SQL4}"
        echo $SQL4
    fi
}

function selectMysqlDbUser()


{
    SQL1="use anemp;"
    SQL2="select email from users;"
    
    if [ -f /root/.my.cnf ]; then
        "$BIN_MYSQL" -e "${SQL1}"
    else
        # If /root/.my.cnf doesn't exist then it'll ask for root password
        _arrow "Please enter root user MySQL password!"
        read rootPassword
        data=$("$BIN_MYSQL" -h $DB_HOST -u root -p${rootPassword} -e "${SQL1}${SQL2}")
       
        
    fi
    
}

# Define an array.
declare -a cmd
 
# Assign elements to an array.
cmd[0]="first.sql"
cmd[1]="second.sql"
cmd[2]="third.sql"
 
# Call the array elements.
for i in ${cmd[*]}; do
  mysql -s -u${username} -p${password} -D${database} < ${directory}/${i} > /dev/null 2>/dev/null
done
 
# Connect and pipe the query result minus errors and warnings to the while loop.
mysql -u${username} -p${password} -D${database} <<<'show tables' 2>/dev/null |
 
# Read through the piped result until it's empty but format the title.
while IFS='\n' read list; do
  if [[ ${list} = "Tables_in_sampledb" ]]; then
    echo $list
    echo "----------------------------------------"
  else
    echo $list
  fi
done
echo ""
 
# Connect and pipe the query result minus errors and warnings to the while loop.
mysql -u${username} -p${password} -D${database} <<<'SELECT CONCAT(a.actor_name," in ",f.film_name) AS "Actors in Films" FROM actor a INNER JOIN movie m ON a.actor_id = m.actor_id INNER JOIN film f ON m.film_id = f.film_id' 2>/dev/null |
 
 #IFS (Internal Field Separator) works with whitespace by default.
# Read through the piped result until it's empty but format the title.
while IFS='\n' read actor_name; do
  if [[ ${actor_name} = "Actors in Films" ]]; then
    echo $actor_name
    echo "----------------------------------------"
  else
    echo $actor_name
  fi
done
################################################################################
# Console Display
################################################################################

function printSuccessMessage()
{
    _success "MySQL DB / User creation completed!"

    echo "################################################################"
    echo ""
    echo " >> Host      : ${DB_HOST}"
    echo " >> Database  : ${DB_NAME}"
    echo " >> User      : ${DB_USER}"
    echo " >> Pass      : ${DB_PASS}"
    data1=$(echo $data )
    echo $data1
    data2=$(echo $data | awk '{print $2}')
    echo $data2
     data2=$(echo $data | awk '{print $2}')
     
     while IFS='\n' read data2; do
    if [[ ${actor_name} = "email" ]]; then
    echo $actor_name
    echo "----------------------------------------"
  else
    echo $actor_name
  fi
done
     if [$data2 == 'jv@gmail.com']; then
     echo "We got the data"
     else 
     echo "we have to fetch the data"
     fi
    echo ""
    echo "################################################################"
    _printPoweredBy

}




################################################################################
# Main
################################################################################
export LC_CTYPE=C
export LANG=C

DEBUG=0 # 1|0
_debug set -x
VERSION="0.1.0"

BIN_MYSQL=$(which mysql)

DB_HOST='localhost'
DB_NAME=
DB_USER=
DB_PASS=$(generatePassword)

function main()
{
    [[ $# -lt 1 ]] && _printUsage
    _success "Processing arguments..."
    processArgs "$@"
    _success "Done!"

    _success "Creating MySQL db and user..."
    
    selectMysqlDbUser
    _success "Done!"

    printSuccessMessage

    exit 0
}

main "$@"

_debug set +x

"***

#!/usr/bin/bash
 
# Assign user and password
username="${1}"
password="${2}"
database="${3}"
directory="${4}"
 
# List the parameter values passed.
echo "Username:  " ${username}
echo "Password:  " ${password}
echo "Database:  " ${database}
echo "Directory: " ${directory}
echo ""
 
# Define an array.
declare -a cmd
 
# Assign elements to an array.
cmd[0]="actor.sql"
cmd[1]="film.sql"
cmd[2]="movie.sql"
 
# Call the array elements.
for i in ${cmd[*]}; do
  mysql -s -u${username} -p${password} -D${database} < ${directory}/${i} > /dev/null 2>/dev/null
done
 
# Connect and pipe the query result minus errors and warnings to the while loop.
mysql -u${username} -p${password} -D${database} <<<'show tables' 2>/dev/null |
 
# Read through the piped result until it's empty but format the title.
while IFS='\n' read list; do
  if [[ ${list} = "Tables_in_sampledb" ]]; then
    echo $list
    echo "----------------------------------------"
  else
    echo $list
  fi
done
echo ""
 
# Connect and pipe the query result minus errors and warnings to the while loop.
mysql -u${username} -p${password} -D${database} <<<'SELECT CONCAT(a.actor_name," in ",f.film_name) AS "Actors in Films" FROM actor a INNER JOIN movie m ON a.actor_id = m.actor_id INNER JOIN film f ON m.film_id = f.film_id' 2>/dev/null |
 
# Read through the piped result until it's empty but format the title.
while IFS='\n' read actor_name; do
  if [[ ${actor_name} = "Actors in Films" ]]; then
    echo $actor_name
    echo "----------------------------------------"
  else
    echo $actor_name
  fi
done
***"

