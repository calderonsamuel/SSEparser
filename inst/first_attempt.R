# Based on https://github.com/mpetazzoni/sseclient/blob/master/sseclient/__init__.py
# Use "https://postman-echo.com/server-events/10" to test

# See HTML spec: https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events

httr2::request("https://postman-echo.com/server-events/10") %>%
	httr2::req_body_json(data = list(
		event = "message",
		request = "POST"
	)) %>%
	httr2::req_perform_stream(callback = \(x) {
		x %>% rawToChar() %>% cat()
		TRUE
	})


# Define SSEClient R6 class
SSEClient <- R6Class(
	"SSEClient",
	public = list(
		eventSource = NULL,

		initialize = function(url, char_enc = "UTF-8") {
			private$eventSource <-
				httr::GET(url, httr::add_headers(Accept = "text/event-stream"))
			private$charEnc <- char_enc
		},

		read = function() {
			data <- raw()
			while (TRUE) {
				chunk <-
					httr::content(
						private$eventSource,
						as = "raw",
						encoding = NULL,
						type = "text"
					)
				lines <-
					strsplit(as.character(chunk), "\r\n", fixed = TRUE)[[1]]

				for (line in lines) {
					data <- paste0(data, line, "\r\n")
					if (grepl("\r\n\r\n$", data)) {
						return(data)
					}
				}
			}
		},

		events = function() {
			while (TRUE) {
				chunk <- private$read()
				if (length(chunk) == 0)
					break

				event <- private$parseEvent(chunk)
				if (event$data != "") {
					cat(sprintf("Dispatching %s event...\n", event$event))
					yield(event)
				}
			}
		},

		parseEvent = function(chunk) {
			lines <- strsplit(chunk, "\r\n", fixed = TRUE)[[1]]
			event <- R6::R6Class(
				"Event",
				public = list(
					id = NULL,
					event = "message",
					data = "",
					retry = NULL,
					initialize = function() {
					}
				)
			)

			for (line in lines) {
				if (line == "") {
					next
				}

				if (startsWith(line, ":")) {
					next
				}

				parts <- strsplit(line, ":", fixed = TRUE)[[1]]
				field <- parts[1]
				value <-
					ifelse(length(parts) > 1, substr(parts[2], 2, nchar(parts[2])), "")

				if (field == "data") {
					event$data <- paste0(event$data, value, "\n")
				} else {
					event[[field]] <- value
				}
			}

			if (endsWith(event$data, "\n")) {
				event$data <- substr(event$data, 1, nchar(event$data) - 1)
			}

			return(event)
		},

		close = function() {
			httr::stop_for_status(private$eventSource)
		}
	)
)

# Example Usage:
# Replace 'YOUR_SSE_ENDPOINT' with the actual SSE endpoint URL
sseClient <- SSEClient$new("YOUR_SSE_ENDPOINT")
events <- sseClient$events()
while (!identical(events$state, "exited")) {
	Sys.sleep(1)
}
