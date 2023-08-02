#!/bin/bash
# NAME
#     grademe - grading script for End of Lesson 3 Lab.
#
# Initialize and set some variables
MYHOST=""
CMD=""
DEBUG='true'
RUN_AS_ROOT='true'
# Source library of functions
LOG_FACILITY=local0
LOG_PRIORITY=info
LOG_TAG="${0##*/}"
DEBUG=false
ERROR_MESSAGE="Error running script. Contact your instructor if you continue \
to see this message."
PACKAGES=( bash )
# paths
LOGGER='/usr/bin/logger'
RPM='/bin/rpm'
SUDO='/usr/bin/sudo'
# Export LANG so we get consistent results
# For instance, fr_FR uses comma (,) as the decimal separator.
export LANG=en_US.UTF-8
# Read in GLS parameters if available
[ -r /etc/rht ] && . /etc/rht
# Set up exit handler (no need for user to do this)
trap on_exit EXIT
function log {
if [[ ${#1} -gt 0 ]] ; then
    $LOGGER -p ${LOG_FACILITY}.${LOG_PRIORITY} -t $LOG_TAG -- "$1"
else
    while read data ; do
        $LOGGER -p ${LOG_FACILITY}.${LOG_PRIORITY} -t $LOG_TAG -- "$1" "$data"
    done
fi
}
function debug {
if [[ ${#1} -gt 0 ]] ; then
    msg="$1"
    if [[ "$DEBUG" = "true" ]] ; then
        echo "$msg"
    fi
    log "$msg"
else
    while read data ; do
        if [[ "$DEBUG" = "true" ]] ; then
            echo "$data"
        fi
        log "$data"
    done
fi
}
function on_exit {
status="$?"
if [[ "$status" -eq "0" ]] ; then
    exit 0
else
    DEBUG=true
    debug "$ERROR_MESSAGE"
    exit "$status"
fi
}
function check_root {
if [[ "$EUID" -gt "0" ]] ; then
    log 'Not running run as root = Fail'
    ERROR_MESSAGE='This script must be run as root!'
    exit 1
fi
}
function check_packages {
for package in ${PACKAGES[@]} ; do
    if $RPM -q $package &>/dev/null ; then
        continue
    else
        ERROR_MESSAGE="Please install $package and try again."
        exit 2
    fi
done
}
function confirm {
read -p "Is this ok [y/N]: " userInput
case "${userInput:0:1}" in
    "y" | "Y")
        return
        ;;
    *)
        ERROR_MESSAGE="Script aborted."
        exit 3
        ;;
esac
}
function check_host {
if [[ ${#1} -gt 0 ]]; then
    if [[ "$1" == "${HOSTNAME:0:${#1}}" ]]; then
        return
    else
        ERROR_MESSAGE="This script must be run on ${1}."
        exit 4
    fi
fi
}
function check_tcp_port {
if [[ ${#1} -gt 0 && ${#2} -gt 0 ]]; then
    # Sending it to the log always returns 0
    ($(echo "brain" >/dev/tcp/$1/$2)) && return 0
fi
return 1
}
function wait_tcp_port {
if [[ ${#1} -gt 0 && ${#2} -gt 0 ]]; then
    # Make sure it is pingable before we attempt the port check
    echo
    echo -n "Pinging $1"
    until `ping -c1 -w1 $1 &> /dev/null`;do
        echo -n "."
        sleep 3
    done
    iterations=0
    echo
    echo 'You may see a few "Connection refused" errors before it connects...'
    sleep 10
    until [[ "$remote_port" == "smart" || $iterations -eq 30 ]]; do
        ($(echo "brain" >/dev/tcp/$1/$2) ) && remote_port="smart" || remote_port="dumb"
        sleep 3
        iterations=$(expr $iterations + 1)
    done
    [[ $remote_port == "smart" ]] && return 0
fi
return 1
}
function push_sshkey {
if [[ ${#1} -gt 0 ]]; then
    rm -f /root/.ssh/known_hosts
    rm -f /root/.ssh/.labtoolkey
    rm -f /root/.ssh/.labtoolkey.pub
    (ssh-keygen -q -N "" -f /root/.ssh/.labtoolkey) || return 1
    (/usr/local/lib/labtool-installkey /root/.ssh/.labtoolkey.pub $1) && return 0
fi
return 1
}
function get_X {
  if [[ -n "${RHT_ENROLLMENT}" ]] ; then
    X="${RHT_ENROLLMENT}"
    MYHOST="${RHT_ROLE}"
  elif hostname -s | grep -q '[0-9]' ; then
    X="$(hostname -s | grep -o '[0-9]*')"
    MYHOST="$(hostname -s | grep -o '[^0-9]*')"
  else
    # If the short hostname does not have a number, it is probably localhost.
    return 1
  fi
  SERVERX="server${X}.example.com"
  DESKTOPX="desktop${X}.example.com"
  # *** The following variables are deprecated. Do not use them.
# TWO_DIGIT_X="$(printf %02i ${X})"
# TWO_DIGIT_HEX="$(printf %02x ${X})"
# LASTIPOCTET="$(hostname -i | cut -d. -f4)"
# # IPOCTETX should match X
# IPOCTETX="$(hostname -i | cut -d. -f3)"
  return 0
}
function get_disk_devices {
  # This functions assumes / is mounted on a physical partition,
  #   and that the secondary disk is of the same type.
  PDISK=$(df | grep '/$' | sed 's:/dev/\([a-z]*\).*:\1:')
  SDISK=$(grep -v "${PDISK}" /proc/partitions | sed '1,2d; s/.* //' |
          grep "${PDISK:0:${#PDISK}-1}.$" | sort | head -n 1)
  PDISKDEV=/dev/${PDISK}
  SDISKDEV=/dev/${SDISK}
}
function print_PASS() {
  echo -e '\033[1;32mPASS\033[0;39m'
}
function print_FAIL() {
  echo -e '\033[1;31mFAIL\033[0;39m'
}
function print_SUCCESS() {
  echo -e '\033[1;36mSUCCESS\033[0;39m'
}
# Additional functions for this shell script
function print_usage {
  cat << EOF
This script controls the grading of this lab.
Usage: grademe
       grademe -h|--help
EOF
}
function pad {
  PADDING="..............................................................."
  TITLE=$1
  printf "%s%s  " "${TITLE}" "${PADDING:${#TITLE}}"
}
 function install_perl {
   yum install perl -y
 }
function grade_umask {
  pad "Checking for correct umask for Rufus"
  grep 'umask 007' /home/Rufus/.bashrc &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - The umask for Rufus is not set properly."
    return 1
  fi
  print_PASS
  return 0
}
function grade_shareddir {
  pad "Checking for correct collaborative directory"
  if [ ! -d /PowerCompany ]; then
    print_FAIL
    echo " - The /PowerCompany directory does not exist."
    return 1
  fi
  if [ $(stat -c %G /PowerCompany) != "Shinra" ]; then
    print_FAIL
    echo " - /PowerCompany does not have correct group ownership."
    return 1
  fi
  if [ $(stat -c %a /PowerCompany) -ne 2770 ]; then
    print_FAIL
    echo " - /PowerCompany does not have correct permissions."
    return 1
  fi
  print_PASS
  return 0
}
function grade_Rufus_facls {
 pad 'Checking access to /PowerCompany for Rufus'
  getfacl /PowerCompany 2>/dev/null | grep "user:Rufus:---" &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - Access to /PowerCompany for Rufus is not set properly."
    return 1
  fi
  getfacl /PowerCompany 2>/dev/null | grep "default:user:Rufus:---" &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - Rufus is still able to access any files created in /PowerCompany in the future."
    return 1
  fi
  print_PASS
  return 0
}
function grade_Mako {
pad 'Checking /Mako.txt permissions.'
  if [ $(stat -c %G /Mako.txt) != "Shinra" ]; then
    print_FAIL
    echo " - /Mako.txt does not have correct group ownership."
    return 1
  fi
  if [ $(stat -c %a /Mako.txt) -ne 660 ]; then
    print_FAIL
    echo " - /Mako.txt does not have correct permissions."
    return 1
  fi
  print_PASS
  return 0
}
function grade_Scarlet_facls {
 pad 'Checking access to /Mako.txt for Scarlet'
  getfacl /Mako.txt 2>/dev/null | grep "user:Scarlet:r--" &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - Access to /Mako.txt for Scarlet is not set properly."
    return 1
  fi
  print_PASS
  return 0
}
install_perl
# end grading section
function lab_grade {
  FAIL=0
  grade_umask || (( FAIL += 1 ))
  grade_shareddir || (( FAIL += 1 ))
  grade_Rufus_facls || (( FAIL += 1 ))
  grade_Mako || (( FAIL += 1 ))
  grade_Scarlet_facls || (( FAIL += 1 ))
  echo
  pad "Overall result"
  if [ ${FAIL} -eq 0 ]; then
    print_PASS
    echo "Congratulations! You've passed all tests."
  else
    print_FAIL
    echo "You failed ${FAIL} tests, please check your work and try again."
  fi
}
# Main area
# Check if to be run as root (must do this first)
if [[ "${RUN_AS_ROOT}" == 'true' ]] && [[ "${EUID}" -gt "0" ]] ; then
  if [[ -x /usr/bin/sudo ]] ; then
    ${SUDO:-sudo} $0 "$@"
    exit
  else
    # Fail out if not running as root
    check_root
  fi
fi
get_X
# Branch based on short (without number) hostname
lab_grade 'desktop'
