#!/usr/bin/env bash

# $1 - file(s) with required options (usually /etc/mage/conflinux)
# $2 - file to check against (i.e. /proc/config.gz or /usr/src/linux/.config
# $3 - toggle to only show problems
# TODO speed this script up
# TODO check for colisions/duplicate entries with dif. values in $1
# TODO better support $1 as a directory /etc/mage/conflinux/* - now this has to be quoted to work properly

zless ${1} | while read LINE; do 
  PARAM=`printf "$LINE" | grep ^[^#] | sed 's:#.*$::g' | awk -F'=' '{print $1}'`
  VALUE=`printf "$LINE" | grep ^[^#] | sed 's:#.*$::g' | awk -F'=' '{print $2}' |  sed 's/^[ \t]*//;s/[ \t]*$//'`

  if [ -n "${PARAM}" ]; then
     CONFP=`zgrep "${PARAM}=" ${2}`
     CONFV=`echo "${CONFP}" | awk -F'=' '{print $2}'`
     CONFP=`echo "${CONFP}" | awk -F'=' '{print $1}'`
     
     if echo "${CONFV}" | grep -iq "${VALUE}"; then # Case insensitive comparison. `if [ "${CONFV}" =~ "${VALUE}" ]; then` didn't work for whatever reason.
       [[ "${3}" = "problems" ]] || echo "${GOOD}${CONFP}=${CONFV}"
     else
       [[ -n "${CONFV}" ]] && echo "${BAD}${CONFP}=${CONFV}${NORMAL}   [expected value: ${VALUE}]"
       [[ -n "${CONFV}" ]] || echo "${WARN}${PARAM}=${VALUE}${NORMAL}   [option not set at all]"
     fi
    echo Hello | grep -iq hello; 
  fi
done


