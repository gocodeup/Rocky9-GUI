#!/bin/bash

function print_PASS() {
  echo -e '\033[1;32mPASS\033[0;39m'
}

function print_FAIL() {
  echo -e '\033[1;31mFAIL\033[0;39m'
}

function pad {
  PADDING="..............................................................."
  TITLE=$1
  printf "%s%s  " "${TITLE}" "${PADDING:${#TITLE}}"
}
 function install_perl {
   sudo yum install perl -y
 }

function grade_Ring {
  pad "Checking for removal of file named Ring"
  
  if [ -f /usr/bin/Ring ]; then
    print_FAIL
    echo " - The file named Ring has not been removed."
    return 1
  fi

  print_PASS
  return 0
}

function grade_Bilbo_files {
  pad "Checking for removal of all files owned by the user Bilbo"

  if [ -f /tmp/Precious ]; then
    print_FAIL
    echo "- The Precious file owned by Bilbo has not been removed."
    return 1
  fi

  if [ -f /var/log/Precious2 ]; then
    print_FAIL
    echo -e "\033[1;31m - The Precious2 file owned by Bilbo has not been removed.\033[0;39m"
    return 1
  fi

  if [ -f /etc/Cursed ]; then
    print_FAIL
    echo -e "\033[1;31m - The Cursed file owned by Bilbo has not been removed.\033[0;39m"
    return 1
  fi
    print_PASS
  return 0
}

install_perl

# end grading section

function lab_grade {
  FAIL=0
  grade_Ring || (( FAIL += 1 ))
  grade_Bilbo_files || (( FAIL += 1 ))
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


# Branch based on short (without number) hostname
lab_grade
