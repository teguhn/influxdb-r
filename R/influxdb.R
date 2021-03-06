#' @import httr
#' @import RJSONIO
NULL

#' Query an InfluxDB database
#' 
#' @param connection A named list containing values of host, port, username, password, and database
#' @param query Character vector containing the InfluxDB query
#' @param time_precision Specifies whether the time should be returned in 
#'   seconds (\code{s}), milliseconds (\code{m}), or microseconds (\code{u}) 
#'   from epoch (January 1, 1970, 00:00:00 UTC).
#' @return A named list of data frames, where the names are the series names,
#'   and the data frames contain the points.
#'
#' @export
influxdb.query <- function(connection, query, time_precision=c("s", "m", "u"), stringsAsFactors=FALSE) {
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
  
  check.reponse(response)
  
  response_data <- fromJSON(rawToChar(response$content), nullValue=NA)
  
  # response_data at this point is a hot mess of nested lists; turn it into
  # something nicer to work with. I'm sure there is a faster/better way to
  # do this.
  responseObjects <- sapply(response_data, function(seriesObj) {
    df <- as.data.frame(t(sapply(seriesObj$points, rbind)))
    # It's a data frame but each column is a list instead of atomic vector; 
    # let's fix that
    df <- as.data.frame(lapply(df, unlist), stringsAsFactors=stringsAsFactors)
    names(df) <- seriesObj$columns
    structure(list(df), names=seriesObj$name)
  })
  return(responseObjects)
}
drop_names <- function(x){
    x_list <- as.list(x)
    x_list[sapply(x_list, is.na)] <- list(NULL) ## Transforms NA values into NULL. This is required for toJSON  to provide the rigth representation of missing data
    names(x_list) <-NULL
    x_list
}

#' Write a data frame into an InfluxDB database
#' 
#' @param connection A named list containing values of host, port, username, password, and database
#' @param series.name Character vector containing the series name
#' @param dataframe A data frame containing the points with the column names
#'
#' @export
influxdb.write <- function(connection, series.name, dataframe, time_precision=c("s", "m", "u")){
  
  seriesObj <- list()
  seriesObj$name <- series.name
  seriesObj$columns <- names(dataframe)
  split_list <- split(dataframe, 1:nrow(dataframe)) 
  
  # We need to drop all names from the points structure 
  # for json output
  seriesObj$points<-mapply(drop_names,split_list,USE.NAMES = FALSE,SIMPLIFY = FALSE)
  bodyParam <- structure(list(seriesObj))
  
  response <- POST(
    "", scheme = "http", hostname = conn$host, port = conn$port,
    path = sprintf("db/%s/series", URLencode(conn$database)),
    query = list(
      u = conn$username,
      p = conn$password,
      time_precision = match.arg(time_precision)
    ),
    body = toJSON(bodyParam),
    encode = "json"
  )
  
  check.reponse(response)

}
check.reponse <- function(response){
  # Check for error. Not familiar enough with httr, there may be other ways it
  # communicates failure.
  if (response$status_code < 200 || response$status_code >= 300) {
    if (length(response$content) > 0)
      warning(rawToChar(response$content))
    stop("Influx query failed with HTTP status code ", response$status_code)
  }
}