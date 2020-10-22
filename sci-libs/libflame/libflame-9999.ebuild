# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PROVIDER_NAME=libflame
PROVIDER_LAPACK=1
inherit blas-lapack-provider autotools fortran-2
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
IUSE="scc static-libs supermatrix ${IUSE_CPU_FLAGS_X86[@]}"

RDEPEND="
	!sci-libs/libflame-amd
"
BDEPEND="dev-vcs/git"

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
	provider-link_lapack "-Llib/${CHOST} -lflame"
}

src_install() {
	emake -j1 DESTDIR="${D}" install
	dodir /usr/include/flame
	#mv "${ED}"/usr/include/{{lapacke,lapacke_mangling,lapack}.h,flame} || die
	provider-install_libs
}
