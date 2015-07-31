all: CoreCrypto.cmxa

ifeq ($(OS),Windows_NT)
CC = i686-w64-mingw32-gcc
else
CC = gcc-5
endif

openssl_stub.o: openssl_stub.c
	ocamlopt -c -cc "$(CC) -I /usr/local/lib/ocaml -I /usr/include -lcrypto -lopenssl -fPIC -c" $<
#	ocamlopt -c -cclib -lcrypto -cclib -lopenssl $< -ccopt -static

dllopenssl_wrap.so: openssl_stub.o
	ocamlmklib  -o  openssl_wrap  $<

CoreCrypto.cmi: CoreCrypto.mli
	ocamlc -I ../../Platform/ml -c CoreCrypto.mli

CoreCrypto.cmo: CoreCrypto.ml openssl.cmi
	ocamlc -I ../../Platform/ml -c CoreCrypto.ml openssl.cmi

CoreCrypto.cma:  CoreCrypto.cmo  dllopenssl_wrap.so
	ocamlc -I ../../Platform/ml -a  -o $@  $<  -dllib -lopenssl_wrap

CoreCrypto.cmx: CoreCrypto.ml CoreCrypto.cmi
	ocamlopt -I ../../Platform/ml -c $<

CoreCrypto.cmxa: CoreCrypto.cmx  dllopenssl_wrap.so
	ocamlopt -I ../../Platform/ml -a  -o $@  $<  -cclib -lopenssl_wrap 

clean:
	rm -f *.[oa] *.so *.cm[ixoa] *.cmxa