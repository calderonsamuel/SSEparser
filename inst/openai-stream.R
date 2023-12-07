stream_chat_completion <-
	function(messages = NULL,
			 element_callback = cat,
			 model = "gpt-3.5-turbo",
			 openai_api_key = Sys.getenv("OPENAI_API_KEY")) {
		# Set the API endpoint URL
		url <- "https://api.openai.com/v1/chat/completions"
		
		# Set the request headers
		headers <- list(
			"Content-Type" = "application/json",
			"Authorization" = paste0("Bearer ", openai_api_key)
		)
		
		# Set the request body
		body <- list(
			"model" = model,
			"stream" = TRUE,
			"messages" = messages
		)
		
		# Create a new curl handle object
		handle <- curl::new_handle() %>%
			curl::handle_setheaders(.list = headers) %>%
			curl::handle_setopt(postfields = jsonlite::toJSON(body, auto_unbox = TRUE)) # request body
		
		# Make the streaming request using curl_fetch_stream()
		curl::curl_fetch_stream(
			url = url,
			fun = function(x) {
				element <- rawToChar(x)
				element_callback(element) # Do whatever element_callback does
			},
			handle = handle
		)
	}

parser <- SSEParser$new()
stream_chat_completion(
	messages = list(
		list(role = "user", content = "What is 1 + 1")
	),
	element_callback = parser$parse_sse
)
parser$events |> 
	purrr::map("data") |> 
	purrr::discard(~.x == "[DONE]") |> 
	purrr::map(~{
		.x |> 
			jsonlite::fromJSON(simplifyDataFrame = FALSE) |> 
			purrr::pluck("choices", 1L, "delta", "content")
	}) |> 
	purrr::reduce(paste0, .init = "")
