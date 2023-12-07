# Based on https://github.com/mpetazzoni/sseclient/blob/master/sseclient/__init__.py
# Use "https://postman-echo.com/server-events/10" to test

# See HTML spec: https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events

buffer <- character()
httr2::request("https://postman-echo.com/server-events/5") %>%
	httr2::req_body_json(data = list(
		event = "message",
		request = "POST"
	)) %>%
	httr2::req_perform_stream(callback = \(x) {
		event <- rawToChar(x)
		buffer <<- c(buffer, event)
	})

parser <- SSEParser$new()
httr2::request("https://postman-echo.com/server-events/5") %>%
	httr2::req_body_json(data = list(
		event = "message",
		request = "POST"
	)) %>%
	httr2::req_perform_stream(callback = \(x) {
		event <- rawToChar(x)
		parser$parse_sse(event)
		TRUE
	})

parser$events

# Example Usage:
event_string <- "data: Hello, World!\nevent: custom-event\nid: 123\nretry: 1000\n\n"

events <- buffer |>
	stringr::str_split("\n\n") |>
	purrr::pluck(1L)

lines <- events[[1]] |>
	stringr::str_split("\n") |>
	purrr::pluck(1L)

parse_line <- function(line) {
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

parse_chunk <- function(chunk) {
	lines <- chunk |>
		stringr::str_split("\n") |>
		purrr::pluck(1L) 
	
	lines |> 
		purrr::map(parse_line) |> 
		purrr::compact() |> # ignore comments
		purrr::reduce(c, .init = list())
}

parse_ss_event <- function(event) {
	chunks <- event |> 
		stringr::str_split("\n\n") |>
		purrr::pluck(1L)
	
	chunks |> 
		purrr::map(parse_chunk) |> 
		purrr::discard(rlang::is_empty)
}
