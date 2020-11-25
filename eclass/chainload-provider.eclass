# @ECLASS: chainload-provider.eclass
# @MAINTAINER:
# Gentoo Science Project <sci@gentoo.org>
# @AUTHOR:
# Aisha Tammy <gentoo@aisha.cc>
# @SUPPORTED_EAPIS: 7,8
# @BLURB: library chainloading utilities, for dummy libraries
# @DESCRIPTION:
# Helper functions for creating dummy libraries which link
# to actual providers to get around runtime SONAME dependencies
# and without the need to create extra copies of libraries.
# Specifically made for BLAS and LAPACK providers but is
# usable for any and all libraries.

case "${EAPI:-0}" in
	0|1|2|3|4|5|6)
		die "Unsupported EAPI=${EAPI:-0} (too old) for ${ECLASS}"
		;;
	7,8)
		;;
	*)
		die "Unsupported EAPI=${EAPI} (unknown) for ${ECLASS}"
		;;
esac

inherit flag-o-matic toolchain-funcs

# @FUNCTION: provider-link-lib
# @USAGE: <libname> [<prepended_ldflags>]
# @DESCRIPTION:
# Create a dummy C library for chain loading.
# Creates a ${libname} in the ${T} folder.
#
# EXAMPLE:
# @CODE
# provider-link-lib "libcblas.so.3" "-Llib/generic -lblis-mt"
# @CODE
provider-link-lib() {
	debug-print-function ${FUNCNAME} "${@}"

	local libname lname
	libname=$1
	shift 1
	# remove trailing .so.* and starting lib
	lname=${libname%%.*}
	lname=${lname##lib}
	cat <<-EOF > "${T}"/gentoo_${lname}.c || die
	const char *__gentoo_${lname}_provider(void){
		return "${PROVIDER_NAME}";
	}
	EOF

	tc-export CC
	local needed="$(no-as-needed)"
	emake -f - <<EOF
all:
	\$(CC) -shared -fPIC \$(CFLAGS) -o "${T}"/${libname} "${T}"/gentoo_${lname}.c -Wl,--soname,${libname} -Wl,--push-state ${needed} ${@} -Wl,--pop-state \$(LDFLAGS)
EOF
}

# @FUNCTION: provider-install-lib
# @USAGE: <libname> [<dir>]
# @DESCRIPTION:
# Install the created ${libname} to ${dir}
# ${dir} defaults to /usr/$(get_libdir)/${lname}/${PROVIDER_NAME}
provider-install-lib() {
	if [[ $# -ne 1 ]] && [[ $# -ne 2 ]]; then
		die -q "need <libname> [<dir>]"
	fi
	local libname=$1 lname dir
	# remove trailing .so.* and starting lib
	lname=${libname%%.*}
	lname=${lname##lib}
	dir="/usr/$(get_libdir)/${lname}/${PROVIDER_NAME}"
	[[ $# -eq 2 ]] && dir="${2}"
	insinto ${dir}
	insopts -m755
	doins "${T}"/${libname}
	dosym ${libname} ${dir}/lib${lname}.so
}
