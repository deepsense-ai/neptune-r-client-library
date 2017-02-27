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
import os
import urllib3
from urllib3.exceptions import RequestError

print("Downloading Java client library from Artifactory...")

version = open("java-client-version.txt").readline().rstrip()
is_version_snapshot = 'SNAPSHOT' in version

http = urllib3.PoolManager()

if is_version_snapshot:
    repository = 'neptune-java-client-snapshot'
else:
    repository = 'neptune-java-client-release'

artifactory_url = 'http://artifactory.deepsense.codilime.com:8081/artifactory/' + repository +\
    '/io/deepsense/neptune/neptune-client-library-uberjar/' + version +\
    '/neptune-client-library-uberjar-' + version + '.jar'

print 'Downloading {}'.format(artifactory_url)

try:
    r = http.request('GET', artifactory_url)

    build_directory = 'build/'
    if not os.path.isdir(build_directory):
        os.mkdir(build_directory)

    with open(build_directory + 'java-client-library.jar', 'wb') as jar:
        jar.write(r.data)

    print("Java client library downloaded from Artifactory")
except RequestError:
    print("Failed to connect to Artifactory!")
    exit(1)
