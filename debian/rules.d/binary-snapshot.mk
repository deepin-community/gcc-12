arch_binaries  := $(arch_binaries) snapshot

ifneq (,$(findstring gcc-snapshot, $(PKGSOURCE)))
  p_snap = gcc-snapshot
else
  $(error unknown build for single gcc package)
endif

ifeq ($(DEB_CROSS),yes)
  p_snap := $(p_snap)$(cross_bin_arch)
endif
d_snap	= debian/$(p_snap)

dirs_snap = \
	$(docdir)/$(p_snap) \
	usr/lib

ifeq ($(with_hppa64),yes)
  snapshot_depends = $(binutils_hppa64),
endif
ifeq ($(with_offload_nvptx),yes)
  snapshot_depends += nvptx-tools,
endif
ifeq ($(with_offload_gcn),yes)
 ifeq ($(gcn_tools_llvm_version),tools)
   snapshot_depends += amdgcn-tools,
 else
   snapshot_depends += llvm-$(gcn_tools_llvm_version), lld-$(gcn_tools_llvm_version),
 endif
endif

common_substvars += '-Vsnap:depends=$(snapshot_depends)' '-Vsnap:recommends=$(snapshot_recommends)'

# ----------------------------------------------------------------------
$(binary_stamp)-snapshot: $(install_snap_stamp) \
    $(if $(filter yes, $(with_offload_nvptx)), $(install_nvptx_stamp)) \
    $(if $(filter yes, $(with_offload_gcn)), $(install_gcn_stamp))
	dh_testdir
	dh_testroot
	mv $(install_snap_stamp) $(install_snap_stamp)-tmp

	rm -rf $(d_snap)
	dh_installdirs -p$(p_snap) $(dirs_snap)

	mv $(d)/$(PF) $(d_snap)/usr/lib/

	find $(d_snap) -name '*.gch' -type d | xargs -r rm -rf
	find $(d_snap) -name '*.la' -o -name '*.lai' | xargs -r rm -f

	: # FIXME: libbacktrace is not installed by default
	for d in . 32 n32 64 sf hf; do \
	  if [ -f $(buildlibdir)/$$d/libbacktrace/.libs/libbacktrace.a ]; then \
	    install -m644 $(buildlibdir)/$$d/libbacktrace/.libs/libbacktrace.a \
	      $(d_snap)/$(gcc_lib_dir)/$$d; \
	  fi; \
	done
	if [ -f $(buildlibdir)/libbacktrace/backtrace-supported.h ]; then \
	  install -m644 $(buildlibdir)/libbacktrace/backtrace-supported.h \
	    $(d_snap)/$(gcc_lib_dir)/include/; \
	  install -m644 $(srcdir)/libbacktrace/backtrace.h \
	    $(d_snap)/$(gcc_lib_dir)/include/; \
	fi

	rm -rf $(d_snap)/$(PF)/lib/nof

ifeq ($(with_ada),yes FIXME: apply our ada patches)
	dh_link -p$(p_snap) \
	   $(gcc_lib_dir)/rts-sjlj/adalib/libgnat.a \
	   $(gcc_lib_dir)/rts-sjlj/adalib/libgnat-$(GNAT_VERSION).a
	dh_link -p$(p_snap) \
	   $(gcc_lib_dir)/rts-sjlj/adalib/libgnarl.a \
	   $(gcc_lib_dir)/rts-sjlj/adalib/libgnarl-$(GNAT_VERSION).a

	set -e; \
	for lib in lib{gnat,gnarl}; do \
	  vlib=$$lib-$(GNAT_SONAME); \
	  mv $(d_snap)/$(gcc_lib_dir)/adalib/$$vlib.so.1 $(d_snap)/$(PF)/$(libdir)/. ; \
	  rm -f $(d_snap)/$(gcc_lib_dir)/adalib/$$lib.so.1; \
	  dh_link -p$(p_snap) \
	    /$(PF)/$(libdir)/$$vlib.so.1 /$(PF)/$(libdir)/$$vlib.so \
	    /$(PF)/$(libdir)/$$vlib.so.1 /$(PF)/$(libdir)/$$lib.so \
	    /$(PF)/$(libdir)/$$vlib.so.1 /$(gcc_lib_dir)/rts-native/adalib/$$lib.so; \
	done
endif
	ln -sf gcc $(d_snap)/$(PF)/bin/cc
ifeq ($(with_ada),yes)
	ln -sf gcc $(d_snap)/$(PF)/bin/gnatgcc
endif
ifeq ($(with_fortran),yes)
	ln -sf gfortran $(d_snap)/$(PF)/bin/f77
endif

ifeq ($(with_offload_nvptx),yes)
	tar -c -C $(d)-nvptx -f - $(PF) \
	    | tar x -C $(d_snap) -f -

	rm -f $(d_snap)/$(PF)/bin/*-lto-dump
	rm -f $(d_snap)/$(PF)/share/man/man1/*-accel-nvptx-none-*.1

	: # re-create the symlinks as relative symlinks
	dh_link -p$(p_snap) \
	  /usr/bin/nvptx-none-ar     /$(gcc_lexec_dir)/accel/nvptx-none/ar \
	  /usr/bin/nvptx-none-as     /$(gcc_lexec_dir)/accel/nvptx-none/as \
	  /usr/bin/nvptx-none-ld     /$(gcc_lexec_dir)/accel/nvptx-none/ld \
	  /usr/bin/nvptx-none-ranlib /$(gcc_lexec_dir)/accel/nvptx-none/ranlib
endif

ifeq ($(with_offload_gcn),yes)
	tar -c -C $(d)-gcn -f - $(PF) \
	  | tar x -C $(d_snap) -f -

  ifeq ($(gcn_tools_llvm_version),tools)
	: # re-create the symlinks as relative symlinks
	dh_link -p$(p_snap) \
	  /usr/$(gcn_target_name)/bin/ar     /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ar \
	  /usr/$(gcn_target_name)/bin/as     /$(gcc_lexec_dir)/accel/$(gcn_target_name)/as \
	  /usr/$(gcn_target_name)/bin/ld     /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ld \
	  /usr/$(gcn_target_name)/bin/nm     /$(gcc_lexec_dir)/accel/$(gcn_target_name)/nm \
	  /usr/$(gcn_target_name)/bin/ranlib /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ranlib
  else
	: # re-create the symlinks as relative symlinks
	dh_link -p$(p_snap) \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-ar /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ar \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-mc /$(gcc_lexec_dir)/accel/$(gcn_target_name)/as \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/lld     /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ld \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-nm /$(gcc_lexec_dir)/accel/$(gcn_target_name)/nm \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-ranlib /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ranlib

	: # FIXME: are these really needed?
	dh_link -p$(p_snap) \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-ar /$(PF)/bin/$(gcn_target_name)-ar \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-mc /$(PF)/bin/$(gcn_target_name)-as \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/lld /$(PF)/bin/$(gcn_target_name)-ld \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-nm /$(PF)/bin/$(gcn_target_name)-nm \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-ranlib /$(PF)/bin/$(gcn_target_name)-ranlib
	rm -f $(d_snap)/$(PF)/bin/*-lto-dump
	rm -f $(d_snap)/$(PF)/share/man/man1/*-accel-$(gcn_target_name)-*.1
  endif
endif

ifeq ($(with_hppa64),yes)
	: # provide as and ld links
	dh_link -p $(p_snap) \
		/usr/bin/hppa64-linux-gnu-as \
		/$(PF)/lib/gcc/hppa64-linux-gnu/$(versiondir)/as \
		/usr/bin/hppa64-linux-gnu-ld \
		/$(PF)/lib/gcc/hppa64-linux-gnu/$(versiondir)/ld
endif

ifeq ($(with_check),yes)
	dh_installdocs -p$(p_snap) test-summary
	cd $(d_snap) && tar xvf ../../installed-testlogs.tar
	mv $(d_snap)/usr/share/doc/gcc-base/* $(d_snap)/usr/share/doc/$(p_snap)/.
	rm -rf $(d_snap)/usr/share/doc/gcc-base
else
	dh_installdocs -p$(p_snap)
endif

	if [ -f $(buildlibdir)/libstdc++-v3/testsuite/current_symbols.txt ]; \
	then \
	  cp -p $(buildlibdir)/libstdc++-v3/testsuite/current_symbols.txt \
	    $(d_snap)/$(docdir)/$(p_snap)/libstdc++6_symbols.txt; \
	fi
	cp -p debian/README.snapshot \
		$(d_snap)/$(docdir)/$(p_snap)/README.Debian
	cp -p debian/README.Bugs \
		$(d_snap)/$(docdir)/$(p_snap)/
	dh_installchangelogs -p$(p_snap)
ifeq ($(DEB_TARGET_ARCH),hppa)
#	dh_dwz -p$(p_snap) -Xdebug -X/cgo -Xbin/go -Xbin/gofmt \
#	  $(if $(unstripped_exe),$(foreach i,cc1 cc1obj cc1objplus cc1plus cc1gm2 d21 f951 go1 lto1, -X/$(i)))
	dh_strip -p$(p_snap) -Xdebug -X.o -X.a -X/cgo -Xbin/go -Xbin/gofmt \
	  $(if $(unstripped_exe),$(foreach i,cc1 cc1obj cc1objplus cc1plus cc1gm2 d21 f951 go1 lto1, -X/$(i)))
else
#	dh_dwz -p$(p_snap) -Xdebug -X/cgo -Xbin/go -Xbin/gofmt \
#	  $(if $(unstripped_exe),$(foreach i,cc1 cc1obj cc1objplus cc1plus cc1gm2 d21 f951 go1 lto1, -X/$(i)))
	dh_strip -p$(p_snap) -Xdebug -X/cgo -Xbin/go -Xbin/gofmt \
	  -X/lib{c,g,m,gcc,gomp,gcov,gfortran,caf_single,ssp,ssp_nonshared}.a \
	  $(if $(unstripped_exe),$(foreach i,cc1 cc1obj cc1objplus cc1plus cc1gm2 d21 f951 go1 lto1, -X/$(i)))
endif

	mkdir -p $(d_snap)/usr/share/lintian/overrides
	cp -p debian/gcc-snapshot.overrides \
		$(d_snap)/usr/share/lintian/overrides/$(p_snap)

	( \
	  echo 'libgcc_s $(GCC_SONAME) ${p_snap} (>= $(DEB_EVERSION))'; \
	  echo 'libobjc $(OBJC_SONAME) ${p_snap} (>= $(DEB_EVERSION))'; \
	  echo 'libgfortran $(FORTRAN_SONAME) ${p_snap} (>= $(DEB_EVERSION))'; \
	  echo 'libgo $(GO_SONAME) ${p_snap} (>= $(DEB_EVERSION))'; \
	  echo 'libgomp $(GOMP_SONAME) ${p_snap} (>= $(DEB_EVERSION))'; \
	  echo 'libgnat-$(GNAT_SONAME) 1 ${p_snap} (>= $(DEB_EVERSION))'; \
	  echo 'libgnarl-$(GNAT_SONAME) 1 ${p_snap} (>= $(DEB_EVERSION))'; \
	) > debian/shlibs.local

	$(ignshld)DIRNAME=$(subst n,,$(2)) $(cross_shlibdeps)  \
	  dh_shlibdeps -p$(p_snap) -l$(CURDIR)/$(d_snap)/$(PF)/lib:$(CURDIR)/$(d_snap)/$(PF)/$(if $(filter $(DEB_TARGET_ARCH),amd64 ppc64),lib32,lib64):/usr/$(DEB_TARGET_GNU_TYPE)/lib
	-sed -i -e 's/$(p_snap)[^,]*, //g' debian/$(p_snap).substvars

ifeq ($(with_multiarch_lib),yes)
	: # paths needed for relative lookups from startfile_prefixes
	for ma in $(xarch_multiarch_names); do \
	  mkdir -p $(d_snap)/lib/$$ma; \
	  mkdir -p $(d_snap)/usr/lib/$$ma; \
	done
endif
	 echo $(p_snap) >> debian/arch_binaries.epoch

	trap '' 1 2 3 15; touch $@; mv $(install_snap_stamp)-tmp $(install_snap_stamp)
