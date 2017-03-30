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

ctx <- NULL
channels <- NULL
charts <- NULL

#' @import rJava
neptuneInit <- function (pkgname, arguments) {
  ctx <<- J("io.deepsense.neptune.clientlibrary.NeptuneContextFactory")$createContext(arguments)
  channels <<- new(J("java.util.HashMap"))
  charts <<- new(J("java.util.HashMap"))
  libraryNamespace <- getNamespace(pkgname)
  reg.finalizer(libraryNamespace, neptuneFinalizer, onexit = TRUE)
}

neptuneFinalizer <- function (context) {
    neptuneContext()$dispose()
}

neptuneContext <- function () {
  if (is.null(ctx)) {
    stop("Neptune Context is not initialized!")
  } else {
    ctx
  }
}

#' Get the job id
#'
#' Gets the job id.
#'
#' @return The job's id.
#'
#' @export
jobId <- function () {
  neptuneContext()$getJob()$getId()$toString()
}

#' Get storage location
#'
#' Gets the location of a directory where the snapshot of job's source code
#' and configuration is copied when the job is run.
#'
#' @return Storage location.
#'
#' @export
storageUrl <- function () {
  neptuneContext()$getStorageUrl()$getSchemeSpecificPart()
}

#' Get metric channel name
#'
#' Gets metric channel name, if metric has been declared in config or NULL otherwise.
#' Metric declares a channel, values of which, are used to compare jobs within an experiment.
#'
#' @return The metric channel name.
#'
#' @examples
#' \donttest{
#' metricChannelNameValue <- metricChannelName()
#' }
#'
#' @export
metricChannelName <- function () {
  metric <- neptuneContext()$getMetric()$orElse(NULL)
  mapNullable(metric, function(metric) { metric$getChannelName() })
}

#' Get metric direction
#'
#' Gets metric direction, if metric has been declared in config or NULL otherwise.
#' Metric declares a channel, values of which, are used to compare jobs within an experiment.
#'
#' @return The metric direction. One of: "maximize" or "minimize".
#'
#' @examples
#' \donttest{
#' metricDirectionValue <- metricDirection()
#' }
#'
#' @export
metricDirection <- function () {
  metric <- neptuneContext()$getMetric()$orElse(NULL)
  mapNullable(metric, function(metric) { metric$getMetricDirection()$toString() })
}

mapNullable <- function(nullable, getter) {
  if (is.null(nullable)) {
    result <- NULL
  } else {
    result <- getter(nullable)
  }
  result
}

#' Get parameter by name
#'
#' Gets the parameter of the job with a given parameterName.
#' Parameters are a set of user-defined variables that will be passed to the job's program.
#' Job's parameters are defined in the configuration file.
#' Parameters' values can be passed to a job using command line parameters
#' when enqueuing or executing the job.
#'
#' @param parameterName Name of the parameter to retrieve.
#' @return The parameter's value.
#'
#' @examples
#' \donttest{
#' x <- params("x")
#' }
#'
#' @export
params <- function (parameterName) {

  if (!neptuneContext()$getParams()$containsKey(parameterName)) {
    stop(sprintf(paste("neptune: Trying to access the '%s' parameter which is not defined.\n",
    "          In order to run a Neptune job offline, you need to provide all parameters\n",
    "          via command line or offlineParams function."),
    parameterName))
  }

  parameter <- neptuneContext()$getParams()$get(parameterName)
  parameterType <- parameter$getType()$toString()

  if (parameterType == "double") {
    parameter$getValue()$asDouble()$orElse(NULL)
  } else if (parameterType == "int") {
    parameter$getValue()$asInteger()$orElse(NULL)
  } else if (parameterType == "boolean") {
    parameter$getValue()$asBoolean()$orElse(NULL)
  } else if (parameterType == "string") {
    parameter$getValue()$asString()$orElse(NULL)
  } else {
    stop(paste("Unsupported parameter type:", parameterType))
  }
}

#' Set offline parameters
#'
#' Sets offline parameters of the job with given parameters.
#' Parameters are a set of user-defined variables that will be passed to the job's program.
#' Supplied parameters are ignored if job is running in online context.
#'
#' @param ... offline job parameters of the job.
#' @examples
#' \donttest{
#' offlineParams(parameterName1 = "paramterValue1", parameterValue2 = "parameterValue2")
#' }
#'
#' @export
offlineParams <- function (...) {
  params <- neptuneContext()$getParams()
  if (params %instanceof% "io.deepsense.neptune.clientlibrary.models.impl.parameters.OfflineJobParameters") {
    offlineParams <- list(...)
    for (parameterName in names(offlineParams)) {
      if (!params$containsKey(parameterName)) {
        rawValue <- offlineParams[[parameterName]]
        parameterValue <- switch(typeof(rawValue),
          "logical" = new(J("java.lang.Boolean"), rawValue),
          "integer" = new(J("java.lang.Integer"), rawValue),
          "double" = new(J("java.lang.Double"), rawValue),
          "character" = new(J("java.lang.String"), rawValue))
        params$put(parameterName, parameterValue)
      }
    }
  } else {
    warning(paste("Warning: Ignoring job parameters passed to neptuneContext."))
  }
}

#' Create a new numeric channel
#'
#' Creates a new numeric channel with a given channelName and extra parameters.
#' A channel is a named series of two-dimensional points belonging to a job.
#' Channels can be defined only from the job's source code.
#' Each point's abscissa (point's X) is a floating point number.
#' The ordinate's (point's Y) is also represented by a floating point number.
#' The points, called channel's values, represent a function,
#' so X-coordinates have to be unique in a channel.
#' Moreover, the points generated by jobs during execution must be in order
#' so that the X-coordinates increase.
#'
#' @param channelName Name of the channel.
#' @param isHistoryPersisted If True, all values sent to the channel are memorized.
#'   Otherwise only the last value is available.
#' @examples
#' \donttest{
#' createNumericChannel("numericChannel1")
#' }
#'
#' @export
createNumericChannel <- function (channelName, isHistoryPersisted = TRUE) {
  channel <- neptuneContext()$getJob()$createNumericChannel(
    channelName,
    J("java.lang.Boolean")$valueOf(isHistoryPersisted))
  channels$put(channelName, channel)
  invisible()
}

#' Create a new text channel
#'
#' Creates a new text channel with a given channelName and extra parameters.
#' A channel is a named series of two-dimensional points belonging to a job.
#' Channels can be defined only from the job's source code.
#' Each point's abscissa (point's X) is a floating point number.
#' The ordinate's (point's Y) is represented by any text value.
#' The points, called channel's values, represent a function,
#' so X-coordinates have to be unique in a channel.
#' Moreover, the points generated by jobs during execution must be in order
#' so that the X-coordinates increase.
#'
#' @param channelName Name of the channel.
#' @param isHistoryPersisted If True, all values sent to the channel are memorized.
#'   Otherwise only the last value is available.
#' @examples
#' \donttest{
#' createTextChannel("textChannel")
#' }
#'
#' @export
createTextChannel <- function (channelName, isHistoryPersisted = TRUE) {
  channel <- neptuneContext()$getJob()$createTextChannel(
    channelName,
    J("java.lang.Boolean")$valueOf(isHistoryPersisted))
  channels$put(channelName, channel)
  invisible()
}

#' Create a new image channel
#'
#' Creates a new image channel with a given channelName.
#' A channel is a named series of two-dimensional points belonging to a job.
#' Channels can be defined only from the job's source code.
#' Each point's abscissa (point's X) is a floating point number.
#' The ordinate's (point's Y) is represented by an image with name and description.
#' The points, called channel's values, represent a function,
#' so X-coordinates have to be unique in a channel.
#' Moreover, the points generated by jobs during execution must be in order
#' so that the X-coordinates increase.
#'
#' @param channelName Name of the channel.
#' @examples
#' \donttest{
#' createImageChannel("imageChannel")
#' }
#'
#' @export
createImageChannel <- function (channelName) {
  channel <- neptuneContext()$getJob()$createImageChannel(channelName)
  channels$put(channelName, channel)
  invisible()
}

#' Create neptuneImage
#'
#' Creates neptuneImage.
#' Neptune image represents information about images sent to image channels.
#'
#' @param name The name of this image.
#' @param description The description of this image.
#' @param data The data of this image.
#' @return Image representation that can be sent to Neptune image channels.
#' @examples
#' \donttest{
#' createImageChannel("imageChannel")
#' channelSend("imageChannel",
#'    0.5, neptuneImage("name", "description", readPNG("rSmokeTest/sample_image.png")))
#' }
#'
#' @export
neptuneImage <- function (name, description, data) {
  new(J("io.deepsense.neptune.clientlibrary.models.NeptuneImage"),
    name,
    description,
    normalizedMatrixToBufferedImage(data))
}

normalizedMatrixToBufferedImage <- function (normalizedRgbMatrix) {
  matrixDimensions <- dim(normalizedRgbMatrix)
  height <- matrixDimensions[1]
  width <- matrixDimensions[2]

  plainRgbMatrix <- normalizedRgbMatrix * 255
  plainRgbMatrixWithSwappedDimensions <- aperm(plainRgbMatrix, c(3, 2, 1))
  imageDataInRasterCompatibleFormat <- .jarray(as.integer(as.vector(plainRgbMatrixWithSwappedDimensions)))

  bufferedImage <- new(J("java.awt.image.BufferedImage"),
    as.integer(width),
    as.integer(height),
    J("java.awt.image.BufferedImage")$TYPE_INT_RGB)

  bufferedImage$getRaster()$setPixels(0L, 0L, width, height, imageDataInRasterCompatibleFormat)

  bufferedImage
}

#' Send a channel value to Neptune
#'
#' Given values of X and Y, sends a channel value to Neptune.
#'
#' @param channelName Name of the channel.
#' @param x The value of channel value's X-coordinate.
#'     Values of the x parameter should be strictly increasing for consecutive calls.
#' @param y The value of channel value's Y-coordinate.
#'     Accepted types: numeric for numeric channels, character for text channels, neptuneImage for image channels.
#' @examples
#' \donttest{
#' createNumericChannel("numericChannel")
#' channelSend("numericChannel", 2, 2)
#'
#' createTextChannel("textChannel")
#' channelSend("textChannel", 1, "1")
#'
#' createImageChannel("imageChannel")
#' channelSend("imageChannel",
#'   0.5, neptuneImage("name", "description", readPNG("rSmokeTest/sample_image.png")))
#' }
#'
#' @export
channelSend <- function (channelName, x, y) {
  channel <- channels$get(channelName)
  numericX <- as.numeric(x)
  channel$send(numericX, channelValueToJava(channel$getType()$toString(), y))
  invisible()
}

channelValueToJava <- function (channelType, channelValue) {
  if (channelType == "numeric" && !is.null(channelValue)) {
    numericChannelValue <- as.numeric(channelValue)
    new(J("java.lang.Double"), numericChannelValue)
  } else {
    channelValue
  }
}

#' Create a new chart
#'
#' Creates a new chart that groups values of one or more numeric channels.
#'
#' @param chartName Unique chart name.
#' @param series A list with definitions of series. You can define series with:
#' \itemize{
#'     \item a list containing the channel name and the series type,
#'     \item a channel name (the series type will be LINE).
#'  }
#'  Series type can be either "LINE" or "DOT".
#'
#' @examples
#' \donttest{
#' createChart(
#'    chartName = "chart",
#'    series = list("numericChannel1","numericChannel2"))
#'
#' createChart(
#'   chartName = "chart2",
#'   series = list(
#'     "series1" = "numericChannel1",
#'     "series2" = "numericChannel2"))
#'
#' createChart(
#'   chartName = "chart3",
#'   series = list(
#'     "series1" = list(channel="numericChannel1", type="LINE"),
#'     "series2" = list(channel="numericChannel2", type="DOT")))
#' }
#'
#' @export
createChart <- function (chartName, series) {
  seriesMap <-
    if (length(series) == 0) {
      new(J("java.util.ArrayList"))
    } else if (is.null(names(series))) {
      createSeriesMapWithDefaultNames(series)
    } else {
      createSeriesMapWithCustomNames(series)
    }

  chart <- neptuneContext()$getJob()$createChart(chartName, seriesMap)
  charts$put(chartName, chart)
  invisible()
}


#' Add a series to a chart
#'
#' Adds a new series specified by a name and a channel to the chart.
#'
#' @param chart Name of the chart the series will be added to.
#' @param name Name of the added series
#' @param channel Name of the channel of the series
#' @param type (Optional) Type of the series.
#'  Series type can be either "LINE" or "DOT". (default "LINE")
#'
#' @examples
#' \donttest{
#' addSeries(
#'    chart = "chart",
#'    name = "newSeries",
#'    channel = "numericChannel1")
#'
#' addSeries(
#'    chart = "chart2",
#'    name = "numericChannel2Series",
#'    channel = "numericChannel2",
#'    type = "DOT")
#' }
#'
#' @export
addSeries <- function (chart, name, channel, type="LINE") {
  chartObject <- charts$get(chart)
  channelObject <- channels$get(channel)
  typeObject <- J("io.deepsense.neptune.clientlibrary.models.ChartSeriesType")$valueOf(type)
  chartObject$addSeries(name, channelObject, typeObject)
}

createSeriesMapWithDefaultNames <- function (series) {
  seriesCollection <- new(J("java.util.ArrayList"))
  for (i in 1:length(series)) {
    seriesAttrs <- getSeriesAttributes(series[[i]])
    channelName <- seriesAttrs[[1]]
    seriesType <- seriesAttrs[[2]]
    newSeries <- new(J("io.deepsense.neptune.clientlibrary.models.ChartSeries"), channelName, channels$get(channelName), seriesType)
    seriesCollection$add(newSeries)
  }
  seriesCollection
}

createSeriesMapWithCustomNames <- function (series) {
  seriesCollection <- new(J("java.util.ArrayList"))
  for (seriesName in names(series)) {
    seriesAttrs <- getSeriesAttributes(series[[seriesName]])
    channelName <- seriesAttrs[[1]]
    seriesType <- seriesAttrs[[2]]
    newSeries <- new(J("io.deepsense.neptune.clientlibrary.models.ChartSeries"), seriesName, channels$get(channelName), seriesType)
    seriesCollection$add(newSeries)
  }
  seriesCollection
}

getSeriesAttributes <- function (seriesDescription) {
  if(is.list(seriesDescription)) {
    channelName <- seriesDescription[["channel"]]
    if("type" %in% names(seriesDescription)) {
      seriesTypeName <- seriesDescription[["type"]]
      seriesType <- J("io.deepsense.neptune.clientlibrary.models.ChartSeriesType")$valueOf(seriesTypeName)
    } else {
      seriesType <- J("io.deepsense.neptune.clientlibrary.models.ChartSeriesType")$LINE
    }
  } else {
    channelName <- seriesDescription
    seriesType <- J("io.deepsense.neptune.clientlibrary.models.ChartSeriesType")$LINE
  }
  list(channelName, seriesType)
}

#' Return the job's tags
#'
#' Returns the job's tags.
#' A tag is a word that contains only lowercase letters, numbers, underscores and dashes.
#' Tags can be assigned to a job or removed from a job anytime throughout job's lifetime.
#' When listing jobs, it is possible to search by tags, so tags are useful to mark jobs.
#' Job's tags can be set from both the configuration file and job's code or by command line parameters.
#'
#' @return Tags of the job.
#' @examples
#' \donttest{
#' print(tags())
#' tags <- tags()
#' tag <- tags[[1]]
#' }
#'
#' @export
tags <- function () {
  lapply(neptuneContext()$getJob()$getTags(), function (tag) { tag$toString() })
}

#' Add tags to the job
#'
#' Adds tags to the job.
#' A tag is a word that contains only lowercase letters, numbers, underscores and dashes.
#' Tags can be assigned to a job or removed from a job anytime throughout job's lifetime.
#' When listing jobs, it is possible to search by tags, so tags are useful to mark jobs.
#' Job's tags can be set from both the configuration file and job's code or by command line parameters.
#'
#' @param ... Tags to add to the job.
#' @examples
#' \donttest{
#' addTags("tag1", "tag2", "tag3")
#' }
#'
#' @export
addTags <- function (...) {
  newTags <- list(...)
  newTagsJava <- new(J("java.util.HashSet"))

  for (i in 1:length(newTags)) {
    newTagsJava$add(newTags[[i]])
  }

  neptuneContext()$getJob()$getTags()$addAll(newTagsJava)
  invisible()
}

#' Remove tags from the job
#'
#' Removes tags from the job.
#' A tag is a word that contains only lowercase letters, numbers, underscores and dashes.
#' Tags can be assigned to a job or removed from a job anytime throughout job's lifetime.
#' When listing jobs, it is possible to search by tags, so tags are useful to mark jobs.
#' Job's tags can be set from both the configuration file and job's code or by command line parameters.
#'
#' @param ... Tags to remove from the job.
#' @examples
#' \donttest{
#' removeTags("tag2", "tag3")
#' }
#'
#' @export
removeTags <- function (...) {
  tagsToRemove = list(...)
  tagsToRemoveJava <- new(J("java.util.HashSet"))

  for (i in 1:length(tagsToRemove)) {
    tagsToRemoveJava$add(tagsToRemove[[i]])
  }

  neptuneContext()$getJob()$getTags()$removeAll(tagsToRemoveJava)
  invisible()
}

#' Get properties of the job
#'
#' Gets the set of user-defined properties of the job.
#' Properties are additional metadata of the job.
#' A property is defined as a key-value pair of two strings.
#' Job's properties can be set from the configuration file and job's code
#' or by command line parameters.
#'
#' @return Properties of the job.
#' @examples
#' \donttest{
#' print(properties())
#' props <- properties()
#' prop <- props[["propertyName"]]
#' }
#'
#' @export
properties <- function () {
  propertiesAsEntries <- neptuneContext()$getJob()$getProperties()$entrySet()
  fetchedProperties <- lapply(propertiesAsEntries, function (keyValue) {
    keyValue$getValue()
  })
  names(fetchedProperties) <- lapply(propertiesAsEntries, function (keyValue) {
    keyValue$getKey()
  })
  fetchedProperties
}

#' Add properties to the job
#'
#' Adds properties to the job.
#' Properties are additional metadata of the job.
#' A property is defined as a key-value pair of two strings.
#' Job's properties can be set from the configuration file and job's code
#' or by command line parameters.
#'
#' @param ... Properties to add to the job.
#' @examples
#' \donttest{
#' addProperties(prop1 = "value1", prop2 = "value2", prop3 = "value3")
#' }
#'
#' @export
addProperties <- function (...) {
  propertiesToAdd = list(...)
  propertiesToAddJava = new(J("java.util.HashMap"))

  for (key in names(propertiesToAdd)) {
    propertiesToAddJava$put(key, propertiesToAdd[[key]])
  }

  neptuneContext()$getJob()$getProperties()$putAll(propertiesToAddJava)
  invisible()
}

#' Remove properties from the job
#'
#' Removes properties from the job.
#' Properties are additional metadata of the job.
#' A property is defined as a key-value pair of two strings.
#' Job's properties can be set from the configuration file and job's code
#' or by command line parameters.
#'
#' @param ... Properties to remove from the job.
#' @examples
#' \donttest{
#' removeProperties("prop2", "prop3")
#' }
#'
#' @export
removeProperties <- function (...) {
  keysToRemove = list(...)
  keysToRemoveJava = new(J("java.util.HashSet"))

  for (i in length(keysToRemove)) {
    keysToRemoveJava$add(keysToRemove[[i]])
  }

  neptuneContext()$getJob()$getProperties()$keySet()$removeAll(keysToRemoveJava)
  invisible()
}
