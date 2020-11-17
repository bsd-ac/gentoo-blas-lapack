CXX =      c++
FC =       gfortran
PYTHON =   python3

all: blas cblas

blas: blas.f90
	$(FC) $(FFLAGS) -o blas blas.f90 $(LDFLAGS) -lblas

cblas: cblas.cc
	$(CXX) $(CFLAGS) -o cblas cblas.cc $(LDFLAGS) -lcblas

run: blas cblas
	$$(time ./blas)
	$$(time ./cblas)
	$$(time $(PYTHON) blas.py)

clean:
	rm -f cblas blas
