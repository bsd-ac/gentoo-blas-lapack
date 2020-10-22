# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..9} )
PROVIDER_NAME="blis-amd"
PROVIDER_BLAS=1
inherit blas-lapack-provider fortran-2 python-any-r1 toolchain-funcs

DESCRIPTION="AMD optimized BLAS-like Library Instantiation Software Framework"
HOMEPAGE="https://developer.amd.com/amd-aocl/"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/amd/blis"
else
	SRC_URI="https://github.com/amd/blis/archive/${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}"/blis-"${PV}"
	KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86"
fi

LICENSE="BSD"
SLOT="0"
IUSE="64bit-index doc openmp pthread static-libs"
REQUIRED_USE="?? ( openmp pthread )"

RDEPEND="
	!64bit-index? ( >=app-eselect/eselect-blas-0.2 )
	!sci-libs/blis
"
DEPEND+="${RDEPEND}
	${PYTHON_DEPS}
"

PATCHES=(
	"${FILESDIR}"/${P}-blas_rpath.patch
)

pkg_pretend() {
	elog "It is very important that to set the BLIS_CONFNAME"
	elog "variable when compiling blis as it tunes the"
	elog "compilation to the specific CPU architecture."
	elog "To look at valid BLIS_CONFNAMEs, look at directories in"
	elog "\t https://github.com/amd/blis/tree/master/config"
	elog "At the very least, it should be set to the ARCH of"
	elog "the machine this will be run on, which gives a"
	elog "performance increase of ~4-5x."
}

pkg_setup() {
	fortran-2_pkg_setup
	python-any-r1_pkg_setup
	tc-export CC AR LD RANLIB

	export BLIS_CONFNAME=${BLIS_CONFNAME:-generic}
}

src_configure() {
	local myconf=(
		--prefix="${BROOT}"/usr
		--libdir="${BROOT}"/usr/$(get_libdir)
		--enable-cblas
		--enable-blas
		--enable-arg-max-hack
		--enable-verbose-make
		--without-memkind
		--enable-shared
		$(use_enable static-libs static)
	)

	use 64bit-index && \
	myconf+=(
		--int-size=64
		--blas-int-size=64
	)

	# threading backend - openmp/pthreads/no
	if use openmp; then
		myconf+=( --enable-threading=openmp )
	elif use pthread; then
		myconf+=( --enable-threading=pthreads )
	else
		myconf+=( --enable-threading=no )
	fi

	./configure "${myconf[@]}" \
	            "${EXTRA_ECONF[@]}" \
	            ${BLIS_CONFNAME} || die
}

src_compile() {
	SET_RPATH=no \
	default

	if ! use 64bit-index ; then
		local -x BLIS_LIB=blis-mt
		if ! use openmp && ! use pthread ; then
			BLIS_LIB=blis
		fi
		provider-link_blas "-Llib/${BLIS_CONFNAME} -l${BLIS_LIB}"
		provider-link_cblas "-Llib/${BLIS_CONFNAME} -l${BLIS_LIB}"
	fi
}

src_test() {
	emake check
}

src_install() {
	default
	use doc && dodoc README.md docs/*.md

	use 64bit-index || provider-install_libs
}

src_postinst() {
	use 64bit-index || \
		blas-lapack-provider_src_postinst
}

src_postrm() {
	use 64bit-index || \
		blas-lapack-provider_src_postrm
}
