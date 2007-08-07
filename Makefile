#
# Makefile for gPodder
# Copyright 2005-2007 Thomas Perl <thp at perli net>
# License: see COPYING file
#

##########################################################################

BINFILE=bin/gpodder
GLADEFILE=data/gpodder.glade
GLADEGETTEXT=$(GLADEFILE).h
MESSAGESPOT=data/messages.pot
GUIFILE=src/gpodder/gui.py
LOGO_22=data/icons/22/gpodder.png
LOGO_24=data/icons/24/gpodder.png
MANPAGE=doc/man/gpodder.1
TEPACHE=./doc/dev/tepache
GPODDERVERSION=`cat $(BINFILE) |grep ^__version__.*=|cut -d\" -f2`

ROSETTA_FILES=$(MESSAGESPOT) data/po/*.po
ROSETTA_ARCHIVE=gpodder-rosetta-upload.tar.gz

CHANGELOG=ChangeLog
CHANGELOG_TMP=.ChangeLog.tmp
CHANGELOG_EDT=.ChangeLog.edit
EMAIL ?= $$USER@`hostname -f`

DESTDIR ?= /
PREFIX ?= /usr

# default editor of user has not set "EDITOR" env variable
EDITOR ?= vim

##########################################################################

all: help

help:
	@echo 'make test            run gpodder in local directory'
	@echo 'make cl              make new changelog entry (1)'
	@echo 'make release         create source tarball in "dist/"'
	@echo 'make install         install gpodder into "$(PREFIX)"'
	@echo 'make uninstall       uninstall gpodder from "$(PREFIX)"'
	@echo 'make generators      generate manpage, run tepache and resize logo'
	@echo 'make messages        rebuild messages.pot from new source'
	@echo 'make rosetta-upload  generate a tarball of all translation files'
	@echo 'make clean           remove generated+temp+*.pyc files'
	@echo 'make distclean       do a "make clean" + remove "dist/"'
	@echo ''
	@echo '(1) Please set environment variable "EMAIL" to your e-mail address'

##########################################################################

cl:
	(echo "`822-date` <$(EMAIL)>"; svn status | grep '^[MA]' | sed -e 's/^[MA] *\(.*\)/        * \1: /'; echo ""; cat $(CHANGELOG)) >$(CHANGELOG_TMP)
	cp $(CHANGELOG_TMP) $(CHANGELOG_EDT)
	$(EDITOR) $(CHANGELOG_EDT)
	diff -q $(CHANGELOG_TMP) $(CHANGELOG_EDT) || mv $(CHANGELOG_EDT) $(CHANGELOG)
	rm -f $(CHANGELOG_TMP) $(CHANGELOG_EDT)


##########################################################################

test:
	$(BINFILE) --local --verbose

deb:
	debuild

release: distclean
	python setup.py sdist

install: generators
	python setup.py install --root=$(DESTDIR) --prefix=$(PREFIX)

update-icons:
	gtk-update-icon-cache -f -i $(PREFIX)/share/icons/hicolor/

uninstall:
	@echo "##########################################################################"
	@echo "#  MAKE UNINSTALL STILL NOT READY FOR PRIME TIME, WILL DO MY BEST TO     #"
	@echo "#  REMOVE FILES INSTALLED BY GPODDER. WATCH INSTALL PROCESS AND REMOVE   #"
	@echo "#  THE REST OF THE PACKAGES MANUALLY TO COMPLETELY REMOVE GPODDER.       #"
	@echo "##########################################################################"
	rm -rf $(PREFIX)/share/gpodder $(PREFIX)/share/pixmaps/gpodder* $(PREFIX)/share/applications/gpodder.desktop $(PREFIX)/share/man/man1/gpodder.1 $(PREFIX)/bin/gpodder $(PREFIX)/lib/python?.?/site-packages/gpodder/ $(PREFIX)/share/locale/*/LC_MESSAGES/gpodder.mo

##########################################################################

generators: $(MANPAGE) gen_glade gen_graphics
	make -C data/po update

messages: gen_gettext

$(MANPAGE): $(BINFILE)
	help2man --name="A Media aggregator and Podcast catcher" -N $(BINFILE) >$(MANPAGE)

gen_glade: $(GLADEFILE)
	$(TEPACHE) --no-helper --glade=$(GLADEFILE) --output=$(GUIFILE)
	chmod -x $(GUIFILE) $(GUIFILE).orig

gen_gettext: $(MESSAGESPOT)
	make -C data/po generators
	make -C data/po update

gen_graphics:
	convert -bordercolor Transparent -border 1x1 $(LOGO_22) $(LOGO_24)

$(GLADEGETTEXT): $(GLADEFILE)
	intltool-extract --type=gettext/glade $(GLADEFILE)

$(MESSAGESPOT): src/gpodder/*.py $(GLADEGETTEXT) $(BINFILE)
	xgettext -k_ -kN_ -o $(MESSAGESPOT) src/gpodder/*.py $(GLADEGETTEXT) $(BINFILE)
	sed -i'~' -e 's/SOME DESCRIPTIVE TITLE/gPodder translation template/g' -e 's/YEAR THE PACKAGE'"'"'S COPYRIGHT HOLDER/2006 Thomas Perl/g' -e 's/FIRST AUTHOR <EMAIL@ADDRESS>, YEAR/Thomas Perl <thp@perli.net>, 2006/g' -e 's/PACKAGE VERSION/gPodder '$(GPODDERVERSION)'/g' -e 's/PACKAGE/gPodder/g' $(MESSAGESPOT)

rosetta-upload: $(ROSETTA_ARCHIVE)
	@echo 'You can now upload the archive to launchpad.net:  ' $(ROSETTA_ARCHIVE)

$(ROSETTA_ARCHIVE):
	tar czvf $(ROSETTA_ARCHIVE) $(ROSETTA_FILES)

##########################################################################

clean:
	python setup.py clean
	rm -f src/gpodder/*.pyc src/gpodder/*.bak MANIFEST PKG-INFO data/gpodder.gladep{,.bak} data/gpodder.glade.bak $(GLADEGETTEXT) data/messages.pot~ data/gpodder-??x??.png $(ROSETTA_ARCHIVE)
	rm -rf build
	make -C data/po clean

debclean:
	fakeroot debian/rules clean

distclean: clean
	rm -rf dist
 
##########################################################################

.PHONY: all cl test release install update-icons generators gen_manpage gen_glade gen_graphics clean distclean messages help

##########################################################################


