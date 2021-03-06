#!/usr/bin/env bash

# $1 - file to check against (i.e. /proc/config.gz or /usr/src/linux/.config
# $2 - file(s) with required options (usually profiles/*/*/linuxconfig)
# $3 - toggle to only show problems
# TODO speed this script up
# TODO check for colisions/duplicate entries with dif. values in $1

[[ -f ${1} ]] || eexit "Can't find ${1}, exitting."
[[ -e ${2} ]] || eexit "Can't find ${2}, exitting."
[[ -f ${2} ]] && REQUIREMENTS="${2}"
[[ -d ${2} ]] && REQUIREMENTS="${2}/*"  # zgrep through all containing files if ${2} is a directory

# zgrep, unlike zcat, works on both, compressed and auncompressed files.
# zgrep also doesn't signal eof such as zless or zmore.
# {PARAM,VALUE} shall be from the requirements set
# {CONFP,CONFV} shall be from the kernel .config set
zgrep -h . ${REQUIREMENTS} | while read LINE; do 
  PARAM=`printf "$LINE" | grep ^[^#] | sed 's:#.*$::g' | awk -F'=' '{print $1}'`
  VALUE=`printf "$LINE" | grep ^[^#] | sed 's:#.*$::g' | awk -F'=' '{print $2}' |  sed 's/^[ \t]*//;s/[ \t]*$//'`

  if [ -n "${PARAM}" ]; then
     CONFP=`zgrep "${PARAM}=" ${1}`
     CONFV=`echo "${CONFP}" | awk -F'=' '{print $2}'`
     CONFP=`echo "${CONFP}" | awk -F'=' '{print $1}'`
     
     if echo "${CONFV}" | grep -iq "${VALUE}"; then # Case insensitive comparison. `if [ "${CONFV}" =~ "${VALUE}" ]; then` didn't work for whatever reason.
       [[ "${!#}" = "problems" ]] || echo "${GOOD}${CONFP}=${CONFV}" # ${!#} is the "last parameter" equivalent, replaces ${3}
     else
       shopt -s nocasematch
       [[ -n "${CONFV}" ]] && echo "${BAD}${CONFP}=${CONFV}${NORMAL}   [expected value: ${VALUE}]"
       if ! [ "${VALUE}" = "n" ]; then { # TODO nocasematch doesnt work here for whatever reasons, replace with nN
         [[ -n "${CONFV}" ]] || echo "${WARN}${PARAM}=${VALUE}${NORMAL}   [option not set at all]"
       }
       fi
       shopt -u nocasematch
     fi
    echo Hello | grep -iq hello; 
  fi
done
