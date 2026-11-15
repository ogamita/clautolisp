# windows-environment.mk --- the Windows profile folders a Lisp needs.
#
# Included by every Makefile that starts a Lisp (the root one and those of
# clautolisp, autolisp-front-end, autolisp-test and autolisp-benchmark):
#
#     include ../scripts/windows-environment.mk
#
# On Windows, UIOP finds the user's configuration under %LOCALAPPDATA%
# (falling back to %APPDATA%\Local) unless XDG_CONFIG_HOME is set. A shell
# opened over ssh -- OpenSSH for Windows into MSYS2 -- has none of
# USERPROFILE, LOCALAPPDATA, APPDATA, TEMP, TMP, so UIOP builds the RELATIVE
# #P"config/" and loading quicklisp/setup.lisp dies with
#
#     Invalid pathname #P"config/": Expected an absolute pathname
#
# before anything is compiled. This supplies the values the interactive
# session would have, and ONLY the missing ones: an existing value is never
# overridden, and no mixed-case twin (ProgramFiles beside PROGRAMFILES) is
# ever created -- .NET tools refuse those. It is the Makefile counterpart of
# the same three lines in scripts/environnement-windows.sh, which the CI
# Windows lanes source.
#
# Windows is recognised by OS=Windows_NT, or by `uname -s' (MINGW*, MSYS*,
# CYGWIN*) in case the ssh session lacks OS too. Elsewhere this is a no-op.
#
# Regression test: scripts/tests/test-windows-environment-mk.sh
# (`make check-windows-make-environment').

ifeq ($(OS),Windows_NT)
WINDOWS_ENVIRONMENT_HOST := yes
else
WINDOWS_ENVIRONMENT_HOST := $(if $(filter MINGW% MSYS% CYGWIN%,$(shell uname -s 2>/dev/null)),yes,)
endif

# The user name is not reliable over ssh either: USERNAME is usually absent,
# and USER may be the ssh login form (domain+user). So every candidate is
# tried -- USERNAME, USER, LOGNAME, then the last component of HOME (MSYS2's
# /home/<user>) -- and the first whose profile folder exists wins; failing
# that, the first candidate. WINDOWS_PROFILES_ROOT exists for the test.
WINDOWS_PROFILES_ROOT ?= C:/Users

ifeq ($(WINDOWS_ENVIRONMENT_HOST),yes)
WINDOWS_ENVIRONMENT_USERS := $(strip $(USERNAME) $(USER) $(LOGNAME) $(notdir $(patsubst %/,%,$(HOME))))
WINDOWS_ENVIRONMENT_USER := $(firstword \
  $(foreach u,$(WINDOWS_ENVIRONMENT_USERS),$(if $(wildcard $(WINDOWS_PROFILES_ROOT)/$(u)/.),$(u))) \
  $(WINDOWS_ENVIRONMENT_USERS))
ifeq ($(strip $(USERPROFILE)),)
ifneq ($(WINDOWS_ENVIRONMENT_USER),)
export USERPROFILE := $(WINDOWS_PROFILES_ROOT)/$(WINDOWS_ENVIRONMENT_USER)
endif
endif
ifneq ($(strip $(USERPROFILE)),)
ifeq ($(strip $(LOCALAPPDATA)),)
export LOCALAPPDATA := $(USERPROFILE)/AppData/Local
endif
ifeq ($(strip $(APPDATA)),)
export APPDATA := $(USERPROFILE)/AppData/Roaming
endif
endif
# UIOP's temporary-directory on Windows is $TEMP and nothing else: unset, it
# is NIL and every temp file the tests make becomes RELATIVE to the current
# directory. Windows' own default is %LOCALAPPDATA%\Temp.
ifneq ($(strip $(LOCALAPPDATA)),)
ifeq ($(strip $(TEMP)),)
export TEMP := $(LOCALAPPDATA)/Temp
endif
ifeq ($(strip $(TMP)),)
export TMP := $(LOCALAPPDATA)/Temp
endif
endif
endif
