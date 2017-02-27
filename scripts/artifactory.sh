#!/bin/bash

set -e
#
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
#
CUSTOM_TAG="$1"

ARTIFACTORY_CREDENTIALS="$HOME/.artifactory_credentials"

ARTIFACTORY_USER=`grep "user=" $ARTIFACTORY_CREDENTIALS | cut -d '=' -f 2`
ARTIFACTORY_PASSWORD=`grep "password=" $ARTIFACTORY_CREDENTIALS | cut -d '=' -f 2`
ARTIFACTORY_URL="http://`grep "host=" $ARTIFACTORY_CREDENTIALS | cut -d '=' -f 2`"

function calculate_repository_url() {
  if [[ $IS_SNAPSHOT == true ]]
  then
    export REPOSITORY_URL="$ARTIFACTORY_URL/$SNAPSHOT_REPOSITORY/io/deepsense"
  else
    export REPOSITORY_URL="$ARTIFACTORY_URL/$RELEASE_REPOSITORY/io/deepsense"
  fi
}

function calculate_full_version() {
  echo "** Calculating version **"
  if [[ $IS_SNAPSHOT == true ]]
  then
    DATE=`date -u +%Y-%m-%d_%H-%M-%S`
    GIT_SHA=`git rev-parse HEAD`
    GIT_SHA_PREFIX=${GIT_SHA:0:7}
    export FULL_VERSION="${BASE_VERSION}-${DATE}-${GIT_SHA_PREFIX}"
  else
    export FULL_VERSION=${BASE_VERSION}
  fi
}

function artifactRemoteName() {
    component=$1
    artifactVersion=$2
    artifactRemoteName="${component}-${artifactVersion}.tar.gz"
}

function publish() {
  url=$3

  echo "** INFO: Uploading ${ARTIFACT_LOCAL_NAME} to ${url} **"
  md5Value="`md5sum "${ARTIFACT_LOCAL_NAME}"`"
  md5Value="${md5Value:0:32}"
  sha1Value="`sha1sum "${ARTIFACT_LOCAL_NAME}"`"
  sha1Value="${sha1Value:0:40}"

  curl -i -X PUT -u $ARTIFACTORY_USER:$ARTIFACTORY_PASSWORD \
   -H "X-Checksum-Md5: $md5Value" \
   -H "X-Checksum-Sha1: $sha1Value" \
   -T "${ARTIFACT_LOCAL_NAME}" \
   "${url}"
}

function publish_custom() {
  component=$1
  artifactVersion=$2
  inVersionPath=$3
  if [ -n "$inVersionPath" ]; then
    inVersionPath="$inVersionPath/"
  fi
  artifactRemoteName ${component} ${artifactVersion}
  publish ${component} ${artifactVersion} "${REPOSITORY_URL}/${component}/${inVersionPath}${component}-${artifactVersion}/${artifactRemoteName}"
}

function publish_latest() {
  publish_custom $1 latest
  if [[ $IS_SNAPSHOT == true ]]
  then
    publish_custom $1 latest ${BASE_VERSION}
  fi
}

function publish_version() {
  component=$1
  artifactVersion=$2
  artifactRemoteName ${component} ${artifactVersion}

  if [[ $IS_SNAPSHOT == true ]]
  then
    url="${REPOSITORY_URL}/${component}/$BASE_VERSION/${artifactVersion}/${artifactRemoteName}"
  else
    url="${REPOSITORY_URL}/${component}/${artifactVersion}/${artifactRemoteName}"
  fi
  publish $component $artifactVersion $url
}

function publish_branch_latest() {
  if [[ $IS_SNAPSHOT == true ]]
  then
    branchTag=`python scripts/get_branch_latest_tag.py`
    publish_custom $1 ${branchTag}
  fi
}

function publish_component() {
  publish_version $1 "${FULL_VERSION}"
  publish_branch_latest $1
  publish_latest $1
}

calculate_repository_url
calculate_full_version

if [ "${CUSTOM_TAG}" == "" ] ; then
  publish_component neptune
else
  publish_custom neptune "${CUSTOM_TAG}"
fi
