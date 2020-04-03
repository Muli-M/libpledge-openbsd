libpledge-openbsd
-----------------

This repository creates site-local binary Debian/Ubuntu package
providing functions for self-resticting system operations from OpenBSD which
one might find useful in porting applications from OpenBSD to Linux.

The following packages are needed to build it on Ubuntu:
    make, dpkg-dev, git-buildpackage, fakeroot

Just type `make debian` to create .deb package.


Differences to pledge(2) on OpenBSD
-----------------------------------
`execpromises` are not supported.