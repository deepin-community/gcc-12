$(lib_binaries)  += libhwasan
ifeq ($(with_lib64hwasan),yes)
  $(lib_binaries)  += lib64hwasan
endif
ifeq ($(with_lib32hwasan),yes)
  $(lib_binaries)	+= lib32hwasan
endif
ifeq ($(with_libn32hwasan),yes)
  $(lib_binaries)	+= libn32hwasan
endif
ifeq ($(with_libx32hwasan),yes)
  $(lib_binaries)	+= libx32hwasan
endif
ifeq ($(with_libhfhwasan),yes)
  $(lib_binaries)	+= libhfhwasan
endif
ifeq ($(with_libsfhwasan),yes)
  $(lib_binaries)	+= libsfhwasan
endif

define __do_hwasan
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_l) $(d_d)
	dh_installdirs -p$(p_l) $(usr_lib$(2))
	$(dh_compat2) dh_movefiles -p$(p_l) $(usr_lib$(2))/libhwasan.so.*

	debian/dh_doclink -p$(p_l) $(p_lbase)
	$(if $(with_dbg),debian/dh_doclink -p$(p_d) $(p_lbase))

	if [ -f debian/$(p_l).overrides ]; then \
		mkdir -p debian/$(p_l)/usr/share/lintian/overrides; \
		cp debian/$(p_l).overrides debian/$(p_l)/usr/share/lintian/overrides/$(p_l); \
	fi
	$(if $(2), \
	  mkdir -p debian/$(p_l)/usr/share/lintian/overrides; \
	  echo "$(p_l): symbols-file-contains-current-version-with-debian-revision" \
	    >> debian/$(p_l)/usr/share/lintian/overrides/$(p_l))

	$(if $(strip_sanitizer), $(call do_strip_lib_dbg, $(p_l), $(p_d), $(v_dbg),,))
	$(cross_makeshlibs) dh_makeshlibs $(ldconfig_arg) -p$(p_l)
	$(call cross_mangle_shlibs,$(p_l))
	$(if $(ignshld),$(ignshld),-)DIRNAME=$(subst n,,$(2)) $(cross_shlibdeps) dh_shlibdeps -p$(p_l) \
		$(call shlibdirs_to_search, \
			$(subst hwasan$(HWASAN_SONAME),gcc-s$(GCC_SONAME),$(p_l)) \
			$(subst hwasan$(HWASAN_SONAME),stdc++$(CXX_SONAME),$(p_l)) \
		,$(2)) \
		$(if $(filter yes, $(with_common_libs)),,-- -Ldebian/shlibs.common$(2))
	$(call cross_mangle_substvars,$(p_l))
	echo $(p_l) $(if $(with_dbg), $(p_d)) >> debian/$(lib_binaries)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
endef

# ----------------------------------------------------------------------

do_hwasan = $(call __do_hwasan,lib$(1)hwasan$(HWASAN_SONAME),$(1))

$(binary_stamp)-libhwasan: $(install_stamp)
	$(call do_hwasan,)

$(binary_stamp)-lib64hwasan: $(install_stamp)
	$(call do_hwasan,64)

$(binary_stamp)-lib32hwasan: $(install_stamp)
	$(call do_hwasan,32)

$(binary_stamp)-libn32hwasan: $(install_stamp)
	$(call do_hwasan,n32)

$(binary_stamp)-libx32hwasan: $(install_stamp)
	$(call do_hwasan,x32)

$(binary_stamp)-libhfhwasan: $(install_dependencies)
	$(call do_hwasan,hf)

$(binary_stamp)-libsfhwasan: $(install_dependencies)
	$(call do_hwasan,sf)
