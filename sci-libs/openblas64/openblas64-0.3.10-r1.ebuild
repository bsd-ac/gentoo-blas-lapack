# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PROVIDER_NAME=openblas64
PROVIDER_LIBS="blas64 lapack64"
inherit chainload-provider flag-o-matic fortran-2 toolchain-funcs

DESCRIPTION="Optimized BLAS library based on GotoBLAS2"
HOMEPAGE="http://xianyi.github.com/OpenBLAS/"
SRC_URI="https://github.com/xianyi/OpenBLAS/archive/v${PV}.tar.gz -> openblas-${PV}.tar.gz"
S="${WORKDIR}"/OpenBLAS-${PV}

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux ~x64-macos ~x86-macos"
IUSE="dynamic openmp pthread relapack static-libs test"
REQUIRED_USE="?? ( openmp pthread )"
RESTRICT="!test? ( test )"

BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}/${PN}-0.3.10-dont-clobber-fflags.patch"
)

pkg_pretend() {
	elog "This software has a massive number of options that"
	elog "are configurable and it is *impossible* for all of"
	elog "those to fit inside any manageable ebuild."
	elog "The Gentoo provided package has enough to build"
	elog "a fully optimized library for your targeted CPU."
	elog "You can set the CPU target using the environment"
	elog "variable - OPENBLAS_TARGET or it will be detected"
	elog "automatically from the target toolchain (supports"
	elog "cross compilation toolchains)."
	elog "You can control the maximum number of threads"
	elog "using OPENBLAS_NTHREAD, default=64 and number of "
	elog "parallel calls to allow before further calls wait"
	elog "using OPENBLAS_NPARALLEL, default=8."
}

pkg_setup() {
	fortran-2_pkg_setup

	# List of most configurable options - Makefile.rule

	# https://github.com/xianyi/OpenBLAS/pull/2663
	tc-export CC FC LD AR AS RANLIB

	# HOSTCC is used for scripting
	export HOSTCC=$(tc-getBUILD_CC)

	# threading options
	use openmp && tc-check-openmp
	USE_THREAD=0
	if use openmp; then
		USE_THREAD=1; USE_OPENMP=1;
	elif use pthread; then
		USE_THREAD=1; USE_OPENMP=0;
	fi
	export USE_THREAD USE_OPENMP

	# We need to filter these while building the library, and not just
	# while building the test suite. Will hopefully get fixed upstream:
	# https://github.com/xianyi/OpenBLAS/issues/2657
	use test && filter-flags "-fbounds-check" "-fcheck=bounds" "-fcheck=all"

	# disable submake with -j and default optimization flags
	# in Makefile.system
	# Makefile.rule says to not modify COMMON_OPT/FCOMMON_OPT...
	export MAKE_NB_JOBS=-1 \
	       COMMON_OPT=" " \
	       FCOMMON_OPT=" "

	# Target CPU ARCH options
	# generally detected automatically from cross toolchain
	use dynamic && \
		export DYNAMIC_ARCH=1 \
		       TARGET=GENERIC \
		       NO_AFFINITY=1 \
		       TARGET=GENERIC

	export NUM_PARALLEL=${OPENBLAS_NPARALLEL:-8} \
	       NUM_THREADS=${OPENBLAS_NTHREAD:-64}

	# setting OPENBLAS_TARGET to override auto detection
	# in case the toolchain is not enough to detect
	# https://github.com/xianyi/OpenBLAS/blob/develop/TargetList.txt
	if ! use dynamic && [[ ! -z "${OPENBLAS_TARGET}" ]] ; then
		export TARGET="${OPENBLAS_TARGET}"
	fi

	if ! use static-libs; then
		export NO_STATIC=1
	else
		export NO_STATIC=0
	fi

	BUILD_RELAPACK=1
	if ! use relapack; then
		BUILD_RELAPACK=0
	fi

	export PREFIX="${EPREFIX}/usr" BUILD_RELAPACK

	### for blas64 bit
	export INTERFACE64=1
}

src_prepare() {
	# disable tests by default
	sed -e "/all ::/s/tests //" -i Makefile || die
	# change soname to libopenblas64.so
	sed -e "/^LIBNAMEBASE =/s/openblas/openblas64/" \
	    -i Makefile.system || die
	default
}

src_compile() {
	default

	provider-link-c "libblas64.so.3" "-L. -lopenblas64"
	provider-link-c "libcblas64.so.3" "-L. -lopenblas64"
	provider-link-c "liblapack64.so.3" "-L. -lopenblas64"
	provider-link-c "liblapacke64.so.3" "-L. -lopenblas64"
}

src_test() {
	emake tests
}

src_install() {
	local libdir=$(get_libdir)
	emake install DESTDIR="${D}" \
	              OPENBLAS_INCLUDE_DIR='$(PREFIX)'/include/${PN} \
	              OPENBLAS_LIBRARY_DIR='$(PREFIX)'/${libdir}

	dodoc GotoBLAS_*.txt *.md Changelog.txt

	# fix package files to move to openblas64
	sed -e "/-lopenblas/s/openblas/openblas64/" \
	    -e "/Name: /s/openblas/openblas64/" \
	    -e "/openblas_/s/openblas/openblas64/" \
	    -i "${ED}"/usr/${libdir}/pkgconfig/openblas.pc  || die
	sed -e "s/OpenBLAS/OpenBLAS64/g" \
	    -i "${ED}"/usr/${libdir}/cmake/openblas/OpenBLASConfig.cmake  || die
	mv "${ED}"/usr/${libdir}/pkgconfig/openblas{,64}.pc || die
	mv "${ED}"/usr/${libdir}/cmake/openblas/OpenBLAS{,64}Config.cmake || die
	mv "${ED}"/usr/${libdir}/cmake/openblas/OpenBLAS{,64}ConfigVersion.cmake || die
	mv "${ED}"/usr/${libdir}/cmake/openblas{,64} || die

	provider-install-lib "libblas64.so.3"
	provider-install-lib "libcblas64.so.3" "/usr/$(get_libdir)/blas64/openblas64"
	provider-install-lib "liblapack64.so.3"
	provider-install-lib "liblapacke64.so.3" "/usr/$(get_libdir)/lapack64/openblas64"
}
