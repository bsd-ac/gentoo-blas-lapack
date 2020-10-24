# @ECLASS: library-provider.eclass
# @MAINTAINER:
# Gentoo Science Project <sci@gentoo.org>
# @AUTHOR:
# Aisha Tammy <gentoo@aisha.cc>
# @SUPPORTED_EAPIS: 7
# @BLURB: trivial functions for eselect library
# @DESCRIPTION:
# default implementations for the ebuild
# operations of a library provider

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

RDEPEND="app-eselect/eselect-library"
DEPEND="${RDEPEND}"

EXPORT_FUNCTIONS pkg_postinst pkg_postrm

# @ECLASS-VARIABLE: PROVIDER_NAME
# @DEFAULT_UNSET
# @REQUIRED
# @DESCRIPTION:
# Name of libraryprovider to be used all
# library registrations
[[ -z "${PROVIDER_NAME}" ]] && die "PROVIDER_NAME needs to be defined and non empty"

# @ECLASS-VARIABLE: PROVIDER_LIBS
# @DEFAULT_UNSET
# @DESCRIPTION:
# Set this variable if the package
# is a provider for BLAS and CBLAS
[[ -z "${PROVIDER_LIBS}" ]] && die "PROVIDER_LIBS needs to be defined and non empty"

# @ECLASS-VARIABLE: PROVIDER_DIRS
# @DEFAULT_UNSET
# @DESCRIPTION:
# dirs in which libraries are registered
# PROVIDER_LIBS[i] should be present in PROVIDER_DIRS[i]
# PROVIDER_DIRS[i] defaults to ${EROOT}/usr/$(get_libdir)/${LIBNAME}/${PROVIDER_NAME}

library-provider_pkg_postinst() {
	local libdir=$(get_libdir)
	local plib pdir
	local icnt=0
	for plib in ${PROVIDER_LIBS[@]}; do
		if [[ $icnt -lt ${#PROVIDER_DIRS[@]} ]]; then
			pdir="${PROVIDER_DIRS[$icnt]}"
		else
			pdir="${EROOT}/usr/${libdir}/${plib}/${PROVIDER_NAME}"
		fi
		icnt=$((icnt + 1))
		elog "adding ${PROVIDER_NAME} [${pdir}] as a provider for ${plib}"
		eselect library add ${plib} ${libdir} "${EROOT}"/${pdir} ${PROVIDER_NAME}
		elog "added ${PROVIDER_NAME} [${pdir}] as a provider for ${plib}"
		local current_library=$(eselect library show ${plib} ${libdir} | cut -d' ' -f2)
		if [[ ${current_library} == "${PROVIDER_NAME}" ]]; then
			eselect library set ${plib} ${libdir} ${PROVIDER_NAME}
			elog "Current eselect: ${plib} ($libdir) -> [${current_library}]."
		else
			elog "Current eselect: ${plib} ($libdir) -> [${current_library}]."
			elog "To use ${LIBNAME} [${PROVIDER_NAME}] as the provider, you have to issue (as root):"
			elog "\t eselect library set ${plib} ${libdir} ${PROVIDER_NAME}"
		fi
	done
}

library-provider_pkg_postrm() {
	local plib
	for plib in ${PROVIDER_LIBS[@]}; do
		eselect library validate ${plib}
	done
}
