test_that("Empty event should not change self$events", {
	SSEparser_instance <- SSEparser$new()
	event <- ""
	SSEparser_instance$parse_sse(event)
	expect_length(SSEparser_instance$events, 0)
})

test_that("Event with empty lines should add events to self$events", {
	SSEparser_instance <- SSEparser$new()
	event <- "data: test\n\n\ndata: example\n\n"
	SSEparser_instance$parse_sse(event)
	expect_length(SSEparser_instance$events, 2)
})

test_that("Event with comment lines should ignore comment lines", {
	SSEparser_instance <- SSEparser$new()
	event <- "data: test\n: comment\n\ndata: example\n\n"
	SSEparser_instance$parse_sse(event)
	expect_length(SSEparser_instance$events[[1]], 1)
	expect_length(SSEparser_instance$events[[2]], 1)
})

test_that("Event with valid fields should add events to self$events", {
	SSEparser_instance <- SSEparser$new()
	event <- "data: test\nevent: message\nid: 123\n\n"
	SSEparser_instance$parse_sse(event)
	expect_length(SSEparser_instance$events, 1)
	expect_length(SSEparser_instance$events[[1]], 3)
	# Add more specific expectations if needed
})

test_that("Event with empty field value should handle it properly", {
	SSEparser_instance <- SSEparser$new()
	event <- "data: test\nevent: \n\n"
	SSEparser_instance$parse_sse(event)
	expect_length(SSEparser_instance$events, 1)
	# Add more specific expectations if needed
})

test_that("Event with leading space in value should trim it", {
	SSEparser_instance <- SSEparser$new()
	event <- "data: test\nevent: message\nid: 123\nvalue:  leading space\n\n"
	SSEparser_instance$parse_sse(event)
	expect_length(SSEparser_instance$events, 1)
	expect_equal(SSEparser_instance$events[[1]]$value, "leading space")
	# Add more specific expectations if needed
})

test_that("Event with colon in field value should handle it properly", {
	SSEparser_instance <- SSEparser$new()
	event <- "data: test\nevent: message\nid: 123\ndata: value:with:colons\n\n"
	SSEparser_instance$parse_sse(event)
	expect_length(SSEparser_instance$events, 1)
	expect_length(SSEparser_instance$events[[1]], 4)
	expect_named(SSEparser_instance$events[[1]], c("data", "event", "id", "data"))
	# Add more specific expectations if needed
})

test_that("Event with lines starting with colon should handle it properly", {
	SSEparser_instance <- SSEparser$new()
	event <- "data: test\n: comment\n:event: message\n\n"
	SSEparser_instance$parse_sse(event)
	expect_length(SSEparser_instance$events, 1)
	expect_length(SSEparser_instance$events[[1]], 1)
	# Add more specific expectations if needed
})

test_that("Multiple chunks in a single event should be processed", {
	SSEparser_instance <- SSEparser$new()
	event <- "data: chunk1\n\ndata: chunk2\n\n"
	SSEparser_instance$parse_sse(event)
	expect_length(SSEparser_instance$events, 2)
	# Add more specific expectations if needed
})

test_that("Complex event with multiple fields should be processed", {
	SSEparser_instance <- SSEparser$new()
	event <- "data: test\nevent: message\nid: 123\ndata: value\n: comment\n\n"
	SSEparser_instance$parse_sse(event)
	expect_length(SSEparser_instance$events, 1)
	# Add more specific expectations if needed
})

# Clean up after tests if needed
