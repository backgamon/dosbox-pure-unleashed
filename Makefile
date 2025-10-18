ZillaApp = DOSBoxPure
ZILLALIB_PATH = ../ZillaLib
include $(ZILLALIB_PATH)/Makefile

ifdef ZL_IS_APP_MAKE

DBPDir := ../dosbox-pure

ZL_ADD_SRC_FILES := $(wildcard \
    $(DBPDir)/*.cpp            \
    $(DBPDir)/src/*.cpp        \
    $(DBPDir)/src/*/*.cpp      \
    $(DBPDir)/src/*/*/*.cpp    \
  )

ISMAC := $(wildcard /Applications)
UNAME := $(shell uname -m)

GLCTX += $(if $(filter undefined,$(origin ZL_VIDEO_OPENGL_CORE)),,OPENGL_CORE)
GLCTX += $(if $(filter undefined,$(origin ZL_VIDEO_OPENGL2)),,OPENGL2)
GLCTX += $(if $(filter undefined,$(origin ZL_VIDEO_OPENGL_ES2)),,OPENGL_ES2)
ifeq ($(words $(GLCTX)),0)
  ifeq ($(if $(ISMAC),0,$(if $(or $(findstring arm,$(UNAME)),$(findstring aarch,$(UNAME))),1,0)),1)
    GLCTX += OPENGL_ES2
  else
    GLCTX += OPENGL_CORE
  endif
endif
ifneq ($(words $(GLCTX)),1)
  $(error Multiple OpenGL context types specified ($(strip $(GLCTX))))
endif
COMMONFLAGS += -DZL_VIDEO_$(strip $(GLCTX))

APPFLAGS += -I$(DBPDir) -I$(DBPDir)/include -D__LIBRETRO__ -DDBP_STANDALONE -Wno-switch -Wno-address-of-packed-member -Wno-array-bounds -Wno-format -Wno-maybe-uninitialized -Wno-misleading-indentation -Wno-sign-compare -Wno-unused-variable -Wno-unused-but-set-variable -Wno-sometimes-uninitialized -Wno-bitwise-instead-of-logical -Wno-stringop-truncation -frtti -fexceptions

# ZL itself is compiled with no-rtti, our main c++ file needs to match that
$(APPOUTDIR)/main$(if $(OBJEXT),$(OBJEXT),.o): APPFLAGS += -fno-rtti

ifneq ($(ISMAC),)
LDFLAGS += -framework CoreMidi
DBPVER := $(shell perl -ne 'print $$1 if /DOSBOX_PURE_VERSION_STR "(.*)"/' $(DBPDir)/dosbox_pure_ver.h)
CPUTYPE := $(if $(or $(findstring arm,$(UNAME)),$(findstring aarch,$(UNAME))),arm_$(or $(findstring 64,$(UNAME)),32),x86_$(if $(if $(M32),,$(or $(M64),$(findstring 64,$(UNAME)))),64,32))

ifeq ($(BUILD),RELEASE)
MACOS_OUTDIR := Release-macos
MACOS_APPIZP := DOSBoxPure.app.zip
else
MACOS_OUTDIR := Debug-macos
MACOS_APPIZP := DOSBoxPure-Debug.app.zip
endif

$(MACOS_OUTDIR)/$(MACOS_APPIZP): $(MACOS_OUTDIR)/DOSBoxPure_$(CPUTYPE) DOSBoxPure-MacOSAppBase
	@unzip -oq DOSBoxPure-MacOSAppBase
	@cp $(MACOS_OUTDIR)/DOSBoxPure_$(CPUTYPE) DOSBoxPure.app/Contents/MacOS/DOSBoxPure
	@touch DOSBoxPure.app DOSBoxPure.app/Contents DOSBoxPure.app/Contents/* DOSBoxPure.app/Contents/MacOS/DOSBoxPure DOSBoxPure.app/Contents/Resources/*
	perl -i -pe "s/1.0.0/$(DBPVER)/g" DOSBoxPure.app/Contents/Info.plist
	zip -r $(MACOS_OUTDIR)/$(MACOS_APPIZP) DOSBoxPure.app
	@rm -rf DOSBoxPure.app

endif #ISMAC

endif #ZL_IS_APP_MAKE
