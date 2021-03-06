# -*- Makefile -*-

# --------------------------------------------------------------------
BASIC=prims-fake.fs basetypes-fake.fs profiling.fs char.fsi char.fs string.fsi string.fs list.fsi \
  list.fs util.fsi util.fs bytes.fsi bytes.fs range.fsi range.fs getoptsimple.fsi \
  getoptsimple.fs platform.fsi platform.fs version.fsi version.fs options.fsi options.fs \
  unionfind.fsi unionfind.fs ident.fs const.fs
BASIC_SRC=$(addprefix basic/, $(BASIC))

ABSYN=syntax.fs const.fs visit.fs util.fs print.fs
ABSYN_SRC=$(addprefix absyn/, $(ABSYN))

SYNTAX=syntax.fsi syntax.fs const.fs subst.fsi subst.fs free.fsi free.fs instfv.fsi instfv.fs util.fs print.fsi print.fs
SYNTAX_SRC=$(addprefix syntax/, $(SYNTAX))

FORMAT=format.fsi format.fs
FORMAT_SRC=$(addprefix format/, $(FORMAT))

EXTRACTION=ml-syntax.fs env.fs uenv.fs util.fs codegen.fsi codegen.fs extracttyp.fs extractexp.fs extractmod.fs term.fs modul.fs
EXTRACTION_SRC=$(addprefix extraction/, $(EXTRACTION))

PARSER=ast.fs parseutil.fs parse.fs lexhelp.fs lex.fs dsenv.fsi dsenv.fs desugar.fsi desugar.fs env.fsi env.fs interleave.fs tosyntax.fsi tosyntax.fs parseit.fsi parseit.fs driver.fs dep.fs
PARSER_SRC=$(addprefix parser/, $(PARSER))

PARSER_NOGEN=ast.fs parseutil.fs parse.fsy lexhelp.fs lex.fsl dsenv.fs desugar.fs env.fs tosyntax.fs parseit.fsi parseit.fs driver.fs dep.fs
PARSER_NOGEN_SRC=$(addprefix parser/, $(PARSER_NOGEN))

TOSMT=term.fsi term.fs z3.fs splitcases.fs encode.fs
TOSMT_SRC=$(addprefix tosmt/, $(TOSMT))

SMTENCODING=term.fsi term.fs z3.fs splitcases.fs errorReporting.fs encode.fs
SMTENCODING_SRC=$(addprefix smtencoding/, $(SMTENCODING))

TC=tcenv.fsi tcenv.fs recheck.fs normalize.fsi normalize.fs errors.fs rel.fsi rel.fs tcutil.fsi tcutil.fs tc.fs
TC_SRC=$(addprefix tc/, $(TC))

TYPECHECKER=common.fs env.fsi env.fs normalize.fsi normalize.fs errors.fs rel.fsi rel.fs util.fsi util.fs tc.fsi tc.fs
TYPECHECKER_SRC=$(addprefix typechecker/, $(TYPECHECKER))

TOPLEVEL=dependences.fs interactive.fs stratified.fs universal.fs fstar.fs
TOPLEVEL_SRC=$(addprefix fstar/, $(TOPLEVEL))

# --------------------------------------------------------------------
LIB=../lib
BIN=../bin

# --------------------------------------------------------------------
PLATFORM       =
RELEASE       ?= Debug
BUILD_VERSION  =
FSCOTHERFLAGS    := --optimize+ --debug:full --nologo --crossoptimize+ --define:DEBUG
FSCOTHERFLAGS    += --mlcompatibility $(addprefix --define:, $(BUILD_VERSION))

ALL_DLLS    = basic.dll format.dll absyn.dll extraction.dll parser.dll tc.dll tosmt.dll syntax.dll smtencoding.dll typechecker.dll
FSHARP_LIBS = System.Runtime.Serialization.dll System.Xml.dll $(BIN)/FSharp.PowerPack.dll $(BIN)/FSharp.PowerPack.Compatibility.dll $(BIN)/FSharp.PPrint.dll
OTHER_DLLS  =
BASELIBS    = $(addprefix -r , $(FSHARP_LIBS) $(OTHER_DLLS))

# --------------------------------------------------------------------
ifeq ($(PLATFORM), X86)
override FSCOTHERFLAGS += --platform:x86
endif

ifeq ($(OS),Windows_NT)
FSC     = fsc
MSBUILD = msbuild
else
FSC     = fsharpc
MSBUILD = xbuild
endif

MSBUILD := $(MSBUILD) /verbosity:normal

# --------------------------------------------------------------------
ifeq ($(OS),Windows_NT)
RUNTIME =
else
RUNTIME = mono
endif

FSLYDIR := VS/packages/FsLexYacc.6.1.0
FSYACC  := $(RUNTIME) $(FSLYDIR)/build/fsyacc.exe
FSLEX   := $(RUNTIME) $(FSLYDIR)/build/fslex.exe

# --------------------------------------------------------------------
.PHONY: all z3_x86 z3_x64 wc clean tidy boot ocaml
.PHONY: msbuild msbuild-clean nuget-restore nuget-clean

# --------------------------------------------------------------------
all: $(BIN)/fstar.exe $(BIN)/tests.exe

# --------------------------------------------------------------------
z3-x86:
	cp $(BIN)/Microsoft.Z3.x86.dll $(BIN)/Microsoft.Z3.dll
	cp $(BIN)/z3.x86.dll $(BIN)/z3.dll

z3-x64:
	cp $(BIN)/Microsoft.Z3.x64.dll $(BIN)/Microsoft.Z3.dll
	cp $(BIN)/z3.x64.dll $(BIN)/z3.dll

# --------------------------------------------------------------------

nuget-restore:
	$(RUNTIME) VS/.nuget/NuGet.exe restore VS/FStar.sln

nuget-clean:
	rm -r VS/packages

$(FSYACC) $(FSLEX): nuget-restore

# --------------------------------------------------------------------
msbuild: nuget-restore
	$(MAKE) -C VS install-packages
	$(MSBUILD) VS/FStar.sln

msbuild-clean:
	$(MSBUILD) /t:clean VS/FStar.sln

# --------------------------------------------------------------------
parser/parse.fs: parser/parse.fsy $(FSYACC)
	$(FSYACC) --module FStar.Parser.Parse $<

parser/lex.fs: parser/lex.fsl $(FSLEX)
	$(FSLEX) --unicode $<

BASIC_DEPS=
$(BIN)/basic.dll: $(BASIC_DEPS) $(BASIC_SRC)
	$(FSC)  $(FSCOTHERFLAGS) -a -o $@ $(BASELIBS) $(addprefix -r , $(BASIC_DEPS)) $(BASIC_SRC)

ABSYN_DEPS=$(addprefix $(BIN)/, basic.dll)
$(BIN)/absyn.dll: $(ABSYN_DEPS) $(ABSYN_SRC)
	$(FSC)  $(FSCOTHERFLAGS) -a -o $@ $(BASELIBS) $(addprefix -r , $(ABSYN_DEPS)) $(ABSYN_SRC)

SYNTAX_DEPS=$(addprefix $(BIN)/, basic.dll)
$(BIN)/syntax.dll: $(SYNTAX_DEPS) $(SYNTAX_SRC)
	$(FSC)  $(FSCOTHERFLAGS) -a -o $@ $(BASELIBS) $(addprefix -r , $(SYNTAX_DEPS)) $(SYNTAX_SRC)

$(BIN)/testAbsyn.exe: $(ABSYN_DEPS) $(ABSYN_SRC) absyn/test.fs
	$(FSC)  $(FSCOTHERFLAGS) --define:TEST --define:DEBUG -o $@ $(BASELIBS) $(addprefix -r , $(ABSYN_DEPS)) $(ABSYN_SRC) absyn/test.fs

FORMAT_DEPS=
$(BIN)/format.dll: $(FORMAT_DEPS) $(FORMAT_SRC)
	$(FSC) $(FSCOTHERFLAGS) -a -o $@ $(BASELIBS) $(addprefix -r , $(FORMAT_DEPS)) $(FORMAT_SRC)

EXTRACTION_DEPS=$(addprefix $(BIN)/, basic.dll absyn.dll syntax.dll format.dll tc.dll typechecker.dll)
$(BIN)/extraction.dll: $(EXTRACTION_DEPS) $(EXTRACTION_SRC)
	$(FSC) $(FSCOTHERFLAGS) -a -o $@ $(BASELIBS) $(addprefix -r , $(EXTRACTION_DEPS)) $(EXTRACTION_SRC)

PARSER_DEPS=$(addprefix $(BIN)/, basic.dll absyn.dll tc.dll syntax.dll typechecker.dll)
$(BIN)/parser.dll: $(PARSER_DEPS) $(PARSER_SRC)
	$(FSC)  $(FSCOTHERFLAGS) -a -o $@ $(BASELIBS) $(addprefix -r , $(PARSER_DEPS)) $(PARSER_SRC)

TOSMT_DEPS=$(addprefix $(BIN)/, basic.dll absyn.dll tc.dll)
$(BIN)/tosmt.dll: $(TOSMT_DEPS) $(TOSMT_SRC)
	$(FSC)  $(FSCOTHERFLAGS) -a -o $@ $(BASELIBS) $(addprefix -r , $(TOSMT_DEPS)) $(TOSMT_SRC)

SMTENCODING_DEPS=$(addprefix $(BIN)/, basic.dll syntax.dll typechecker.dll)
$(BIN)/smtencoding.dll: $(SMTENCODING_DEPS) $(SMTENCODING_SRC)
	$(FSC)  $(FSCOTHERFLAGS) -a -o $@ $(BASELIBS) $(addprefix -r , $(SMTENCODING_DEPS)) $(SMTENCODING_SRC)

TC_DEPS=$(addprefix $(BIN)/, basic.dll absyn.dll)
$(BIN)/tc.dll: $(TC_DEPS) $(TC_SRC)
	$(FSC)  $(FSCOTHERFLAGS) -a -o $@ $(BASELIBS) $(addprefix -r , $(TC_DEPS)) $(TC_SRC)

TYPECHECKER_DEPS=$(addprefix $(BIN)/, basic.dll syntax.dll)
$(BIN)/typechecker.dll: $(TYPECHECKER_DEPS) $(TYPECHECKER_SRC)
	$(FSC)  $(FSCOTHERFLAGS) -a -o $@ $(BASELIBS) $(addprefix -r , $(TYPECHECKER_DEPS)) $(TYPECHECKER_SRC)

FSTAR_DEPS=$(addprefix $(BIN)/, $(ALL_DLLS))
$(BIN)/fstar.exe: $(FSTAR_DEPS) $(TOPLEVEL_SRC) fstar/main.fs $(BIN)/fstar-mono.sh
ifeq ($(OS),Windows_NT)
	$(FSC)  $(FSCOTHERFLAGS) -o $@ $(BASELIBS) $(addprefix -r , $(FSTAR_DEPS)) $(TOPLEVEL_SRC) fstar/main.fs
else
	$(FSC)  $(FSCOTHERFLAGS) -o $(BIN)/fstar-mono.exe $(BASELIBS) $(addprefix -r , $(FSTAR_DEPS)) $(TOPLEVEL_SRC) fstar/main.fs
	cp $(BIN)/fstar-mono.sh $(BIN)/fstar.exe
endif

TESTS_SRC=$(addprefix tests/, pars.fs util.fs norm.fs unif.fs test.fs)
$(BIN)/tests.exe: $(FSTAR_DEPS) $(TOPLEVEL_SRC) $(TESTS_SRC) $(BIN)/tests-mono.sh
ifeq ($(OS),Windows_NT)
	$(FSC)  $(FSCOTHERFLAGS) -o $@ $(BASELIBS) $(addprefix -r , $(FSTAR_DEPS)) $(TOPLEVEL_SRC) $(TESTS_SRC)
else
	$(FSC)  $(FSCOTHERFLAGS) -o $(BIN)/tests-mono.exe $(BASELIBS) $(addprefix -r , $(FSTAR_DEPS)) $(TOPLEVEL_SRC) $(TESTS_SRC)
	cp $(BIN)/tests-mono.sh $(BIN)/tests.exe
endif

wc: $(BASIC_SRC) $(ABSYN_SRC) $(PARSER_NOGEN_SRC) $(TC_SRC) $(TOSMT_SRC) $(FORMAT_SRC) $(EXTRACTION_SRC) fstar/fstar.fs
	sloccount $^

clean:
	rm -rf *.exe $(addprefix $(BIN)/, $(ALL_DLLS) fstar.exe) *~ *res
	rm -rf $(BIN)/*.pdb  $(BIN)/*.mdb $(BIN)/queries
	make -s -C ocaml-output clean

# --------------------------------------------------------------------
# Bootstrapping in OCaml
# --------------------------------------------------------------------

# JP: these modules are meant to be fsti's (realized in ML); but, the compiler
# currently works in non-universes mode so this is not possible. These files are
# in ulib/ as fstis, though, so the --no_extract argument will go away once the
# F* compiler bootstraps in universes.
NUM=FStar.Int8 FStar.UInt8 FStar.Int16 FStar.UInt16 FStar.Int32 FStar.UInt32 FStar.Int64 FStar.UInt64
STDLIB=$(addprefix $(LIB)/, allboot.fsti stboot.fsti list.fsti option.fsti \
  FStar.Float.fsti FStar.Char.fsti $(addsuffix .fst,$(NUM)) FStar.BaseTypes.fsti \
  FStar.Util.fsti FStar.GetOpt.fsti FStar.Unionfind.fsti)
BOOT_BASIC_FSTI=$(addprefix boot_fstis/, string.fsti bytes.fsti platform.fsti version.fsti range.fsti)
BOOT_BASIC_FS=$(addprefix basic/, options.fs ident.fs const.fs)
BOOT_PARSER=$(addprefix parser/, ast.fs dsenv.fs desugar.fs env.fs interleave.fs tosyntax.fs parse.fsti lexhelp.fs parseit.fsi driver.fs dep.fs)
BOOT_FORMAT=$(addprefix format/, formatml.fs)
BOOT_ALL=$(BOOT_BASIC_FS) $(BOOT_FORMAT) $(ABSYN_SRC) $(SYNTAX_SRC) $(TC_SRC) \
  $(TOSMT_SRC) $(BOOT_PARSER) $(TYPECHECKER_SRC) $(EXTRACTION_SRC) $(SMTENCODING_SRC) $(TOPLEVEL_SRC)

ALL_INTERFACES=$(STDLIB) $(BOOT_BASIC_FSTI)
ALL_SOURCES=FStar.Options.fst FStar.Ident.fst FStar.Const.fst \
	        FStar.Format.fst \
	    	FStar.Absyn.Syntax.fst FStar.Absyn.Const.fst FStar.Absyn.Visit.fst FStar.Absyn.Util.fst FStar.Absyn.Print.fst \
	    	FStar.Syntax.Syntax.fst FStar.Syntax.Const.fst FStar.Syntax.Subst.fst FStar.Syntax.Free.fst FStar.Syntax.InstFV.fst FStar.Syntax.Util.fst FStar.Syntax.Print.fst \
	    	FStar.Tc.Env.fst FStar.Tc.Recheck.fst FStar.Tc.Normalize.fst FStar.Tc.Errors.fst FStar.Tc.Rel.fst FStar.Tc.Util.fst FStar.Tc.Tc.fst \
	    	FStar.ToSMT.Term.fst FStar.ToSMT.Z3.fst FStar.ToSMT.SplitQueryCases.fst FStar.ToSMT.Encode.fst \
	    	FStar.TypeChecker.Common.fst FStar.TypeChecker.Env.fst FStar.TypeChecker.Normalize.fst FStar.TypeChecker.Errors.fst FStar.TypeChecker.Rel.fst FStar.TypeChecker.Util.fst FStar.TypeChecker.Tc.fst \
		FStar.Parser.AST.fst FStar.Parser.DesugarEnv.fst FStar.Parser.Desugar.fst FStar.Parser.Env.fst FStar.Parser.Interleave.fst FStar.Parser.ToSyntax.fst FStar.Parser.Parse.fsti FStar.Parser.Lexhelp.fst FStar.Parser.ParseIt.fsti FStar.Parser.Driver.fst FStar.Parser.Dep.fst \
		FStar.Extraction.ML.Syntax.fst FStar.Extraction.ML.Env.fst FStar.Extraction.ML.UEnv.fst FStar.Extraction.ML.Util.fst FStar.Extraction.ML.Code.fst FStar.Extraction.ML.ExtractTyp.fst FStar.Extraction.ML.ExtractExp.fst FStar.Extraction.ML.ExtractMod.fst FStar.Extraction.ML.Term.fst FStar.Extraction.ML.Modul.fst  \
	    	FStar.SMTEncoding.Term.fst FStar.SMTEncoding.Z3.fst FStar.SMTEncoding.SplitQueryCases.fst FStar.SMTEncoding.ErrorReporting.fst FStar.SMTEncoding.Encode.fst \
	    	FStar.Dependences.fst FStar.Interactive.fst FStar.Stratified.fst FStar.Universal.fst FStar.FStar.fst

ADMITTED_MODULES=System System.IO System.Text System.Diagnostics System.Collections.Generic Collections FStar.Heap FStar.ST FStar.All FStar.List FStar.Option FStar.Char FStar.String FStar.List FStar.Bytes FStar.Platform FStar.Util FStar.Version FStar.Getopt FStar.Range FStar.Unionfind FStar.Parser.ParseIt FStar.Parser.Parse
ADMITS=$(addprefix --admit_fsi , $(ADMITTED_MODULES))

FSTAROPTS=

all_boot_fsts:
	cp format/format.fsi format/formatml.fsi
	./tools/make_all_boot_fsts "$(BOOT_ALL)"

boot_fstis/%.fsti: basic/%.fsi
	cp $^ $@

boot_fsts/FStar.Parser.Parse.fsti: parser/parse.fsti
	cp $^ $@

boot_fsts/FStar.Parser.ParseIt.fsti: parser/parseit.fsi
	cp $^ $@

$(LIB)/FStar.Util.fsti: basic/util.fsi
	cat $^ | sed 's/open System.IO//g' | sed 's/type time.*/new type time/g' | sed 's/type smap.*/new type smap : Type -> Type/g' | sed 's/type out_channel.*/new type out_channel/g' | sed 's/type file_handle.*/new type file_handle/g' | sed 's/type stream_reader.*/new type stream_reader/g' | sed 's/type string_builder.*/new type string_builder/g' | sed 's/type proc.*/new type proc/g' | sed 's/type set.*/new type set:Type -> Type/g' > $@

$(LIB)/FStar.GetOpt.fsti: basic/getoptsimple.fsi
	cp $^ $@

$(LIB)/FStar.Unionfind.fsti: basic/unionfind.fsi
	cat $^ | sed 's/type cell.*//g' | sed 's/and contents.*//g' | sed 's/.*| Data.*//g' | sed 's/.*| Fwd.*//g' | sed 's/type uvar.*/new type uvar : Type -> Type/g' > $@

clean_ocaml_prep:
	rm -rf boot_fsts boot_fstis
	mkdir boot_fsts boot_fstis
	cp basic/bytes.fsti boot_fstis/

extract_ocaml_prep: all_boot_fsts

extract_ocaml: $(ALL_INTERFACES) $(addprefix boot_fsts/, $(ALL_SOURCES))
	../bin/fstar.exe --explicit_deps --use_native_int --eager_inference --lax --fs_typ_app \
	  $(addprefix --no_extract ,$(NUM)) --odir ocaml-output --MLish $(FSTAROPTS) --codegen OCaml $^

ocaml: clean_ocaml_prep extract_ocaml_prep extract_ocaml

ocaml-test: ocaml boot-ocaml

boot-ocaml:
	make -C ocaml-output

# --------------------------------------------------------------------
# Bootstrapping in F#
# --------------------------------------------------------------------

FS_SUPPORT_LIBS=native_int/prims.fs st.fs all.fs option.fs
FSTAR_SUPPORT_LIBS=char.fsi char.fs string.fsi string.fs list.fsi list.fs util.fsi util.fs platform.fsi platform.fs bytes.fsi bytes.fs range.fsi range.fs getoptsimple.fsi getoptsimple.fs version.fsi version.fs unionfind.fsi unionfind.fs
BOOT_FS_BASE=FStar.Options.fs
BOOT_FS_SYNTAX=FStar.Absyn.Syntax.fs FStar.Absyn.Const.fs FStar.Absyn.Visit.fs FStar.Absyn.Util.fs FStar.Absyn.Print.fs
BOOT_FS_TC=FStar.Tc.Env.fs FStar.Tc.Recheck.fs FStar.Tc.Normalize.fs FStar.Tc.Errors.fs FStar.Tc.Rel.fs FStar.Tc.Util.fs FStar.Tc.Tc.fs
BOOT_FS_PARSER=FStar.Parser.AST.fs parseutil.fs parse.fs FStar.Parser.Lexhelp.fs lex.fs FStar.Parser.DesugarEnv.fs FStar.Parser.Desugar.fs parseit.fs FStar.Parser.Driver.fs
BOOT_FS_TOSMT=FStar.ToSMT.Term.fs FStar.ToSMT.Z3.fs FStar.ToSMT.SplitQueryCases.fs FStar.ToSMT.Encode.fs
BOOT_FS_EXTRACTION=FStar.Extraction.ML.Syntax.fs FStar.Extraction.ML.Env.fs FStar.Extraction.ML.Util.fs FStar.Extraction.ML.Code.fs FStar.Extraction.ML.ExtractTyp.fs FStar.Extraction.ML.ExtractExp.fs FStar.Extraction.ML.ExtractMod.fs
BOOT_FS_FILES=FSharp.Format.fs $(BOOT_FS_BASE) $(BOOT_FS_SYNTAX) $(BOOT_FS_TC) $(BOOT_FS_PARSER) $(BOOT_FS_TOSMT) $(BOOT_FS_EXTRACTION) FStar.FStar.fs

boot-fsharp: fsharp-output fs plain-fs-files fsharp-output/fstar.exe

fsharp-output/fstar.exe: $(addprefix ../lib/fs/, $(FS_SUPPORT_LIBS)) $(addprefix basic/, $(FSTAR_SUPPORT_LIBS)) $(addprefix fsharp-output/, $(BOOT_FS_FILES) main.fs)
	$(FSC) --nowarn:0025 -o $@ $(BASELIBS) $(FSCOTHERFLAGS) $^

fs: $(BOOT_ALL)
	../bin/fstar.exe --explicit_deps --use_native_int --eager_inference --MLish --lax --fs_typ_app \
	  --odir fsharp-output $(FSTAROPTS) --codegen FSharp $(ADMITS) $^

fsharp-output: nuget-restore
	mkdir -p fsharp-output
	cp ../bin/FSharp.PowerPack.* fsharp-output

plain-fs-files: $(addprefix parser/, parseutil.fs parse.fs lex.fs parseit.fs) fstar/main.fs
	cp $^ fsharp-output/

deploy-boot-fs: fsharp-output/fstar.exe
	cp $^ ../bin

clean-boot-fs:
	rm -rf fsharp-output

# --------------------------------------------------------------------
# Testing
# --------------------------------------------------------------------

test:   clean $(BIN)/fstar.exe $(BIN)/tests.exe fsharp-regressions ocaml-test regressions

# The regressions to be run with a working F# build of F*
fsharp-regressions:
	$(BIN)/tests.exe

# The regressions to be run with a working OCaml build of F*
regressions:
	make -C ../lib
	make -C ../ulib
	make -C ../examples
	make -C ../examples/hello ocaml
	make -C ../ucontrib/CoreCrypto/ml/ test
	make -C ../examples/crypto clean rpc-test cnt-test
	make -C ../examples/wysteria a.out distclean

test_universes: ulib uexamples
	../bin/tests #all the unit tests

ulib:
	+make -C ../ulib

uexamples:
	+make -C ../examples univ

uregressions:
	+make test_universes | grep -i 'error\|Verif'

test.net: clean $(BIN)/fstar.exe boot
	make -C ../examples

test.diff:
	@make -s test | grep -v "^make\[" > .test.out
	@diff .test.out expected-test-output
	@echo "F* ok"

wc-boot:
	wc -l $(BOOT_ALL)
