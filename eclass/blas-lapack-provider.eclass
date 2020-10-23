# Copyright 2019-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: blas-lapack-provider.eclass
# @MAINTAINER:
# Gentoo Science Project <sci@gentoo.org>
# @AUTHOR:
# Aisha Tammy <gentoo@aisha.cc>
# @SUPPORTED_EAPIS: 7
# @BLURB: Dummy linking utilities for providers of BLAS/LAPACK
# @DESCRIPTION:
# Helper functions for creating dummy libraries which link
# to actual providers to get around runtime SONAME dependencies
# and without the need to create extra copies of libraries
#
# BLAS/LAPACK specifications do not mandate that the provider
# for the library needs to have all function symbols
# present in the linked library itself.
# Code relying on this behaviour is incorrect and should be
# patched accordingly and upstream should be notified.
# 'dlopen' calls to load symbols from the linked libraries
# ${LIBBLAS}/${LIBCBLAS} are relying on undocumented promises
# and should instead call the corresponding upstream provider
# such as libopenblas.so / libmkl_rt.so / libblis-mt.so / etc

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

EXPORT_FUNCTIONS pkg_postinst pkg_postrm

# @ECLASS-VARIABLE: PROVIDER_NAME
# @DEFAULT_UNSET
# @REQUIRED
# @DESCRIPTION:
# Name of provider to be used for registration
# for eselect blas / lapack
[[ -z "${PROVIDER_NAME}" ]] && die "PROVIDER_NAME needs to be defined and non empty"

# @ECLASS-VARIABLE: PROVIDER_BLAS
# @DEFAULT_UNSET
# @DESCRIPTION:
# Set this variable if the package
# is a provider for BLAS and CBLAS

# @ECLASS-VARIABLE: PROVIDER_LAPACK
# @DEFAULT_UNSET
# @DESCRIPTION:
# Set this variable if the package
# is a provider for LAPACK

# @ECLASS-VARIABLE: PROVIDER_LAPACKE
# @DEFAULT_UNSET
# @DESCRIPTION:
# Set this variable if the package
# is a provider for LAPACKE

# @ECLASS-VARIABLE: LIBBLAS
# @INTERNAL
# @DESCRIPTION:
# SONAME for libblas.so
LIBBLAS="${LIBBLAS:-libblas.so.3}"

# @ECLASS-VARIABLE: LIBCBLAS
# @INTERNAL
# @DESCRIPTION:
# SONAME for libcblas.so
LIBCBLAS="${LIBCBLAS:-libcblas.so.3}"

# @ECLASS-VARIABLE: LIBLAPACK
# @INTERNAL
# @DESCRIPTION:
# SONAME for liblapack.so
LIBLAPACK="${LIBLAPACK:-liblapack.so.3}"

# @ECLASS-VARIABLE: LIBLAPACKE
# @INTERNAL
# @DESCRIPTION:
# SONAME for liblapacke.so
LIBLAPACKE="${LIBLAPACKE:-liblapacke.so.3}"

# @FUNCTION: provider-link_blas
# @USAGE: <prepended_ldflags>
# @DESCRIPTION:
# Link libraries to an empty ${LIBBLAS}
# to create a provider for BLAS
#
# Creates a ${LIBBLAS} in the ${T} folder
#
# EXAMPLE:
# @CODE
# provider-link_blas "-Llib/generic -lblis-mt"
# @CODE
provider-link_blas() {
	debug-print-function ${FUNCNAME} "${@}"

	cat <<-EOF > "${T}"/gentoo_blas.c || die

	const char *__gentoo_${LIBBLAS%%.*}_provider(void){
		return "${PROVIDER_NAME}";
	}
	EOF

	emake -f - <<EOF
${T}/${LIBBLAS}:
	\$(CC) -shared -fPIC \$(CFLAGS) -o "${T}"/${LIBBLAS} "${T}"/gentoo_blas.c -Wl,--soname,${LIBBLAS} ${@} \$(LDFLAGS)
EOF
}

# @FUNCTION: provider-link_cblas
# @USAGE: <prepended_ldflags>
# @DESCRIPTION:
# Link libraries to an empty ${LIBCBLAS}
# to create a provider for CBLAS
#
# Creates a ${LIBCBLAS} in the ${T} folder
#
# EXAMPLE:
# @CODE
# provider-link_cblas "-Llib/generic -lblis-mt"
# @CODE
provider-link_cblas() {
	debug-print-function ${FUNCNAME} "${@}"

	cat <<-EOF > "${T}"/gentoo_cblas.c || die

	const char *__gentoo_${LIBCBLAS%%.*}_provider(void){
		return "${PROVIDER_NAME}";
	}
	EOF

	emake -f - <<EOF
${T}/${LIBCBLAS}:
	\$(CC) -shared -fPIC \$(CFLAGS) -o "${T}"/${LIBCBLAS} "${T}"/gentoo_cblas.c -Wl,--soname,${LIBCBLAS} ${@} \$(LDFLAGS)
EOF
}

# @FUNCTION: provider-link_lapack
# @USAGE: <prepended_ldflags>
# @DESCRIPTION:
# Link libraries to an empty ${LIBLAPACK}
# to create a provider for LAPACK
#
# Creates a ${LIBLAPACK} in the ${T} folder
#
# EXAMPLE:
# @CODE
# provider-link_lapack "-L. -lflame"
# @CODE
provider-link_lapack() {
	debug-print-function ${FUNCNAME} "${@}"

	cat <<-EOF > "${T}"/gentoo_lapack.c || die

	const char *__gentoo_${LIBLAPACK%%.*}_provider(void){
		return "${PROVIDER_NAME}";
	}
	EOF

	emake -f - <<EOF
${T}/${LIBLAPACK}:
	\$(CC) -shared -fPIC \$(CFLAGS) -o "${T}"/${LIBLAPACK} "${T}"/gentoo_lapack.c -Wl,--soname,${LIBLAPACK} ${@} \$(LDFLAGS)
EOF
}

# @FUNCTION: provider-link_lapacke
# @USAGE: <prepended_ldflags>
# @DESCRIPTION:
# Link libraries to an empty ${LIBLAPACKE}
# to create a provider for LAPACKE
#
# Creates a ${LIBLAPACKE} in the ${T} folder
#
# EXAMPLE:
# @CODE
# provider-link_lapacke "-L. -lopenblas"
# @CODE
provider-link_lapacke() {
	debug-print-function ${FUNCNAME} "${@}"

	cat <<-EOF > "${T}"/gentoo_lapacke.c || die

	const char *__gentoo_${LIBLAPACKE%%.*}_provider(void){
		return "${PROVIDER_NAME}";
	}
	EOF

	emake -f - <<EOF
${T}/${LIBLAPACKE}:
	\$(CC) -shared -fPIC \$(CFLAGS) -o "${T}"/${LIBLAPACKE} "${T}"/gentoo_lapacke.c -Wl,--soname,${LIBLAPACKE} ${@} \$(LDFLAGS)
EOF
}

# @FUNCTION: provider-install_libs
# @USAGE:
# @DESCRIPTION:
# Install the created ${LIBBLAS} and ${LIBLAPACK}
# to the providers eselect folder
provider-install_libs() {
	if [[ ! -z "${PROVIDER_BLAS+set}" ]]; then
		insinto /usr/$(get_libdir)/blas/${PROVIDER_NAME}
		insopts -m755
		doins "${T}"/{${LIBBLAS},${LIBCBLAS}}
		dosym ${LIBBLAS} usr/$(get_libdir)/blas/${PROVIDER_NAME}/${LIBBLAS%%so.*}so
		dosym ${LIBCBLAS} usr/$(get_libdir)/blas/${PROVIDER_NAME}/${LIBCBLAS%%so.*}so
	fi
	if [[ ! -z "${PROVIDER_LAPACK+set}" ]]; then
		insinto /usr/$(get_libdir)/lapack/${PROVIDER_NAME}
		insopts -m755
		doins "${T}"/${LIBLAPACK}
		dosym ${LIBLAPACK} usr/$(get_libdir)/lapack/${PROVIDER_NAME}/${LIBLAPACK%%so.*}so
	fi
	if [[ ! -z "${PROVIDER_LAPACKE+set}" ]]; then
		insinto /usr/$(get_libdir)/lapack/${PROVIDER_NAME}
		insopts -m755
		doins "${T}"/${LIBLAPACKE}
		dosym ${LIBLAPACKE} usr/$(get_libdir)/lapack/${PROVIDER_NAME}/${LIBLAPACKE%%so.*}.so
	fi
}

blas-lapack-provider_pkg_postinst() {
	local libdir=$(get_libdir)

	# check blas
	if [[ ! -z "${PROVIDER_BLAS+set}" ]]; then
		elog "adding ${PROVIDER_NAME}"
		eselect blas add ${libdir} "${EROOT}"/usr/${libdir}/blas/${PROVIDER_NAME} ${PROVIDER_NAME}
		elog "added ${PROVIDER_NAME}"
		local current_blas=$(eselect blas show ${libdir} | cut -d' ' -f2)
		if [[ ${current_blas} == "${PROVIDER_NAME}" || -z ${current_blas} ]]; then
			eselect blas set ${libdir} ${PROVIDER_NAME}
			elog "Current eselect: BLAS/CBLAS ($libdir) -> [${current_blas}]."
		else
			elog "Current eselect: BLAS/CBLAS ($libdir) -> [${current_blas}]."
			elog "To use blas [${PROVIDER_NAME}] implementation, you have to issue (as root):"
			elog "\t eselect blas set ${libdir} ${PROVIDER_NAME}"
		fi
	fi
	# check lapack
	if [[ ! -z "${PROVIDER_LAPACK+set}" ]]; then
		elog "adding ${PROVIDER_NAME}"
		eselect lapack add ${libdir} "${EROOT}"/usr/${libdir}/lapack/${PROVIDER_NAME} ${PROVIDER_NAME}
		elog "added ${PROVIDER_NAME}"
		local current_lapack=$(eselect lapack show ${libdir} | cut -d' ' -f2)
		if [[ ${current_lapack} == "${PROVIDER_NAME}" || -z ${current_lapack} ]]; then
			eselect lapack set ${libdir} ${PROVIDER_NAME}
			elog "Current eselect: LAPACK ($libdir) -> [${current_lapack}]."
		else
			elog "Current eselect: LAPACK ($libdir) -> [${current_lapack}]."
			elog "To use lapack [${PROVIDER_NAME}] implementation, you have to issue (as root):"
			elog "\t eselect lapack set ${libdir} ${PROVIDER_NAME}"
		fi
	fi
}

blas-lapack-provider_pkg_postrm() {
	[[ ! -z "${PROVIDER_BLAS+set}" ]] && eselect blas validate
	[[ ! -z "${PROVIDER_LAPACK+set}" ]] && eselect lapack validate
}
