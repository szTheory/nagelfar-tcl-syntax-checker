#----------------------------------------------------------------------
# Make file for Nagelfar
#----------------------------------------------------------------------

# This string is used to generate release file names
VERSION = 131
# This string is used to show the version number in the source
DOTVERSION = 1.3.1

# Path to the TclKits used for creating StarPacks.
TCLKIT = /home/$(USER)/tclkit
TCLKIT85_LINUX = $(TCLKIT)/v85/tclkit-linux
TCLKIT85_WIN   = $(TCLKIT)/v85/tclkit-win32.upx.exe
TCLKITSH85_WIN = $(TCLKIT)/v85/tclkitsh-win32.upx.exe

# Path to the libraries used
TKDND   = /home/$(USER)/src/packages/tkdnd/lib/tkdnd2.4
#CTEXT   = /home/$(USER)/src/ctext
TEXTSEARCH = /home/$(USER)/src/textsearch

# Path to the interpreter used for generating the syntax database
TCLSHDB  = ~/tcl/install/bin/wish8.6
DB1NAME  = syntaxdb86.tcl
TCLSHDB2 = ~/tcl/install/bin/wish8.5
DB2NAME  = syntaxdb85.tcl
TCLSHDB3 = ~/tcl/install/bin/wish8.7
DB3NAME  = syntaxdb87.tcl
# Path to the interpreter used for running tests
TCLSH85  = ~/tcl/install/bin/tclsh8.5
TCLSH86  = ~/tcl/install/bin/tclsh8.6
TCLSH87  = ~/tcl/install/bin/tclsh8.7

all: base

base: nagelfar.tcl setup misctest web doc db

# Target to update minimum stuff, that needs less environment
min: nagelfar.tcl misctest

#----------------------------------------------------------------
# Setup symbolic links from the VFS to the real files
#----------------------------------------------------------------

#nagelfar.vfs/lib/app-nagelfar/nagelfar.tcl:
#	cd nagelfar.vfs/lib/app-nagelfar ; ln -s ../../../nagelfar.tcl
#nagelfar.vfs/lib/app-nagelfar/syntaxdb.tcl:
#	cd nagelfar.vfs/lib/app-nagelfar ; ln -s ../../../syntaxdb.tcl
#nagelfar.vfs/lib/app-nagelfar/packagedb:
#	cd nagelfar.vfs/lib/app-nagelfar ; ln -s ../../../packagedb
nagelfar.vfs/lib/tkdnd:
	cd nagelfar.vfs/lib ; ln -s $(TKDND) tkdnd
#nagelfar.vfs/lib/ctext:
#	cd nagelfar.vfs/lib ; ln -s $(CTEXT) ctext
nagelfar.vfs/lib/textsearch:
	cd nagelfar.vfs/lib ; ln -s $(TEXTSEARCH) textsearch

links: nagelfar.vfs/lib/tkdnd \
	nagelfar.vfs/lib/textsearch

setup: links

#----------------------------------------------------------------
# Concatening source
#----------------------------------------------------------------

FILES1 = src/prologue.tcl
FILES2 = src/nagelfar.tcl src/gui.tcl src/dbbrowser.tcl \
	src/registry.tcl src/preferences.tcl src/plugin.tcl src/startup.tcl
SRCFILES = $(FILES1) $(FILES2)
CATFILES = $(FILES1) catversion.txt $(FILES2)

nagelfar.tcl: $(SRCFILES)
	echo "set version \"Version $(DOTVERSION) `date --iso-8601`\"" > catversion.txt
	cat $(CATFILES) | sed "s/\\\$$Revision\\\$$/`git show-ref --hash --heads master`/" > nagelfar.tcl
	@chmod 775 nagelfar.tcl
	@rm catversion.txt

#----------------------------------------------------------------
# Testing
#----------------------------------------------------------------

spell:
	@cat doc/*.txt | ispell -d british -l | sort -u

# Note: Nagelfar promises to run in 8.5 so that database is used for check.

# Create a common "header" file for all source files.
nagelfar_h.syntax: nagelfar.tcl nagelfar.syntax $(SRCFILES)
	@echo Creating syntax header file...
	@./nagelfar.tcl -s $(DB2NAME) -header nagelfar_h.syntax nagelfar.syntax $(SRCFILES)

check: nagelfar.tcl nagelfar_h.syntax
	@./nagelfar.tcl -s $(DB2NAME) -strictappend -plugin nfplugin.tcl nagelfar_h.syntax $(SRCFILES)

test: clean base
	@$(TCLSH86) ./tests/all.tcl -notfile gui.test $(TESTFLAGS)

testgui: base
	@$(TCLSH86) ./tests/all.tcl -file gui.test $(TESTFLAGS)

test85: base
	@$(TCLSH85) ./tests/all.tcl -notfile gui.test $(TESTFLAGS)

testoo: base
	@./nagelfar.tcl -s syntaxdb.tcl -s snitdb.tcl ootest/*.tcl

#----------------------------------------------------------------
# Coverage
#----------------------------------------------------------------

# Source files for code coverage
IFILES   = $(SRCFILES:.tcl=.tcl_i)
LOGFILES = $(SRCFILES:.tcl=.tcl_log)
LOCKFILES = $(SRCFILES:.tcl=.tcl_log.lck)
MFILES   = $(SRCFILES:.tcl=.tcl_m)

# Instrument source file for code coverage
%.tcl_i: %.tcl
	@./nagelfar.tcl -instrument $<

# Target to prepare for code coverage run. Makes sure log file is clear.
instrument: base $(IFILES) nagelfar.tcl_i
	@rm -f $(LOGFILES)

# Top file for coverage run
nagelfar_dummy.tcl: $(IFILES)
	@rm -f nagelfar_dummy.tcl
	@touch nagelfar_dummy.tcl
	@cat src/prologue.tcl >> nagelfar_dummy.tcl
	@for i in $(SRCFILES) ; do echo "source $$i" >> nagelfar_dummy.tcl ; done

# Top file for coverage run
nagelfar.tcl_i: nagelfar_dummy.tcl_i
	@cp -f nagelfar_dummy.tcl_i nagelfar.tcl_i
	@chmod 775 nagelfar.tcl_i

# Run tests to create log file.
testcover $(LOGFILES): nagelfar.tcl_i
	@./tests/all.tcl $(TESTFLAGS)
	@$(TCLSH86) ./tests/all.tcl -notfile gui.test -match expand-*

# Create markup file for better view of result
%.tcl_m: %.tcl_log 
	@./nagelfar.tcl -markup $*.tcl

# View code coverage result
markup: $(MFILES)
icheck: $(MFILES)
	@for i in $(SRCFILES) ; do eskil -noparse $$i $${i}_m & done

# Remove code coverage files
clean:
	@rm -f $(LOGFILES) $(IFILES) $(MFILES) $(LOCKFILES)
	@rm -f nagelfar.tcl_* nagelfar_dummy* _testfile_*

#----------------------------------------------------------------
# Generating test examples
#----------------------------------------------------------------

misctests/test.result: misctests/test.tcl nagelfar.tcl
	@cd misctests; ../nagelfar.tcl test.tcl > test.result

misctests/test.html: misctests/test.tcl misctests/htmlize.tcl \
		misctests/test.result
	@cd misctests; ./htmlize.tcl

misctest: misctests/test.result misctests/test.html

#----------------------------------------------------------------
# Documentation
#----------------------------------------------------------------

RSTFILES = $(wildcard websrc/*.rst) websrc/conf.py

doc/plugins.txt : $(RSTFILES)
	make -C websrc text
	cp websrc/_build/text/plugins.txt doc
	cp websrc/_build/text/codecoverage.txt doc
	cp websrc/_build/text/messages.txt doc
	cp websrc/_build/text/call-by-name.txt doc
	cp websrc/_build/text/inlinecomments.txt doc
	cp websrc/_build/text/syntaxtokens.txt doc
	cp websrc/_build/text/syntaxdatabases.txt doc

doc: doc/plugins.txt

#----------------------------------------------------------------
# Web pages
#----------------------------------------------------------------

web/htdocs/index.html : $(RSTFILES)
	make -C websrc html
	@mkdir -p web/htdocs
	cp -r $(wildcard websrc/_build/html/*) web/htdocs

web/cgi-bin/cginf.tcl: nagelfar.tcl syntaxdb.tcl cgibase.tcl cgibuild.tcl
	@mkdir -p web/cgi-bin
	./cgibuild.tcl

web: web/cgi-bin/cginf.tcl web/htdocs/index.html

webt: web
	rsync -e ssh -r web/htdocs web/cgi-bin pspjuth@web.sourceforge.net:/home/project-web/nagelfar/

#----------------------------------------------------------------
# Generating database
#----------------------------------------------------------------

syntaxdb.tcl: syntaxbuild.tcl $(TCLSHDB)
	$(TCLSHDB) syntaxbuild.tcl syntaxdb.tcl
	cp syntaxdb.tcl $(DB1NAME)

$(DB2NAME): syntaxbuild.tcl $(TCLSHDB2)
	$(TCLSHDB2) syntaxbuild.tcl $(DB2NAME)

$(DB3NAME): syntaxbuild.tcl $(TCLSHDB3)
	$(TCLSHDB3) syntaxbuild.tcl $(DB3NAME)

db: syntaxdb.tcl $(DB2NAME) $(DB3NAME)

#----------------------------------------------------------------
# Packaging/Releasing
#----------------------------------------------------------------

force: base
	make -B nagelfar.tcl
.phony: force

wrap: base
	sdx wrap nagelfar.kit

wrapexe: base
	@\rm -f nagelfar nagelfar.exe nagelfar_sh.exe
	sdx wrap nagelfar.linux   -runtime $(TCLKIT85_LINUX)
	sdx wrap nagelfar.exe     -runtime $(TCLKIT85_WIN)
	sdx wrap nagelfar.shexe   -runtime $(TCLKITSH85_WIN)
	mv nagelfar.shexe nagelfar_sh.exe

distrib: base
	@\rm -f nagelfar.tar.gz
	@ln -s . nagelfar$(VERSION)
	@mkdir -p lib
	@ln -sf $(TEXTSEARCH) lib/textsearch
	@tar --exclude .svn -cvf nagelfar.tar nagelfar$(VERSION)/COPYING \
		nagelfar$(VERSION)/README.txt nagelfar$(VERSION)/syntaxbuild.tcl \
		nagelfar$(VERSION)/syntaxdb85.tcl \
		nagelfar$(VERSION)/syntaxdb86.tcl \
		nagelfar$(VERSION)/syntaxdb.tcl \
		nagelfar$(VERSION)/syntaxdb87.tcl \
		nagelfar$(VERSION)/nagelfar.syntax nagelfar$(VERSION)/nagelfar.tcl \
		nagelfar$(VERSION)/misctests/test.tcl nagelfar$(VERSION)/misctests/test.syntax \
		nagelfar$(VERSION)/doc nagelfar$(VERSION)/packagedb
	@tar --exclude .svn --exclude CVS -rvhf nagelfar.tar \
		nagelfar$(VERSION)/lib
	@gzip nagelfar.tar
	@\rm lib/textsearch
	@\rm nagelfar$(VERSION)

release: force distrib wrap wrapexe
	@cp nagelfar.tar.gz nagelfar`date +%Y%m%d`.tar.gz
	@mv nagelfar.tar.gz nagelfar$(VERSION).tar.gz
	@gzip nagelfar.linux
	@mv nagelfar.linux.gz nagelfar$(VERSION).linux.gz
	@zip nagelfar$(VERSION).win.zip nagelfar.exe
	@zip nagelfar_sh$(VERSION).win.zip nagelfar_sh.exe
	@cp nagelfar.kit nagelfar`date +%Y%m%d`.kit
	@cp nagelfar.kit nagelfar$(VERSION).kit

upload:
	rsync -e ssh README nagelfar$(VERSION).tar.gz nagelfar$(VERSION).kit nagelfar$(VERSION).linux.gz nagelfar$(VERSION).win.zip nagelfar_sh$(VERSION).win.zip pspjuth@frs.sourceforge.net:/home/frs/project/nagelfar/Rel_$(VERSION)/
