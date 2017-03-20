# Neptune Client Library for R

## Description

This repository contains sources of Neptune Client Library for R. You need to import this library
in the R code you want to run as a Neptune job.

You can find the example R jobs in [neptune-examples](https://github.com/deepsense-io/neptune-examples/tree/1.4/r).

You can read more about Neptune - the machine learning platform - in [the documentation](http://neptune.deepsense.io/versions/1.4/).

## Prerequisites

* R (3.3.2+)
* devtools (1.12.0+)
* rJava (0.9_8+)

* Python (2.7.x)
* virtualenv

* Oracle JDK 8
* Gradle (2.9+)

### Hints

To install devtools, you need to install the following binary packages:

* **Debian and Ubuntu**: libssl-dev libssh2-1-dev libcurl4-openssl-dev
* **Fedora, CentOS and RHEL:** openssl-devel libssh2-devel libcurl-devel
* **OS X**: openssl libssh2

To install rJava, you need to configure the binding between R and Java:

`sudo sh -c 'export JDK_HOME=<path to your Java JDK installation>; export JAVA_HOME=$JDK_HOME/jre; R CMD javareconf'`

If rJava module fails to load with a message that `libjava.so` was not found,
you may need to configure the `LD_LIBRARY_PATH` environment variable to add a path that contains this file.
This environment variable has to be always set, so you may add it to your `~/.bashrc` file.
Here is a script that fixes this issue, assuming that your Java is linked to `/usr/lib/java/default-java` directory:

`export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib/jvm/default-java/jre/lib/amd64:/usr/lib/jvm/default-java/jre/lib/amd64/server"`

It's recommended to use `virtualenv` when building the Client Library.

Make sure you have set the [`R_LIBS_USER`](https://csg.sph.umich.edu/docs/R/localpackages.html)
environment variable to a path in your home directory. If you don't, you'll need to run
the following commands with root privileges.

Run:

```
make build
```

You will find the packaged Client Library in the `dist/` directory.

## Installing the Client Library

You can install the Client Library in the terminal window:

```
R CMD INSTALL dist/neptune_1.4.1.tar.gz
```

or in the R console:

```
> install.packages("<absolute path to the .tar.gz file with the Client Library>")
```

## Examples

### Loading the Client Library

```R
library(neptune)
```

### Accessing Job Information

```R
id <- jobId()
dumpDir <- dumpDirUrl()
```

### Accessing Parameters

```R
x <- params("x")
```

### Creating Channels

```R
createNumericChannel("numericChannel")
createTextChannel("textChannel")
createImageChannel("imageChannel")
```

### Sending Values To Channels

```R
channelSend("numericChannel", 1.0, 2.0)
channelSend(
    "imageChannel",
    1.0,
    neptuneImage("name", "description", readPNG("images/sample_image.png")))
```

### Accessing Metric Information

```R
name <- metricName()
channelName <- metricChannelName()
direction <- metricDirection()
```

### Creating Charts

```R
createChart(
    chartName = "chart",
    series = list("numericChannel1","numericChannel2"))
```

### Manipulating Tags

```R
addTags("tag1", "tag2", "tag3")
removeTags("tag2", tag3")
tagList <- tags()
```

### Manipulating Properties

```R
addProperties("property1" = "value1", "property2" = "value2", "property3" = "value3")
removeProperties("property2", "property3")
propertiesList <- properties()
```

## License

Copyright (c) 2017, deepsense.io

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
