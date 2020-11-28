.PHONY: all run clean

all:
	$(CXX) -o cblas_dlopen cblas_dlopen.cpp -ldl -fpermissive

run:
	$$(time ./cblas_dlopen)

clean:
	rm -f cblas_dlopen
