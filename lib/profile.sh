#!/usr/bin/env bash

. /etc/portage/make.conf      # include make.conf


case "$1" in
    enable)
        shift 1;
        pushd "${VARDIR}/${1}" || eexit "No such profile in ${VARDIR}"
        
        [[ `cat /etc/mage/profiles-enabled | grep "${1}"` ]] && ewarn "Profile ${1} already enabled, really wanna do that again?" && read -r -p "[y/n]: " response
        case $response in
             [yY]) 
                for D in *; do
                    [[ -d "${D}" ]] && cp -r `echo "${D} /etc/portage"`
                done
                popd >> /dev/null
                [[ -d "/etc/mage" ]] || ewarn "/etc/mage directory is not present when it should, creating it!" && mkdir -p /etc/mage || eexit "It seems that an /etc/mage *file* exists already. Exitting because of name colision."
                [[ -d "/etc/mage/linuxconfig" ]] || ewarn "/etc/mage/linuxconfig directory is not present when it should, creating it!" && mkdir -p /etc/mage/linuxconfig || eexit "It seems that an /etc/mage/linuxconfig *file* exists already. Exitting because of name colision."
                [[ -f "${VARDIR}/${1}/linuxconfig" ]] && cp "${VARDIR}/${1}/linuxconfig" "/etc/mage/linuxconfig/`echo ${1} | tr '/' '-'`"
                [[ -f "${VARDIR}/${1}/setup.sh" ]] && . "${VARDIR}/${1}/setup.sh"
                echo "${1}" >> /etc/mage/profiles-enabled
            ;;
            *)
                einfo "Doing nothing then"
            ;;
        esac
    ;;
    *)
        eexit "Command ${BOLD}${1}${NORMAL} not recognized, exitting. Try ${BOLD}mage help profile${NORMAL}"
    ;;
esac


