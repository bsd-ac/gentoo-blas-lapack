.PHONY: all run clean

all:
	$(CXX) -o blas_dlopen blas_dlopen.c -ldl -fpermissive

run:
	$$(time ./blas_dlopen)

clean:
	rm -f blas_dlopen
