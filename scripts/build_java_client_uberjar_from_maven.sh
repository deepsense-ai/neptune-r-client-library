#/bin/bash
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
set -eu

echo "Building Java client library from Maven..."
cd java-client-library

gradle wrapper
./gradlew clean
./gradlew uberjar

mkdir -p ../build
cp build/libs/java-client-library-all.jar ../build/java-client-library.jar

echo "Java client library built from Maven"
