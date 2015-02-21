#' @import httr
#' @import rjson
NULL

#' Query an InfluxDB database
#' 
#' @param conn A named list containing values of host, port, username, password, and database
#' @param query Character vector containing the InfluxDB query
#' @param time_precision Specifies whether the time should be returned in 
#'   seconds (\code{s}), milliseconds (\code{m}), or microseconds (\code{u}) 
#'   from epoch (January 1, 1970, 00:00:00 UTC).
#' @return A named list of data frames, where the names are the series names,
#'   and the data frames contain the points.
#'
#' @export
influxdb.query <- function(conn, query,
                        time_precision=c("s", "m", "u")) {
  response <- GET(
    "", scheme = "http", hostname = conn$host, port = conn$port,
    path = sprintf("db/%s/series", URLencode(conn$database)),
    query = list(
      u = conn$username,
      p = conn$password,
      q = query,
      time_precision = match.arg(time_precision),
      chunked = "false"
    )
  )
  
  # Check for error. Not familiar enough with httr, there may be other ways it
  # communicates failure.
  if (response$status_code < 200 || response$status_code >= 300) {
    if (length(response$content) > 0)
      warning(rawToChar(response$content))
    stop("Influx query failed with HTTP status code ", response$status_code)
  }
  
  response_data <- fromJSON(rawToChar(response$content))
  
  # response_data at this point is a hot mess of nested lists; turn it into
  # something nicer to work with. I'm sure there is a faster/better way to
  # do this.
  responseObjects <- sapply(response_data, function(seriesObj) {
    # TODO: Should stringsAsFactors be used or not?
    df <- as.data.frame(t(sapply(seriesObj$points, rbind)))
    # It's a data frame but each column is a list instead of atomic vector; 
    # let's fix that
    df <- as.data.frame(lapply(df, unlist))
    names(df) <- seriesObj$columns
    structure(list(df), names=seriesObj$name)
  })
  return(responseObjects)
}

#' Write a data frame into an InfluxDB database
#' 
#' @param conn A named list containing values of host, port, username, password, and database
#' @param series Character vector containing the series name
#' @param dataframe A data frame containing the points with the column names
#'
#' @export
influxdb.write <- function(conn, series, dataframe){
  
  seriesObj <- list()
  seriesObj$name <- series
  seriesObj$columns <- names(dataframe)
  seriesObj$points <- apply(dataframe, 1, function(x){unname(as.list(x))})
  bodyParam <- structure(list(seriesObj))
  
  response <- POST(
    "", scheme = "http", hostname = conn$host, port = conn$port,
    path = sprintf("db/%s/series", URLencode(conn$database)),
    query = list(
      u = conn$username,
      p = conn$password
    ),
    body = toJSON(bodyParam),
    encode = "json"
  )
  
  # Check for error. Not familiar enough with httr, there may be other ways it
  # communicates failure.
  if (response$status_code < 200 || response$status_code >= 300) {
    if (length(response$content) > 0)
      warning(rawToChar(response$content))
    stop("Influx query failed with HTTP status code ", response$status_code)
  }
}
