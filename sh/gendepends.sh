#!/bin/sh
# Shell wrapper to list our dependencies

# Copyright 2007-2008 Roy Marples
# All rights reserved

. /etc/init.d/functions.sh

config() {
	[ -n "$*" ] && echo "${SVCNAME} config $*" >&3
}
need() {
	[ -n "$*" ] && echo "${SVCNAME} ineed $*" >&3
}
use() {
	[ -n "$*" ] && echo "${SVCNAME} iuse $*" >&3
}
before() {
	[ -n "$*" ] && echo "${SVCNAME} ibefore $*" >&3
}
after() {
	[ -n "$*" ] && echo "${SVCNAME} iafter $*" >&3
}
provide() {
	[ -n "$*" ] && echo "${SVCNAME} iprovide $*" >&3
}
keywords() {
	[ -n "$*" ] && echo "${SVCNAME} keywords $*" >&3
}
depend() {
	:
}

for _dir in /etc/init.d /usr/local/etc/init.d; do
	[ -d "${_dir}" ] || continue
	cd "${_dir}"
	for SVCNAME in *; do
		[ -x "${SVCNAME}" ] || continue

		# Only generate dependencies for runscripts
		read one two < "${SVCNAME}"
		[ "${one}" = "#!/sbin/runscript" ] || continue
		unset one two

		export SVCNAME=${SVCNAME##*/}
		(
		# Save stdout in fd3, then remap it to stderr
		exec 3>&1 1>&2

		_rc_c=${SVCNAME%%.*}
		if [ -n "${_rc_c}" -a "${_rc_c}" != "${SVCNAME}" ]; then
			[ -e "${_dir}/../conf.d/${_rc_c}" ] && . "${_dir}/../conf.d/${_rc_c}"
		fi
		unset _rc_c

		[ -e "${_dir}/../conf.d/${SVCNAME}" ] && . "${_dir}/../conf.d/${SVCNAME}"

		[ -e /etc/rc.conf ] && . /etc/rc.conf

		if . "${_dir}/${SVCNAME}"; then
			echo "${SVCNAME}" >&3
			depend

			# Add any user defined depends
			for _deptype in config need use after before provide keywords; do
				eval _depends=\$rc_$(shell_var "${SVCNAME}")_${_deptype}
				[ -z "${_depends}" ] && eval _depends=\$rc_${_deptype}
				${_deptype} ${_depends}
			done
		fi
		)
	done
done

# vim: set ts=4 :
