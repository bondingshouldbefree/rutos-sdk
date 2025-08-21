# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2006-2020 OpenWrt.org

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/prereq.mk

SHELL:=sh
PKG_NAME:=Build dependency


# Required for the toolchain
$(eval $(call TestHostCommand,working-make, \
	Please install GNU make v3.82 or later. (This version has bugs), \
	$(MAKE) -v | grep -E 'Make (3\.8[2-9]|3\.9[0-9]|[4-9]\.)'))

$(eval $(call TestHostCommand,case-sensitive-fs, \
	OpenWrt can only be built on a case-sensitive filesystem, \
	rm -f $(TMP_DIR)/test.*; touch $(TMP_DIR)/test.fs; \
		test ! -f $(TMP_DIR)/test.FS))

$(eval $(call TestHostCommand,proper-umask, \
	Please build with umask 022 - other values produce broken packages, \
	umask | grep -xE 0?0[012][012]))

ifndef IB
$(eval $(call SetupHostCommand,gcc, \
	Please install the GNU C Compiler (gcc) 4.8 or later, \
	$(CC) -dumpversion | grep -E '^(4\.[8-9]|[5-9]\.?|1[0-9]\.?)', \
	gcc -dumpversion | grep -E '^(4\.[8-9]|[5-9]\.?|1[0-9]\.?)', \
	gcc --version | grep -E 'Apple.(LLVM|clang)' ))

$(eval $(call TestHostCommand,working-gcc, \
	\nPlease reinstall the GNU C Compiler (4.8 or later) - \
	it appears to be broken, \
	echo 'int main(int argc, char **argv) { return 0; }' | \
		gcc -x c -o $(TMP_DIR)/a.out -))

$(eval $(call SetupHostCommand,g++, \
	Please install the GNU C++ Compiler (g++) 4.8 or later, \
	$(CXX) -dumpversion | grep -E '^(4\.[8-9]|[5-9]\.?|1[0-9]\.?)', \
	g++ -dumpversion | grep -E '^(4\.[8-9]|[5-9]\.?|1[0-9]\.?)', \
	g++ --version | grep -E 'Apple.(LLVM|clang)' ))

$(eval $(call TestHostCommand,working-g++, \
	\nPlease reinstall the GNU C++ Compiler (4.8 or later) - \
	it appears to be broken, \
	echo 'int main(int argc, char **argv) { return 0; }' | \
		g++ -x c++ -o $(TMP_DIR)/a.out - -lstdc++ && \
		$(TMP_DIR)/a.out))

$(eval $(call TestHostCommand,ncurses, \
	Please install ncurses. (Missing libncurses.so or ncurses.h), \
	echo 'int main(int argc, char **argv) { initscr(); return 0; }' | \
		gcc -include ncurses.h -x c -o $(TMP_DIR)/a.out - -lncurses))

$(eval $(call TestHostCommand,expat, \
	Please install expat. (Missing libexpat.so or expat.h), \
	echo 'int main(int argc, char **argv) { XML_ParserCreate(NULL); return 0; }' | \
		gcc -include expat.h -x c -o $(TMP_DIR)/a.out - -lexpat))

$(eval $(call TestHostCommand,lz4, \
	Please install lz4. (Missing liblz4.so or lz4.h), \
	echo 'int main(int argc, char **argv) { LZ4_compressBound(32); return 0; }' | \
		gcc -include lz4.h -x c -o $(TMP_DIR)/a.out - -llz4))

$(eval $(call TestHostCommand,zstd, \
	Please install zstd. (Missing libzstd.so or zstd.h), \
	echo 'int main(int argc, char **argv) { ZSTD_compressBound(32); return 0; }' | \
		gcc -include zstd.h -x c -o $(TMP_DIR)/a.out - -lzstd))

endif # IB

ifeq ($(HOST_OS),Linux)
  zlib_link_flags := -Wl,-Bstatic -lz -Wl,-Bdynamic
else
  zlib_link_flags := -lz
endif

$(eval $(call TestHostCommand,perl-data-dumper, \
	Please install the Perl Data::Dumper module, \
	perl -MData::Dumper -e 1))

$(eval $(call TestHostCommand,perl-findbin, \
	Please install the Perl FindBin module, \
	perl -MFindBin -e 1))

$(eval $(call TestHostCommand,perl-file-copy, \
	Please install the Perl File::Copy module, \
	perl -MFile::Copy -e 1))

$(eval $(call TestHostCommand,perl-file-compare, \
	Please install the Perl File::Compare module, \
	perl -MFile::Compare -e 1))

$(eval $(call TestHostCommand,perl-thread-queue, \
	Please install the Perl Thread::Queue module, \
	perl -MThread::Queue -e 1))

$(eval $(call SetupHostCommand,tar,Please install GNU 'tar', \
	gtar --version 2>&1 | grep GNU, \
	gnutar --version 2>&1 | grep GNU, \
	tar --version 2>&1 | grep GNU))

$(eval $(call SetupHostCommand,find,Please install GNU 'find', \
	gfind --version 2>&1 | grep GNU, \
	find --version 2>&1 | grep GNU))

$(eval $(call SetupHostCommand,bash,Please install GNU 'bash', \
	bash --version 2>&1 | grep GNU))

$(eval $(call SetupHostCommand,xargs, \
	Please install 'xargs' that supports '-r/--no-run-if-empty', \
	gxargs -r --version, \
	xargs -r --version))

$(eval $(call SetupHostCommand,patch,Please install GNU 'patch', \
	gpatch --version 2>&1 | grep 'Free Software Foundation', \
	patch --version 2>&1 | grep 'Free Software Foundation'))

$(eval $(call SetupHostCommand,diff,Please install diffutils, \
	gdiff --version 2>&1 | grep diff, \
	diff --version 2>&1 | grep diff))

$(eval $(call SetupHostCommand,cp,Please install GNU fileutils, \
	gcp --help 2>&1 | grep 'Copy SOURCE', \
	cp --help 2>&1 | grep 'Copy SOURCE'))

$(eval $(call SetupHostCommand,seq,Please install seq, \
	gseq --version, \
	seq --version 2>&1 | grep seq))

$(eval $(call SetupHostCommand,awk,Please install GNU 'awk', \
	gawk --version 2>&1 | grep GNU, \
	awk --version 2>&1 | grep GNU))

$(eval $(call SetupHostCommand,grep,Please install GNU 'grep', \
	ggrep --version 2>&1 | grep GNU, \
	grep --version 2>&1 | grep GNU))

$(eval $(call SetupHostCommand,egrep,Please install GNU 'grep', \
	gegrep --version 2>&1 | grep GNU, \
	egrep --version 2>&1 | grep GNU))

$(eval $(call SetupHostCommand,getopt, \
	Please install an extended getopt version that supports --long, \
	gnugetopt -o t --long test -- --test | grep '^ *--test *--', \
	getopt -o t --long test -- --test | grep '^ *--test *--', \
	/usr/local/opt/gnu-getopt/bin/getopt -o t --long test -- --test | grep '^ *--test *--'))

$(eval $(call SetupHostCommand,stat,Cannot find a file stat utility, \
	gnustat -c%s $(TOPDIR)/Makefile, \
	gstat -c%s $(TOPDIR)/Makefile, \
	stat -c%s $(TOPDIR)/Makefile))

$(eval $(call SetupHostCommand,unzip,Please install 'unzip', \
	unzip 2>&1 | grep zipfile, \
	unzip))

$(eval $(call SetupHostCommand,bzip2,Please install 'bzip2', \
	bzip2 --version </dev/null))

$(eval $(call SetupHostCommand,wget,Please install GNU 'wget', \
	wget --version | grep GNU))

$(eval $(call SetupHostCommand,perl,Please install Perl 5.x, \
	perl --version | grep "perl.*v5"))

$(eval $(call CleanupPython2))

$(eval $(call SetupHostCommand,python,Please install Python >= 3.11, \
	python3.13 -V 2>&1 | grep 'Python 3', \
	python3.12 -V 2>&1 | grep 'Python 3', \
	python3.11 -V 2>&1 | grep 'Python 3'))

$(eval $(call SetupHostCommand,python3,Please install Python >= 3.11, \
	python3.13 -V 2>&1 | grep 'Python 3', \
	python3.12 -V 2>&1 | grep 'Python 3', \
	python3.11 -V 2>&1 | grep 'Python 3'))

$(eval $(call TestHostCommand,python3-distutils, \
	Please install the Python3 distutils module (or Python3 setuputils module on Python >= 3.12), \
	$(STAGING_DIR_HOST)/bin/python3 -c 'from distutils import util'))

$(eval $(call SetupHostCommand,git,Please install Git (git-core) >= 1.7.12.2, \
	git --exec-path | xargs -I % -- grep -q -- --recursive %/git-submodule))

$(eval $(call SetupHostCommand,file,Please install the 'file' package, \
	file --version 2>&1 | grep file))

$(eval $(call SetupHostCommand,rsync,Please install 'rsync', \
	rsync --version </dev/null))

$(eval $(call SetupHostCommand,which,Please install 'which', \
	which which | grep which))

$(STAGING_DIR_HOST)/bin/mkhash: $(SCRIPT_DIR)/mkhash.c
	mkdir -p $(dir $@)
	$(CC) -O2 -I$(TOPDIR)/tools/include -o $@ $<

prereq: $(STAGING_DIR_HOST)/bin/mkhash

# Install ldconfig stub
$(eval $(call TestHostCommand,ldconfig-stub,Failed to install stub, \
	touch $(STAGING_DIR_HOST)/bin/ldconfig && \
	chmod +x $(STAGING_DIR_HOST)/bin/ldconfig))

$(eval $(call TestHostCommand,node,Please install NodeJS >= 20.0, \
	node --version 2>&1 | awk -F. \
		'{major=int(substr($$$$$$$$1,2,length($$$$$$$$1)-1)); if(major < 20) exit 1}'))

$(eval $(call SetupHostCommand,npm,Please install the 'npm' package, \
	npm --version))

$(eval $(call SetupHostCommand,jq,Please install 'jq', \
	jq --version 2>&1 ))

$(eval $(call SetupHostCommand,gperf,Please install 'gperf', \
	gperf --version 2>&1 ))

$(eval $(call SetupHostCommand,cmake,Please install 'cmake', \
	cmake --version 2>&1 ))

$(eval $(call SetupHostCommand,fakeroot,Please install fakeroot >= 1.28, \
	fakeroot --version | grep -E "fakeroot version 1\.(2[8-9]|[3-9][0-9+])"))
