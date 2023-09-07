ifeq ($(with_offload_gcn),yes)
  arch_binaries := $(arch_binaries) gcn
  ifeq ($(with_common_libs),yes)
    arch_binaries := $(arch_binaries) gcn-plugin
  endif
endif

p_gcn	= gcc$(pkg_ver)-offload-amdgcn
d_gcn	= debian/$(p_gcn)

p_pl_gcn = libgomp-plugin-amdgcn1
d_pl_gcn = debian/$(p_pl_gcn)

dirs_gcn = \
	$(docdir)/$(p_xbase)/ \
	$(PF)/bin \
	$(gcc_lexec_dir)/accel

files_gcn = \
	$(PF)/bin/$(DEB_TARGET_GNU_TYPE)-accel-$(gcn_target_name)-gcc$(pkg_ver) \
	$(gcc_lexec_dir)/accel/$(gcn_target_name)

# not needed: libs moved, headers not needed for lto1
#	$(PF)/amdgcn-none

# are these needed?
#	$(PF)/lib/gcc/$(gcn_target_name)/$(versiondir)/{include,finclude,mgomp}

ifneq ($(GFDL_INVARIANT_FREE),yes)
  files_gcn += \
	$(PF)/share/man/man1/$(DEB_HOST_GNU_TYPE)-accel-$(gcn_target_name)-gcc$(pkg_ver).1
endif

$(binary_stamp)-gcn: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_gcn)
	dh_installdirs -p$(p_gcn) $(dirs_gcn)
	tar -c -C $(d)-gcn -f - $(files_gcn) \
	  | tar -x -v -C $(d_gcn) -f -

ifeq ($(gcn_tools_llvm_version),tools)
	: # re-create the symlinks as relative symlinks
	dh_link -p$(p_gcn) \
	  /usr/$(gcn_target_name)/bin/ar     /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ar \
	  /usr/$(gcn_target_name)/bin/as     /$(gcc_lexec_dir)/accel/$(gcn_target_name)/as \
	  /usr/$(gcn_target_name)/bin/ld     /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ld \
	  /usr/$(gcn_target_name)/bin/nm     /$(gcc_lexec_dir)/accel/$(gcn_target_name)/nm \
	  /usr/$(gcn_target_name)/bin/ranlib /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ranlib
else
	: # re-create the symlinks as relative symlinks
	dh_link -p$(p_gcn) \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-ar /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ar \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-mc /$(gcc_lexec_dir)/accel/$(gcn_target_name)/as \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/lld     /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ld \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-nm /$(gcc_lexec_dir)/accel/$(gcn_target_name)/nm \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-ranlib /$(gcc_lexec_dir)/accel/$(gcn_target_name)/ranlib

	mkdir -p $(d_gcn)/usr/$(gcn_target_name)/bin
	dh_link -p$(p_gcn) \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-ar /usr/$(gcn_target_name)/bin/ar \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-mc /usr/$(gcn_target_name)/bin/as \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/lld /usr/$(gcn_target_name)/bin/ld \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-nm /usr/$(gcn_target_name)/bin/nm \
	  /usr/lib/llvm-$(gcn_tools_llvm_version)/bin/llvm-ranlib /usr/$(gcn_target_name)/bin/ranlib
endif

	mkdir -p $(d_gcn)/usr/share/lintian/overrides
	( \
	  echo '$(p_gcn) binary: hardening-no-pie'; \
	  echo '$(p_gcn) binary: non-standard-dir-in-usr'; \
	  echo '$(p_gcn) binary: file-in-unusual-dir'; \
	  echo '$(p_gcn) binary: binary-from-other-architecture'; \
	) > $(d_gcn)/usr/share/lintian/overrides/$(p_gcn)
ifeq ($(GFDL_INVARIANT_FREE),yes)
	echo '$(p_gcn) binary: binary-without-manpage' \
	  >> $(d_gcn)/usr/share/lintian/overrides/$(p_gcn)
endif

	debian/dh_doclink -p$(p_gcn) $(p_xbase)

	debian/dh_rmemptydirs -p$(p_gcn)

ifeq (,$(findstring nostrip,$(DEB_BUILD_OPTONS)))
	$(DWZ) \
	  $(d_gcn)/$(gcc_lexec_dir)/accel/$(gcn_target_name)/{collect2,lto1,lto-wrapper,mkoffload}
endif
	dh_strip -p$(p_gcn) \
	  $(if $(unstripped_exe),-X/lto1) -X/lib{c,g,m,gcc,gomp,gcov,gfortran,caf_single,ssp,ssp_nonshared}.a
	dh_shlibdeps -p$(p_gcn)
	echo $(p_gcn) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

# ----------------------------------------------------------------------
$(binary_stamp)-gcn-plugin: $(install_dependencies)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_pl_gcn)
	dh_installdirs -p$(p_pl_gcn) \
		$(docdir) \
		$(usr_lib)
	$(dh_compat2) dh_movefiles -p$(p_pl_gcn) \
		$(usr_lib)/libgomp-plugin-gcn.so.*

	debian/dh_doclink -p$(p_pl_gcn) $(p_xbase)
	debian/dh_rmemptydirs -p$(p_pl_gcn)

	dh_strip -p$(p_pl_gcn)
	dh_makeshlibs -p$(p_pl_gcn)
	dh_shlibdeps -p$(p_pl_gcn)
	echo $(p_pl_gcn) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
