
OCAMLCFLAGS=-c -bin-annot -safe-string -package ctypes.stubs -package bigarray -package bytes -w @5@8@10@11@12@14@23@24@26@29 -I lib_gen -I lib
OCAMLC=ocamlfind ocamlc
OCAMLOPT=ocamlfind ocamlopt

all: lib/ocaml-sodium.cma lib/ocaml-sodium.cmxa

lib_gen/sodium_typegen.byte: lib_gen/sodium_types.cmo lib_gen/sodium_typegen.cmo
	ocamlfind ocamlc -linkpkg -package ctypes.stubs lib_gen/sodium_types.cmo lib_gen/sodium_typegen.cmo -o lib_gen/sodium_typegen.byte

lib_gen/sodium_types_detect.c: lib_gen/sodium_typegen.byte
	lib_gen/sodium_typegen.byte


lib_gen/sodium_types_detect: lib_gen/sodium_types_detect.c
	cc -I `ocamlfind query ctypes` -I `ocamlc -where` -o lib_gen/sodium_types_detect lib_gen/sodium_types_detect.c

lib/sodium_types_detected.ml: lib_gen/sodium_types_detect
	lib_gen/sodium_types_detect > lib/sodium_types_detected.ml

lib_gen/sodium_bindgen.byte: lib/sodium_storage.cmo lib/sodium_types_detected.cmo lib_gen/sodium_bindings.cmo lib_gen/sodium_bindgen.cmo
	ocamlfind ocamlc -linkpkg -package ctypes.stubs lib/sodium_storage.cmo lib/sodium_types_detected.cmo lib_gen/sodium_types.cmo lib_gen/sodium_bindings.cmo lib_gen/sodium_bindgen.cmo -o lib_gen/sodium_bindgen.byte

lib/sodium_stubs.c lib/sodium_generated.ml: lib_gen/sodium_bindgen.byte
	lib_gen/sodium_bindgen.byte

lib/sodium_stubs.o: lib/sodium_stubs.c
	ocamlfind ocamlc -ccopt -I/usr/local/include -I `ocamlfind query ctypes` -ccopt '--std=c99 -Wall -pedantic -Werror -Wno-pointer-sign' -c lib/sodium_stubs.c && mv sodium_stubs.o lib/sodium_stubs.o

lib/sodium_bindings.ml: lib_gen/sodium_bindings.ml
	cp -p lib_gen/sodium_bindings.ml lib/sodium_bindings.ml

lib/sodium_types.ml: lib_gen/sodium_types.ml
	cp -p lib_gen/sodium_types.ml lib/sodium_types.ml

lib/sodium.cmo: lib/sodium.cmi

OBJ=lib/sodium_storage.cmo lib/sodium_types.cmo lib/sodium_types_detected.cmo lib/sodium_bindings.cmo lib/sodium_generated.cmo lib/sodium.cmo
OBJOPT=$(OBJ:.cmo=.cmx)

lib/ocaml-sodium.cma lib/ocaml-sodium.cmxa: lib/sodium_stubs.o $(OBJ) $(OBJOPT)
	ocamlfind ocamlmklib -verbose -o lib/ocaml-sodium $(OBJ) $(OBJOPT) lib/sodium_stubs.o -lsodium

test:: lib_test/nacl_runner lib_test/test_sodium.byte lib_test/test_sodium.native
	lib_test/test_sodium.byte
	lib_test/test_sodium.native

lib_test/nacl_runner: lib_test/nacl_runner.c
	cc -Wall -g  -o lib_test/nacl_runner lib_test/nacl_runner.c -lsodium

TESTML= \
  lib_test/test_auth.ml \
  lib_test/test_box.ml \
  lib_test/test_generichash.ml \
  lib_test/test_hash.ml \
  lib_test/test_random.ml \
  lib_test/test_scalar_mult.ml \
  lib_test/test_secret_box.ml \
  lib_test/test_sign.ml \
  lib_test/test_stream.ml \
  lib_test/test_sodium.ml

lib_test/test_sodium.byte: $(TESTOBJ)
	ocamlfind ocamlc -linkpkg -package ctypes.stubs -package bigarray -package bytes -package sodium -package oUnit -I lib_test $(TESTML) -o lib_test/test_sodium.byte

lib_test/test_sodium.native: $(TESTOBJ)
	ocamlfind ocamlopt -linkpkg -package ctypes.stubs -package bigarray -package bytes -package sodium -package oUnit -I lib_test $(TESTML) -o lib_test/test_sodium.native

install:
	ocamlfind install sodium lib/META \
        lib/sodium.mli lib/sodium.cmi lib/sodium.cmti lib/ocaml-sodium.cma lib/ocaml-sodium.cmxa lib/ocaml-sodium.a lib/dllocaml-sodium.so lib/libocaml-sodium.a

uninstall:
	ocamlfind remove sodium

.SUFFIXES: .ml .mli .cmi .cmo .cmx

.ml.cmo:
	$(OCAMLC) -c $(OCAMLCFLAGS) -o $@ $<

.ml.cmx:
	$(OCAMLOPT) -c $(OCAMLCFLAGS) -o $@ $<

.mli.cmi:
	$(OCAMLC) -c $(OCAMLCFLAGS) -o $@ $<

clean:
	rm -f */*.byte */*.cm* */*.o */*.a */*.so lib_gen/sodium_types_detect* lib/sodium_stubs.c lib/sodium_generated.ml lib/sodium_types_detected.ml lib/sodium_bindings.ml lib/sodium_types.ml

lib/sodium_types_detected.ml: lib/sodium_types_detected.ml
