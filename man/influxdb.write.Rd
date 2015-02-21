\name{influxdb.write}
\alias{influxdb.write}
\title{Write a data frame to an InfluxDB database}
\usage{
  influxdb.write(conn, series, dataframe)
}
\arguments{
  \item{connection}{A named list containing values of host, port, username, password, and database}
  \item{series.name}{Character vector containing the series name}
  \item{dataframe}{A data frame containing the points with the column names}
}
\description{
  Write a data frame into an InfluxDB database
}
