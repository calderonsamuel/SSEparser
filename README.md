
<!-- README.md is generated from README.Rmd. Please edit that file -->

# SSEparser

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/SSEparser)](https://CRAN.R-project.org/package=SSEparser)
[![R-CMD-check](https://github.com/calderonsamuel/SSEparser/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/calderonsamuel/SSEparser/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/calderonsamuel/SSEparser/branch/main/graph/badge.svg)](https://app.codecov.io/gh/calderonsamuel/SSEparser?branch=main)
<!-- badges: end -->

The goal of SSEparser is to provide robust functionality to parse
Server-Sent Events and to build on top of it.

## Installation

You can install `SEEparser` from CRAN like so:

``` r
install.packages("gptstudio")
```

Alternatively, you can install the development version like so:

``` r
pak::pak("calderonsamuel/SSEparser")
```

## Example

The `parse_sse()` function takes a string containing a server-sent event
and converts it to a R list.

``` r
library(SSEparser)

event <- "data: test\nevent: message\nid: 123\n\n"

parse_sse(event)
#> [[1]]
#> [[1]]$data
#> [1] "test"
#> 
#> [[1]]$event
#> [1] "message"
#> 
#> [[1]]$id
#> [1] "123"
```

Comments are usually received in a line starting with a colon. They are
not parsed.

``` r
with_comment <- "data: test\n: comment\nevent: example\n\n"

parse_sse(with_comment)
#> [[1]]
#> [[1]]$data
#> [1] "test"
#> 
#> [[1]]$event
#> [1] "example"
```

## Use in HTTP requests

`parse_sse()` wraps the `SSEparser` R6 class, which is also exported to
be used with real-time streaming data. The following code handles a
request with MIME type “text/event-stream”.

``` r
parser <- SSEparser$new()
response <- httr2::request("https://postman-echo.com/server-events/3") %>%
    httr2::req_body_json(data = list(
        event = "message",
        request = "POST"
    )) %>%
    httr2::req_perform_stream(callback = \(x) {
        event <- rawToChar(x)
        parser$parse_sse(event)
        TRUE
    })

str(parser$events)
#> List of 3
#>  $ :List of 3
#>   ..$ event: chr "info"
#>   ..$ data : chr "{\"event\":\"message\",\"request\":\"POST\"}"
#>   ..$ id   : chr "1"
#>  $ :List of 3
#>   ..$ event: chr "error"
#>   ..$ data : chr "{\"event\":\"message\",\"request\":\"POST\"}"
#>   ..$ id   : chr "2"
#>  $ :List of 3
#>   ..$ event: chr "ping"
#>   ..$ data : chr "{\"event\":\"message\",\"request\":\"POST\"}"
#>   ..$ id   : chr "3"
```

## Extending SSEparser

Following the previous example, it should be useful to parse the content
of every `data` field to be also an R list instead of a JSON string. For
that, we can create a new R6 class which inherits from `SSEparser`. We
just need to overwrite the `append_parsed_sse()` method.

``` r
CustomParser <- R6::R6Class(
    classname = "CustomParser",
    inherit = SSEparser,
    public = list(
        initialize = function() {
            super$initialize()
        },
        append_parsed_sse = function(parsed_event) {
            parsed_event$data <- jsonlite::fromJSON(parsed_event$data)
            self$events = c(self$events, list(parsed_event))
            invisible(self)
        }
    )
)
```

Notice that the only thing we are modifying is the parsing of the data
field, not the parsing of the event itself. This is the the original
method from `SSEparser`:

``` r
SSEparser$public_methods$append_parsed_sse
#> function (parsed_event) 
#> {
#>     self$events <- c(self$events, list(parsed_event))
#>     invisible(self)
#> }
#> <bytecode: 0x000001933515c630>
#> <environment: namespace:SSEparser>
```

`CustomParser` uses `jsonlite::fromJSON()` to parse the data field of
every chunk in the event stream. We can now use our custom class with
the previous request[^1].

``` r
parser <- CustomParser$new()
response <- httr2::request("https://postman-echo.com/server-events/3") %>%
    httr2::req_body_json(data = list(
        event = "message",
        request = "POST"
    )) %>%
    httr2::req_perform_stream(callback = \(x) {
        event <- rawToChar(x)
        parser$parse_sse(event)
        TRUE
    })

str(parser$events)
#> List of 3
#>  $ :List of 3
#>   ..$ event: chr "info"
#>   ..$ data :List of 2
#>   .. ..$ event  : chr "message"
#>   .. ..$ request: chr "POST"
#>   ..$ id   : chr "1"
#>  $ :List of 3
#>   ..$ event: chr "ping"
#>   ..$ data :List of 2
#>   .. ..$ event  : chr "message"
#>   .. ..$ request: chr "POST"
#>   ..$ id   : chr "2"
#>  $ :List of 3
#>   ..$ event: chr "error"
#>   ..$ data :List of 2
#>   .. ..$ event  : chr "message"
#>   .. ..$ request: chr "POST"
#>   ..$ id   : chr "3"
```

Now instead of a JSON string we can have an R list in the data field
**while the stream is still in process**.

[^1]: This endpoint returns random event field names for each chunk in
    every request, so the response will not be exactly the same.
