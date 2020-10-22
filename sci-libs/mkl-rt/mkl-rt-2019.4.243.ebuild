# Copyright 2019-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PROVIDER_NAME=mkl-rt
PROVIDER_BLAS=1
PROVIDER_LAPACK=1
PROVIDER_LAPACKE=1
inherit blas-lapack-provider

DESCRIPTION="Intel Math Kernel Library (Runtime)"
HOMEPAGE="https://software.intel.com/en-us/mkl"
SRC_URI="https://repo.continuum.io/pkgs/main/linux-64/mkl-2019.4-243.tar.bz2 -> ${P}.tar.bz2"

LICENSE="ISSL" # https://software.intel.com/en-us/mkl/license-faq
SLOT="0"
KEYWORDS="~amd64"

# MKL uses Intel/LLVM OpenMP by default.
# One can change the threadding layer to "gnu" or "tbb" through the MKL_THREADING_LAYER env var.
RDEPEND="
	>=app-eselect/eselect-blas-0.2
	sys-libs/libomp
"

S=${WORKDIR}

src_install() {
	dolib.so lib/*.so

	dodir /usr/$(get_libdir)/blas/mkl-rt
	dosym ../../libmkl_rt.so usr/$(get_libdir)/blas/mkl-rt/libblas.so
	dosym ../../libmkl_rt.so usr/$(get_libdir)/blas/mkl-rt/libblas.so.3
	dosym ../../libmkl_rt.so usr/$(get_libdir)/blas/mkl-rt/libcblas.so
	dosym ../../libmkl_rt.so usr/$(get_libdir)/blas/mkl-rt/libcblas.so.3
	dosym ../../libomp.so    usr/$(get_libdir)/blas/mkl-rt/libiomp5.so
	dodir /usr/$(get_libdir)/lapack/mkl-rt
	dosym ../../libmkl_rt.so usr/$(get_libdir)/lapack/mkl-rt/liblapack.so
	dosym ../../libmkl_rt.so usr/$(get_libdir)/lapack/mkl-rt/liblapack.so.3
	dosym ../../libmkl_rt.so usr/$(get_libdir)/lapack/mkl-rt/liblapacke.so
	dosym ../../libmkl_rt.so usr/$(get_libdir)/lapack/mkl-rt/liblapacke.so.3
	dosym ../../libomp.so    usr/$(get_libdir)/lapack/mkl-rt/libiomp5.so
}
