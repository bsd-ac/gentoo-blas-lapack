# @ECLASS: chainload-provider.eclass
# @MAINTAINER:
# Gentoo Science Project <sci@gentoo.org>
# @AUTHOR:
# Aisha Tammy <gentoo@aisha.cc>
# @SUPPORTED_EAPIS: 7
# @BLURB: library chainloading utilities, for dummy libraries
# @DESCRIPTION:
# Helper functions for creating dummy libraries which link
# to actual providers to get around runtime SONAME dependencies
# and without the need to create extra copies of libraries.
#
# Specifically made for BLAS and LAPACK providers but is
# usable for any other library.
# Notes about BLAS/LAPACK -
# BLAS/LAPACK specifications do not mandate that the provider
# for the library needs to have all function symbols
# present in the linked library itself.
# Code relying on this behaviour is incorrect and should be
# patched accordingly and upstream should be notified.
# 'dlopen' calls to load symbols from the linked libraries
# ${LIBBLAS}/${LIBCBLAS} are relying on undocumented promises
# and should instead call the corresponding upstream provider
# such as libopenblas.so / libmkl_rt.so / libblis-mt.so / etc.

case "${EAPI:-0}" in
	0|1|2|3|4|5|6)
		die "Unsupported EAPI=${EAPI:-0} (too old) for ${ECLASS}"
		;;
	7)
		;;
	*)
		die "Unsupported EAPI=${EAPI} (unknown) for ${ECLASS}"
		;;
esac

inherit library-provider toolchain-funcs

# @FUNCTION: provider-link-c
# @USAGE: <libname> [<prepended_ldflags>]
# @DESCRIPTION:
# Create a dummy c library for chain loading.
# Creates a ${libname} in the ${T} folder.
#
# EXAMPLE:
# @CODE
# provider-link-c "libcblas.so.3" "-Llib/generic -lblis-mt"
# @CODE
provider-link-c() {
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
	emake -f - <<EOF
${T}/${libname}:
	\$(CC) -shared -fPIC \$(CFLAGS) -o "${T}"/${libname} "${T}"/gentoo_${lname}.c -Wl,--soname,${libname} ${@} \$(LDFLAGS)
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
