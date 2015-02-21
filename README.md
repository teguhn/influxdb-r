influxdb-r
==========

R library for InfluxDB. Currently only supports querying.

Install using devtools:

```
> if (!require(devtools))
    install.packages('devtools')
> devtools::install_github('teguhn/influxdb-r')
```

Example usage:

```
> library(influxdb)
>conn <- list(
  host='sandbox.influxdb.org',
  port=9061,
  username='jcheng',
  password='xxxxxxxx',
  database='joetest'
)
> results <- influxdb.query(conn, 'SELECT * FROM /.*/')
$some_series
        time sequence_number             email state value
1 1386405189          802637       foo@bar.com    CO 191.3
2 1386405182          802636 paul@influxdb.org    NY    23

$some_series2
        time sequence_number        email state value
1 1386405625          802640 baz@quux.com    MA    63
> summary(results$some_series$value)
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  23.00   65.08  107.20  107.20  149.20  191.30 

> influxdb.write(conn, 'some_series', some_dataframe)
```