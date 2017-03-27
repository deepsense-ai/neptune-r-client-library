# Copyright (c) 2017, deepsense.io
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

-include $(HOME)/.artifactory_credentials
-include $(HOME)/.gerrit_credentials

GIT="git"
RSCRIPT="Rscript"
PYTHON="python"

ifeq ($(OS),Windows_NT)
        SSH="C:\Program Files\Git\usr\bin\ssh.exe"
        TOUCH="C:\Program Files\Git\usr\bin\touch.exe"
        GREP="C:\Program Files\Git\usr\bin\grep.exe"
        CUT="C:\Program Files\Git\usr\bin\cut.exe"
        EXPORT=set
        CURL="C:\Program Files\Git\usr\bin\curl.exe"
        CP="C:\Program Files\Git\usr\bin\cp.exe"
        MV="C:\Program Files\Git\usr\bin\mv.exe"
        RM="C:\Program Files\Git\usr\bin\rm.exe"
        MKDIR="C:\Program Files\Git\usr\bin\mkdir.exe"
        FIND="C:\Program Files\Git\usr\bin\find.exe"
        JAVA_CLIENT_UBERJAR_LOCATION="build\java-client-library.jar"
        INTEGRATED_JAVA_CLIENT_LOCATION="neptune\inst\java"
        CMD_SEP=&
else
        SSH="ssh"
        TOUCH="touch"
        GREP="grep"
        CUT="cut"
        EXPORT="export"
        CURL="curl"
        CP="cp"
        MV="mv"
        RM="rm"
        MKDIR="mkdir"
        FIND="find"
        SED="sed"
        JAVA_CLIENT_UBERJAR_LOCATION="build/java-client-library.jar"
        INTEGRATED_JAVA_CLIENT_LOCATION="neptune/inst/java"
        CMD_SEP=;
endif

COLOR_RED=1
COLOR_GREEN=2
COLOR_YELLOW=3
COLOR_BLUE=4
COLOR_MAGENTA=5
COLOR_CYAN=6
COLOR_WHITE=7

ifeq ($(OS), Windows_NT)
define printMsg
	@echo $(1)
endef
else
define printMsg
	@tput setaf $(2)
	@tput bold
	@echo $(1)
	@tput sgr0
endef
endif

define inf
	$(call printMsg, $(1), $(COLOR_GREEN))
endef

define wrn
	$(call printMsg, $(1), $(COLOR_YELLOW))
endef

define err
	$(call printMsg, $(1), $(COLOR_RED))
endef

check_artifactory:
ifeq (,$(wildcard $(HOME)/.artifactory_credentials))
	$(call err, ">>> File $(HOME)/.artifactory_credentials does not exist!")
	@exit 1
endif
ifndef host
	$(call err, "Variable 'host' is not defined in $(HOME)/.artifactory_credentials file")
	@exit 1
endif
ifndef user
	$(call err, "Variable 'user' is not defined in $(HOME)/.artifactory_credentials file")
	@exit 1
endif
ifndef password
	$(call err, "Variable 'password' is not defined in $(HOME)/.artifactory_credentials file")
	@exit 1
endif

check_gerrit:
ifeq (,$(wildcard $(HOME)/.gerrit_credentials))
	$(call err, ">>> File $(HOME)/.gerrit_credentials does not exist!")
	@exit 1
endif
ifndef gerritHost
	$(call err, "Variable 'gerritHost' is not defined in $(HOME)/.gerrit_credentials file")
	@exit 1
endif
ifndef gerritPort
	$(call err, "Variable 'gerritPort' is not defined in $(HOME)/.gerrit_credentials file")
	@exit 1
endif
ifndef gerritUser
	$(call err, "Variable 'gerritUser' is not defined in $(HOME)/.gerrit_credentials file")
	@exit 1
endif
