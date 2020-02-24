# Makefile for the libpledge-openbsd package
#.error : This Makefile needs GNU make

MULI_TAG?=1.1
ARCH=`dpkg --print-architecture`

include config.mk

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
	$(CC) -shared $^ -o $@ $(LDFLAGS)

options:
	@echo "CFLAGS  = ${CFLAGS}"
	@echo "LDFLAGS = ${LDFLAGS}"
	@echo "CC      = ${CC}"
	@echo "ALL     = ${ALL}"

tests:
	make -C tests/pledge

clean:
	-rm -f $(ALL) *.o
	rm -f *~ *.deb
	rm -rf debian

install: all
	mkdir -p $(DESTDIR)$(BINDIR) \
		$(DESTDIR)$(LIBDIR) \
		$(DESTDIR)$(INCDIR)
	install -m0644 $(LIBPLEDGE).a $(LIBPLEDGE).so $(DESTDIR)$(LIBDIR)
	install -m0644 include/pledge.h $(DESTDIR)$(INCDIR)
	install -m0755 pledge $(DESTDIR)$(BINDIR)
	install -m0644 man/pledge.1 $(DESTDIR)$(MANDIR)/man1

debian: Makefile control_tmpl
	rm -rf debian
	mkdir -p debian/DEBIAN
	mkdir -p debian/usr/local/include
	mkdir -p debian/usr/local/lib
	mkdir -p debian/usr/local/share/man/man1
	DESTDIR=$(shell pwd)/debian fakeroot make -f Makefile install

	# control
	echo "Version: ${MULI_TAG}" > debian/DEBIAN/control
	echo "Architecture: ${ARCH}" >> debian/DEBIAN/control
	cat control_tmpl >> debian/DEBIAN/control

	# debian scripts
#	install -D preinst debian/DEBIAN
#	install -D postinst debian/DEBIAN


	fakeroot dpkg-deb --build debian .

.PHONY: all options tests clean install debian
