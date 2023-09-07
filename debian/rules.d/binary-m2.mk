ifneq ($(DEB_STAGE),rtlibs)
  ifeq (0,1)
  ifneq (,$(filter yes, $(biarch64) $(biarch32) $(biarchn32) $(biarchx32) $(biarchsf)))
    arch_binaries  := $(arch_binaries) gm2-multi
  endif
  endif
  arch_binaries := $(arch_binaries) gm2

  ifeq ($(with_m2dev),yes)
    $(lib_binaries) += libgm2-dev
  endif
  ifeq ($(with_libgm2),yes)
    $(lib_binaries) += libgm2
  endif

  ifeq (0,1)
  ifeq ($(with_lib64gm2dev),yes)
    $(lib_binaries)	+= lib64gm2-dev
  endif
  ifeq ($(with_lib32gm2dev),yes)
    $(lib_binaries)	+= lib32gm2-dev
  endif
  ifeq ($(with_libn32gm2dev),yes)
    $(lib_binaries)	+= libn32gm2-dev
  endif
  ifeq ($(with_libx32gm2dev),yes)
    $(lib_binaries)	+= libx32gm2-dev
  endif
  ifeq ($(with_libhfgm2dev),yes)
    $(lib_binaries)	+= libhfgm2-dev
  endif
  ifeq ($(with_libsfgm2dev),yes)
    $(lib_binaries)	+= libsfgm2-dev
  endif

  ifeq ($(with_lib64gm2),yes)
    $(lib_binaries)	+= lib64gm2
  endif
  ifeq ($(with_lib32gm2),yes)
    $(lib_binaries)	+= lib32gm2
  endif
  ifeq ($(with_libn32gm2),yes)
    $(lib_binaries)	+= libn32gm2
  endif
  ifeq ($(with_libx32gm2),yes)
    $(lib_binaries)	+= libx32gm2
  endif
  ifeq ($(with_libhfgm2),yes)
    $(lib_binaries)	+= libhfgm2
  endif
  ifeq ($(with_libsfgm2),yes)
    $(lib_binaries)	+= libsfgm2
  endif
  endif
endif

p_gm2           = gm2$(pkg_ver)$(cross_bin_arch)
p_gm2_m		= gm2$(pkg_ver)-multilib$(cross_bin_arch)
p_libgm2	= libgm2-$(GM2_SONAME)
p_libgm2dev	= libgm2$(pkg_ver)-dev

d_gm2           = debian/$(p_gm2)
d_gm2_m		= debian/$(p_gm2_m)
d_libgm2	= debian/$(p_libgm2)
d_libgm2dev	= debian/$(p_libgm2dev)

dirs_gm2 = \
	$(PF)/bin \
	$(PF)/share/man/man1 \
	$(gcc_lexec_dir) \
	$(gcc_lexec_dir)/plugin
#ifneq ($(DEB_CROSS),yes)
#  dirs_gm2 += \
#	$(gm2_include_dir)
#endif

files_gm2 = \
	$(PF)/bin/$(cmd_prefix)gm2$(pkg_ver) \
	$(gcc_lexec_dir)/plugin/m2rte.so \
	$(gcc_lexec_dir)/{cc1gm2,gm2l,gm2lcc,gm2lgen,gm2lorder}
ifneq ($(GFDL_INVARIANT_FREE),yes-now-pure-gfdl)
    files_gm2 += \
	$(PF)/share/man/man1/$(cmd_prefix)gm2$(pkg_ver).1
endif

dirs_libgm2 = \
	$(PF)/lib \
	$(gm2_include_dir) \
	$(gcc_lib_dir)

$(binary_stamp)-gm2: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_gm2)
	dh_installdirs -p$(p_gm2) $(dirs_gm2)

	dh_installdocs -p$(p_gm2)
	dh_installchangelogs -p$(p_gm2) src/gcc/m2/ChangeLog

	$(dh_compat2) dh_movefiles -p$(p_gm2) $(files_gm2)

ifeq ($(unprefixed_names),yes)
	ln -sf $(cmd_prefix)gm2$(pkg_ver) \
	    $(d_gm2)/$(PF)/bin/gm2$(pkg_ver)
  ifneq ($(GFDL_INVARIANT_FREE),yes-now-pure-gfdl)
	ln -sf $(cmd_prefix)gm2$(pkg_ver).1 \
	    $(d_gm2)/$(PF)/share/man/man1/gm2$(pkg_ver).1
  endif
endif

	dh_link -p$(p_gm2) \
		/$(docdir)/$(p_gcc)/README.Bugs \
		/$(docdir)/$(p_gm2)/README.Bugs

ifeq (,$(findstring nostrip,$(DEB_BUILD_OPTONS)))
	$(DWZ) \
	  $(d_gm2)/$(gcc_lexec_dir)/{cc1gm2,gm2l,gm2lcc,gm2lgen,gm2lorder}
endif
	dh_strip -p$(p_gm2) \
	  $(if $(unstripped_exe),-X/cc1gm2 -X/gm2)
	dh_shlibdeps -p$(p_gm2)

	mkdir -p $(d_gm2)/usr/share/lintian/overrides
	echo '$(p_gm2) binary: hardening-no-pie' \
	  > $(d_gm2)/usr/share/lintian/overrides/$(p_gm2)

	echo $(p_gm2) >> debian/arch_binaries

	find $(d_gm2) -type d -empty -delete

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-gm2-multi: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_gm2_m)
	dh_installdirs -p$(p_gm2_m) $(docdir)

	debian/dh_doclink -p$(p_gm2_m) $(p_xbase)

	dh_strip -p$(p_gm2_m)
	dh_shlibdeps -p$(p_gm2_m)
	echo $(p_gm2_m) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

define __do_libgm2
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_l) $(d_d)
	dh_installdirs -p$(p_l) \
		$(usr_lib$(2))
	$(dh_compat2) dh_movefiles -p$(p_l) \
		$(usr_lib$(2))/libm2pim.so.* \
		$(usr_lib$(2))/libm2cor.so.* \
		$(usr_lib$(2))/libm2iso.so.* \
		$(usr_lib$(2))/libm2log.so.* \
		$(usr_lib$(2))/libm2min.so.*

	debian/dh_doclink -p$(p_l) $(p_lbase)
	$(if $(with_dbg),debian/dh_doclink -p$(p_d) $(p_lbase))

	$(call do_strip_lib_dbg, $(p_l), $(p_d), $(v_dbg),,)
	: ln -sf libgm2.symbols debian/$(p_l).symbols
	$(cross_makeshlibs) dh_makeshlibs $(ldconfig_arg) -p$(p_l) \
		-- -a$(call mlib_to_arch,$(2)) || echo XXXXXXXXXXX ERROR $(p_l)
	rm -f debian/$(p_l).symbols
	$(call cross_mangle_shlibs,$(p_l))
	$(ignshld)DIRNAME=$(subst n,,$(2)) $(cross_shlibdeps) dh_shlibdeps -p$(p_l) \
		$(call shlibdirs_to_search, \
			$(subst gm2-$(GM2_SONAME),gcc-s$(GCC_SONAME),$(p_l)) \
		,$(2)) \
		$(if $(filter yes, $(with_common_libs)),,-- -Ldebian/shlibs.common$(2))
	$(call cross_mangle_substvars,$(p_l))

	mkdir -p $(d_l)/usr/share/lintian/overrides; \
	( \
	  echo "$(p_l) binary: dev-pkg-without-shlib-symlink"; \
	  echo "$(p_l) binary: shared-lib-without-dependency-information"; \
	  echo "$(p_l) binary: package-name-doesnt-match-sonames"; \
	  echo "$(p_l) binary: library-not-linked-against-libc"; \
	) >> $(d_l)/usr/share/lintian/overrides/$(p_l)

	dh_lintian -p$(p_l)
	echo $(p_l) $(if $(with_dbg), $(p_d)) >> debian/$(lib_binaries)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
endef

# install_gm2_lib(lib,soname,flavour,package,subdir)
#define install_gm2_lib
#	mkdir -p debian/$(4)/$(gcc_lib_dir$(3))/$(5)
#	mv $(d)/$(usr_lib$(3))/$(1)*.a debian/$(4)/$(gcc_lib_dir$(3))/$(5)/.
#	rm -f $(d)/$(usr_lib$(3))/$(1)*.{la,so}
#	dh_link -p$(4) \
#	  /$(usr_lib$(3))/$(1).so.$(2) /$(gcc_lib_dir$(3))/$(5)/$(1).so
#endef
define install_gm2_lib
	dh_link -p$(4) \
	  /$(usr_lib$(3))/$(1).so.$(2) /$(gcc_lib_dir$(3))/$(5)/$(1).so
	rm -f $(d)/$(usr_lib$(3))/$(1).so
	rm -f $(d)/$(usr_lib$(3))/$(1).a
endef

define __do_libgm2_dev
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_l)
	dh_installdirs -p$(p_l) \
		$(gcc_lib_dir$(2))

	: # install_gm2_lib calls needed?

	$(if $(2),,
	$(dh_compat2) dh_movefiles -p$(p_l) \
		$(gcc_lexec_dir)/m2
	)

	$(call install_gm2_lib,libm2pim,$(GM2_SONAME),$(2),$(p_l),m2/m2pim)
	$(call install_gm2_lib,libm2cor,$(GM2_SONAME),$(2),$(p_l),m2/m2cor)
	$(call install_gm2_lib,libm2iso,$(GM2_SONAME),$(2),$(p_l),m2/m2iso)
	$(call install_gm2_lib,libm2log,$(GM2_SONAME),$(2),$(p_l),m2/m2log)
	$(call install_gm2_lib,libm2min,$(GM2_SONAME),$(2),$(p_l),m2/m2min)

	: # included in gm2 package
	rm -f $(d_l)/$(gm2_include_dir)/__entrypoint.di

	debian/dh_doclink -p$(p_l) \
		$(if $(filter yes,$(with_separate_gm2)),$(p_gm2),$(p_lbase))
	echo $(p_l) >> debian/$(lib_binaries)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
endef

do_libgm2 = $(call __do_libgm2,lib$(1)gm2-$(GM2_SONAME),$(1))
do_libgm2_dev = $(call __do_libgm2_dev,lib$(1)gm2-$(BASE_VERSION)-dev,$(1))

$(binary_stamp)-libgm2: $(install_stamp)
	$(call do_libgm2,)

$(binary_stamp)-lib64gm2: $(install_stamp)
	$(call do_libgm2,64)

$(binary_stamp)-lib32gm2: $(install_stamp)
	$(call do_libgm2,32)

$(binary_stamp)-libn32gm2: $(install_stamp)
	$(call do_libgm2,n32)

$(binary_stamp)-libx32gm2: $(install_stamp)
	$(call do_libgm2,x32)

$(binary_stamp)-libhfgm2: $(install_stamp)
	$(call do_libgm2,hf)

$(binary_stamp)-libsfgm2: $(install_stamp)
	$(call do_libgm2,sf)


$(binary_stamp)-libgm2-dev: $(install_stamp)
	$(call do_libgm2_dev,)

$(binary_stamp)-lib64gm2-dev: $(install_stamp)
	$(call do_libgm2_dev,64)

$(binary_stamp)-lib32gm2-dev: $(install_stamp)
	$(call do_libgm2_dev,32)

$(binary_stamp)-libx32gm2-dev: $(install_stamp)
	$(call do_libgm2_dev,x32)

$(binary_stamp)-libn32gm2-dev: $(install_stamp)
	$(call do_libgm2_dev,n32)

$(binary_stamp)-libhfgm2-dev: $(install_stamp)
	$(call do_libgm2_dev,hf)

$(binary_stamp)-libsfgm2-dev: $(install_stamp)
	$(call do_libgm2_dev,sf)
