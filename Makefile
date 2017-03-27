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

include common.mk

GIT_BRANCH=$(shell git branch | $(GREP) '*' | $(CUT) -d ' ' -f 2)
PROJECT_NAME="neptune"
PROJECT_MODULE="client"
VERSION_FILE="neptune/DESCRIPTION"
VERSION=$(shell $(GREP) Version $(VERSION_FILE) | $(CUT) -d " " -f 2)

USAGE="USAGE: make command [parameters]\n \
	commands:\n \
	usage \t\t- \tprint this message\n \
	clean \t\t- \tclean environment (built artifacts, docker images, temporary files)\n \
	build \t\t- \tbuild project\n \
	publish \t- \tpublish built artifact to Artifactory\n \
	\t\t\t\tparameters:\n \
	\t\t\t\t\trelease=true|false - indicates whether you're publishing release version of an artifact or snapshot\n \
	release \t- \trelease new version (bump project version, tag release branch, build project, build docker image)\n \
	\t\t\t\tparameters:\n \
	\t\t\t\t\tversion=x.y.z - project's version you want to release (format: x.y.z)"

usage:
	$(call printMsg, $(USAGE), $(COLOR_WHITE))

release:
	$(call inf, ">>> Releasing version $(version)")
ifndef version
	$(call err, ">>> No release version specified!")
	@exit 1
endif
	@$(MAKE) prepare clean set_version version=$(version) build commit_version tag_version publish release=true
	$(call inf, ">>> Version $(version) released")

all: build

prepare:
	$(call inf, ">>> Checking prerequisities")
	$(GIT) --version
	$(RSCRIPT) --version
	$(PYTHON) --version
	$(SSH) -V
	pip install -r test_requirements.txt
	$(call inf, ">>> All prerequisites are met")

download_java_library:
	$(call inf, ">>> Obtaining Java client library")
	$(PYTHON) scripts/download_java_client_uberjar.py || scripts/build_java_client_uberjar_from_maven.sh
	$(call inf, ">>> Java client library obtained")

install_r_libraries:
	$(call inf, ">>> Installing R libraries")
	$(RSCRIPT) --vanilla requirements.R
	$(call inf, ">>> R libraries installed")

build: prepare clean download_java_library install_r_libraries
	$(call inf, ">>> Building R client library")
	$(MKDIR) -p dist
	$(MKDIR) -p neptune/inst/java
	$(CP) $(JAVA_CLIENT_UBERJAR_LOCATION) $(INTEGRATED_JAVA_CLIENT_LOCATION)
	(cd neptune $(CMD_SEP) R -e "library(devtools);document()")
	(cd neptune $(CMD_SEP) R -e "library(devtools);build()")
	(cd neptune $(CMD_SEP) R -e "library(devtools);check()")
	$(MV) neptune_$(VERSION).tar.gz dist/
	$(call inf, ">>> R client library built")

clean:
	$(call inf, ">>> Performing environment cleaning")
	-R CMD REMOVE neptune
	$(RM) -rf build
	$(RM) -rf dist
	$(RM) -f neptune/inst/java/java-client-library.jar
	$(RM) -rf neptune/man
	$(call inf, ">>> Environment cleaned")

publish: check_artifactory
	$(call inf, ">>> Publishing built artifacts to Artifactory")
ifndef release
	$(call err, ">>> You must define define release=true|false!")
	@exit 1
endif
ifeq ($(release),true)
	($(EXPORT) BASE_VERSION=$(VERSION) $(CMD_SEP) scripts/publish_release.sh)
else
	($(EXPORT) BASE_VERSION=$(VERSION) $(CMD_SEP) scripts/publish_snapshot.sh)
endif
	$(call inf, ">>> Artifacts published")

set_version:
	$(call inf, ">>> Setting project version to $(version) in $(VERSION_FILE)")
ifndef version
	$(call err, ">>> No release version specified!")
	@exit 1
endif
	$(SED) -ri "s/^Version:.*/Version: $(version)/g" $(VERSION_FILE)
	$(call inf, ">>> Project version set to $(version)")

commit_version: check_gerrit
	$(call inf, ">>> Pushing new version to remote")
	$(GIT) add $(VERSION_FILE)
	$(GIT) commit -m "Release version $(VERSION)"
	$(GIT) push origin HEAD:refs/publish/$(GIT_BRANCH)
	$(SSH) -p $(gerritPort) $(gerritUser)@$(gerritHost) gerrit review --verified +1 --code-review +2 --submit --project $(PROJECT_NAME)-$(PROJECT_MODULE) `git rev-parse HEAD`
	$(call inf, ">>> Version $(VERSION) pushed to remote")

tag_version: check_gerrit
	$(call inf, ">>> Tagging repository")
	$(call inf, ">>> Creating new tag: release-r-$(VERSION)")
	$(GIT) tag -a "release-r-$(version)" -m "Release R $(VERSION)"
	$(call inf, ">>> Pushing tag release-r-$(VERSION) to remote")
	$(GIT) push origin release-r-$(VERSION)
	$(call inf, ">>> Repository tagged")

tests: build
	R CMD INSTALL dist/neptune_$(VERSION).tar.gz
