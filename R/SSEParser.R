#' Parse a Server Sent Event
#' 
#' @description
#' This class can help you parse a single server sent event or a stream of them. 
#' You can inherit the class for a custom aplication. 
#' 
#' @param event A server sent event as specified in the [HTML spec](https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events).
#' 
#' @importFrom R6 R6Class
#' 
#' @export
SSEparser <- R6::R6Class(
	classname = "SSEparser",
	public = list(
		
		#' @field events List  that contains all the events parsed. When the class is initialized, is just an empty list.
		events = NULL,
		
		#' @description Takes a string representing that comes from a server sent event and parses it to an R list. 
		#' If you need finer control for parsing the data received, is better to utilize this method inside of a child class instead of overwriting it.
		parse_sse = function(event) {
			chunks <- event |> 
				stringr::str_split("\n\n") |>
				purrr::pluck(1L)
			
			parsed_chunks <-  chunks |> 
				purrr::map(private$parse_chunk) |> 
				purrr::discard(rlang::is_empty)
			
			self$events <- c(self$events, parsed_chunks)
			
			invisible(self)
		},
		
		#' @description Create a new SSE parser
		initialize = function() {
			self$events <- list()
		}
	),
	private = list(
		
		parse_chunk = function(chunk) {
			lines <- chunk |>
				stringr::str_split("\n") |>
				purrr::pluck(1L) 
			
			lines |> 
				purrr::map(private$parse_line) |> 
				purrr::discard(rlang::is_empty) |> # ignore comments
				purrr::reduce(c, .init = list())
		},
		
		parse_line = function(line) {
			# https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
			
			# If the line is empty (a blank line)
			# Dispatch the event. In our case, we just return NULL, to ignore it later
			if(line == "") return()
			
			# If the line starts with a U+003A COLON character (:) -> Ignore the line
			if (stringr::str_starts(line, ":")) return()
			
			# If the line contains a U+003A COLON character (:)
			# 1. Collect the characters on the line before the first (:), and let field be that string.
			# 2. Collect the characters on the line after the first (:), and let value be that string. 
			#    If value starts with a U+0020 SPACE character, remove it from value.
			output <- list()
			if (stringr::str_detect(line, ":")) {
				splitted <- stringr::str_split_1(line, ":")
				field <- splitted[1]
				value <- paste0(splitted[2:length(splitted)], collapse = ":") |> 
					stringr::str_trim("left")
			} else {
				field <- line
				value <- ""
			}
			
			# Otherwise, the string is not empty but does not contain a U+003A COLON character (:)
			# Process the field using the steps described below, using the whole line as the field name, 
			# and the empty string as the field value.
			output[[field]] <- value
			output
		}
	)
)
