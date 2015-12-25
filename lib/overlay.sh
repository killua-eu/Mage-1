#!/usr/bin/env bash

. /etc/portage/make.conf      # include make.conf


# mk_overlay($ONAME,$OPATH)
# use OPATH without trailing slash

overlay_mk()
{
	[ -z "$1" ] && return 1
	[ -z "$2" ] && return 1
	ONAME=${1}
	OPATH=${2}
	einfo "Creating repo ${ONAME} in ${OPATH}"
	mkdir -p "${OPATH}/"{metadata,profiles} || eexit "Failed to create ${OPATH}/{metadata,profiles}"
        echo "${ONAME}" > "${OPATH}/profiles/repo_name" || eexit "Failed setting repo_name"
        echo 'masters = gentoo' > "${OPATH}/metadata/layout.conf" || eexit "${MFAIL} Failed setting layout.conf"
	chown -R portage:portage ${OPATH}
	mkdir -p /etc/portage/repos.conf

	cat >> /etc/portage/repos.conf/local.conf << DATA_END
[${ONAME}]
location = ${OPATH}
masters = gentoo
auto-sync = no
DATA_END

	edone "Done!"
	
}


    case "$1" in

        mk)
            shift 1;
	    overlay_mk ${1} ${2};
        ;;
        *)
    	    eexit "Command ${BOLD}${1}${NORMAL} not recognized, exitting. Try ${BOLD}mage help overlay${NORMAL}"
        ;;
    esac


	