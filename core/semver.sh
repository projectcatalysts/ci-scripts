#!/bin/bash

# function: procat_ci_semver_bump
# desc:     Increment a version string using Semantic Versioning (SemVer)
# usage:    procat_ci_semver_bump [-Mmp] major.minor.patch
function procat_ci_semver_bump {
	# Parse command line options.
	while getopts ":Mmp" Option
	do
		case $Option in
			M ) major=true;;
			m ) minor=true;;
			p ) patch=true;;
		esac
	done

	shift $(($OPTIND - 1))
	version=$1

	# Build array from version string.
	a=( ${version//./ } )

	# If version string is missing or has the wrong number of members, show usage message.
	if [ ${#a[@]} -ne 3 ]
	then
		pc_log_fatal "procat_ci_semver_bump [-Mmp] major.minor.patch"
	fi

	# Increment version numbers as requested.
	if [ ! -z $major ]
	then
		((a[0]++))
		a[1]=0
		a[2]=0
	fi

	if [ ! -z $minor ]
	then
		((a[1]++))
		a[2]=0
	fi

	if [ ! -z $patch ]
	then
		((a[2]++))
	fi

	echo "${a[0]}.${a[1]}.${a[2]}"
}