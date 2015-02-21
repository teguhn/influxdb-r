\name{influxdb.query}
\alias{influxdb.query}
\title{Query an InfluxDB database}
\usage{
  influxdb.query(conn,
    query, time_precision = c("s", "m", "u"))
}
\arguments{
  \item{conn}{A named list containing values of host, port, username, password, and database}
  \item{query}{Character vector containing the InfluxDB
  query}

  \item{time_precision}{Specifies whether the time should
  be returned in seconds (\code{s}), milliseconds
  (\code{m}), or microseconds (\code{u}) from epoch
  (January 1, 1970, 00:00:00 UTC).}
}
\value{
  A named list of data frames, where the names are the
  series names, and the data frames contain the points.
}
\description{
  Query an InfluxDB database
}

