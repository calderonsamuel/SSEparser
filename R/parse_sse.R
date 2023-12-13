#' Parse Server-Sent Events
#' 
#' This functions converts Server-Sent Events to a R list. 
#' A single string can contain multiple SSEs.
#' 
#' @param event A length 1 string containing a server sent event as specified in 
#' the [HTML spec](https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events).
#' 
#' @return An R list on which each element is an event
#' @export
#' 
#' @examples
#' event <- "data: test\nevent: message\nid: 123\n\n"
#' parse_sse(event)
#' 
#' with_comment <- "data: test\n: comment\nevent: example\n\n"
#' parse_sse(with_comment)
#' 
parse_sse <- function(event) {
	parser <- SSEparser$new()
	parser$parse_sse(event)
	
	parser$events
}
