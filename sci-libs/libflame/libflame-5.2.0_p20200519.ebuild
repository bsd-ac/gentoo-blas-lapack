# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PROVIDER_NAME=libflame
PROVIDER_LIBS="lapack"
inherit chainload-provider autotools fortran-2
FORTRAN_NEED_OPENMP=1

DESCRIPTION="high-performance object-based library for DLA computations"
HOMEPAGE="https://github.com/flame/libflame"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/flame/libflame"
else
	COMMIT=b112dd8f0d917aa1f19747a61e01f83758692b7f
	SRC_URI="https://github.com/flame/libflame/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}"/${PN}-${COMMIT}
	KEYWORDS="~amd64"
fi

LICENSE="BSD"
SLOT="0"

CPU_FLAGS=( sse3 )
IUSE_CPU_FLAGS_X86="${CPU_FLAGS[@]/#/cpu_flags_x86_}"
IUSE="scc static-libs supermatrix test ${IUSE_CPU_FLAGS_X86[@]}"
RESTRICT="!test? ( test )"

RDEPEND="
	!sci-libs/libflame-amd
"
BDEPEND="dev-vcs/git"

src_prepare() {
	default

	# link to shared during testing
	# need both blas and cblas
	sed -e "/libflame\.a/s/^/#/" \
	    -e "/libflame\.so/s/#//" \
	    -e "/^LIBBLAS\s/s/^.*$/LIBBLAS := -lblas -lcblas/" \
	    -i test/Makefile || die
}

src_configure() {
	local myconf=(
		--disable-optimizations
		--enable-multithreading=openmp
		--enable-verbose-make-output
		--enable-lapack2flame
		--enable-cblas-interfaces
		--enable-max-arg-list-hack
		--enable-dynamic-build
		--enable-vector-intrinsics=$(usex cpu_flags_x86_sse3 sse none)
		$(use_enable static-libs static-build)
		$(use_enable scc)
		$(use_enable supermatrix)
	)
	econf "${myconf[@]}"
}

src_compile() {
	default
	provider-link-lib "liblapack.so.3" "-Llib/${CHOST} -lflame"

	use test && emake -Ctest
}

src_test() {
	cd test
	LD_LIBRARY_PATH="../lib/${CHOST}" ./test_libflame.x
}

src_install() {
	emake -j1 DESTDIR="${D}" install
	dodir /usr/include/flame
	provider-install-lib "liblapack.so.3"
}
