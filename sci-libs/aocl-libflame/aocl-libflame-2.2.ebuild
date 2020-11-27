# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PROVIDER_NAME="aocl-libflame"
PROVIDER_LIBS=( "lapack" )
inherit library-provider chainload-provider fortran-2 toolchain-funcs
FORTRAN_NEED_OPENMP=1

DESCRIPTION="AMD optimized high-performance object-based library for DLA computations"
HOMEPAGE="https://developer.amd.com/amd-aocl/"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/amd/libflame"
else
	SRC_URI="https://github.com/amd/libflame/archive/${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}"/libflame-"${PV}"
	KEYWORDS="~amd64"
fi

LICENSE="BSD"
SLOT="0"

CPU_FLAGS=( sse3 )
IUSE_CPU_FLAGS_X86="${CPU_FLAGS[@]/#/cpu_flags_x86_}"
IUSE="scc supermatrix test ${IUSE_CPU_FLAGS_X86[@]}"
RESTRICT="!test? ( test )"

RDEPEND="
	!sci-libs/libflame
"
BDEPEND="dev-vcs/git"

pkg_setup() {
	fortran-2_pkg_setup
	tc-export CC AR LD RANLIB
}

src_prepare() {
	default

	# link to shared during testing
	# need both blas and cblas
	sed -e "/libflame\.a/s/^/#/" \
	    -e "/libflame\.so/s/#//" \
	    -e "/^LIBBLAS\s/s/$/-lblas -lcblas/" \
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
		--disable-static-build
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
	mv "${ED}"/usr/include/{{lapacke,lapacke_mangling,lapack}.h,flame} || die
	provider-install-lib "liblapack.so.3"
}
