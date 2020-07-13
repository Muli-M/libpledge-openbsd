# Makefile for the libpledge-openbsd package
#.error : This Makefile needs GNU make

MULI_TAG?=1.4
ARCH=`dpkg --print-architecture`

include config.mk

API_VERSION=0
LIBPLEDGE=libpledge-openbsd
PROGS = pledge
LIBS = $(LIBPLEDGE)
ALL = $(LIBS:=.a) $(LIBS:=.so) $(PROGS)

all: options $(ALL)

$(PROGS) : % : %.o
#$(LIBS:=.a) : %.a : %.o
#$(LIBS:=.so) : %.so : %.o
$(LIBPLEDGE:=.a) : %.a : libpledge.o
$(LIBPLEDGE:=.so) : %.so : libpledge.o

libpledge.o : include/pledge_syscalls.h include/seccomp_bpf_utils.h
libpledge.o pledge.o : include/pledge.h

pledge: $(LIBPLEDGE).a


pledge:
	$(CC) $^ -o $@ $(LDFLAGS)

%.a:
	ar rc $@ $^

%.so:
	$(CC) -shared $^ -Wl,-soname,$@.$(API_VERSION) -o $@.$(API_VERSION) $(LDFLAGS)
	$(LN) -f -s $@.$(API_VERSION) $@

options:
	@echo "CFLAGS  = ${CFLAGS}"
	@echo "LDFLAGS = ${LDFLAGS}"
	@echo "CC      = ${CC}"
	@echo "ALL     = ${ALL}"

tests:
	make -C tests/pledge

clean:
	-rm -f $(ALL) *.o *.so.$(API_VERSION)
	rm -f *~ *.deb
	rm -rf debian/tmp

install: all
	mkdir -p $(DESTDIR)$(BINDIR) \
		$(DESTDIR)$(LIBDIR) \
		$(DESTDIR)$(INCDIR)
	install -m0644 $(LIBPLEDGE).a $(LIBPLEDGE).so.$(API_VERSION) $(DESTDIR)$(LIBDIR)
	cp -d $(LIBPLEDGE).so $(DESTDIR)$(LIBDIR)
	install -m0644 include/pledge.h $(DESTDIR)$(INCDIR)
	install -m0755 pledge $(DESTDIR)$(BINDIR)
	install -m0644 man/pledge.1 $(DESTDIR)$(MANDIR)/man1

debian: Makefile debian/control
	rm -rf debian/tmp
	mkdir -p debian/tmp/DEBIAN
	mkdir -p debian/tmp/usr/local/include
	mkdir -p debian/tmp/usr/local/lib
	mkdir -p debian/tmp/usr/local/share/man/man1
	DESTDIR=$(shell pwd)/debian/tmp fakeroot make -f Makefile install

	# generate changelog from git log
	gbp dch --ignore-branch --git-author
	sed -i "/UNRELEASED;/s/unknown/${MULI_TAG}/" debian/changelog
	# generate dependencies
	dpkg-shlibdeps debian/tmp/usr/local/lib/libpledge-openbsd.so debian/tmp/usr/local/bin/pledge
	# generate symbols file
	dpkg-gensymbols
	# generate triggers file
	echo "activate-noawait ldconfig" > debian/tmp/DEBIAN/triggers
	# generate md5sums file
	find debian/tmp/ -type f -exec md5sum '{}' + | grep -v DEBIAN | sed s#debian/tmp/## > debian/tmp/DEBIAN/md5sums
	# control
	dpkg-gencontrol -v${MULI_TAG}


	fakeroot dpkg-deb --build debian/tmp .

.PHONY: all options tests clean install debian
