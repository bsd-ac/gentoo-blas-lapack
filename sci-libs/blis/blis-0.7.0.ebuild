# Copyright 2019-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} )
PROVIDER_BLAS=1
PROVIDER_CBLAS=1
PROVIDER_NAME=blis
inherit blas-lapack-provider fortran-2 python-any-r1

DESCRIPTION="BLAS-like Library Instantiation Software Framework"
HOMEPAGE="https://github.com/flame/blis"
SRC_URI="https://github.com/flame/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~ppc64 ~x86"
IUSE="openmp pthread static-libs doc 64bit-index"
REQUIRED_USE="?? ( openmp pthread )"

RDEPEND="
	!64bit-index? ( >=app-eselect/eselect-blas-0.2 )
"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
"

PATCHES=(
	"${FILESDIR}/${P}-rpath.patch"
)

pkg_pretend() {
	elog "It is very important that to set the BLIS_CONFNAME"
	elog "variable when compiling blis as it tunes the"
	elog "compilation to the specific CPU architecture."
	elog "To look at valid BLIS_CONFNAMEs, look at directories in"
	elog "\t https://github.com/flame/blis/tree/master/config"
	elog "At the very least, it should be set to the ARCH of"
	elog "the machine this will be run on, which gives a"
	elog "performance increase of ~4-5x."
}

pkg_setup() {
	fortran-2_pkg_setup
	use openmp && tc-check-openmp

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

	# not an autotools configure script
	./configure "${myconf[@]}" \
	            "${EXTRA_ECONF[@]}" \
	            ${BLIS_CONFNAME} || die
}

src_compile() {
	SET_RPATH=no \
	default

	if ! use 64bit-index ; then
		provider-link_blas "-Llib/${BLIS_CONFNAME} -lblis"
		provider-link_cblas "-Llib/${BLIS_CONFNAME} -lblis"
	fi
}

src_test() {
	local -x LD_LIBRARY_PATH=lib/${BLIS_CONFNAME}
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
	! use 64bit-index || \
		blas-lapack-provider_src_postrm
}
