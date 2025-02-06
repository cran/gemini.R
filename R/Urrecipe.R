# library(gemini.R)
# library(httr2)
# library(quarto)
#
# AUDIO_PATH <- "/Users/jinhwan/Documents/pp/esn.mp3"
# videoid <- 'kwluOT_Sp2I'
# Urrecipe <- function(AUDIO_PATH = NULL, videoid = NULL){
#   if(is.null(AUDIO_PATH)){
#     stop("Please provide the path to the audio file.")
#   }
#
#   if(is.null(videoid)){
#     stop("Please provide the youtube videoid.")
#   }
#
#   api_key <- Sys.getenv("GEMINI_API_KEY")
#
#   # FILE UPLOAD
#   BASE_URL <- "https://generativelanguage.googleapis.com/upload/v1beta/files" # Google API 기본 URL
#   # MIME_TYPE <- system(paste("file --mime-type -b", shQuote(AUDIO_PATH)), intern = TRUE) # audio/mpeg
#   MIME_TYPE <- "audio/mpeg" # for mp3
#   NUM_BYTES <- file.info(AUDIO_PATH)$size # 5843564
#   DISPLAY_NAME <- "AUDIO"
#
#   resumable_request <-
#     request(BASE_URL) |>
#     req_url_query(key = api_key) |>
#     req_method("POST") |>
#     req_headers(
#       "X-Goog-Upload-Protocol" = "resumable",
#       "X-Goog-Upload-Command" = "start",
#       "X-Goog-Upload-Header-Content-Length" = as.character(NUM_BYTES),
#       "X-Goog-Upload-Header-Content-Type" = MIME_TYPE,
#       "Content-Type" = "application/json"
#     ) |>
#     req_body_json(list(
#       file = list(display_name = DISPLAY_NAME)
#     ))
#
#   # 요청 전송 및 응답 처리
#   response <- resumable_request |>
#     req_perform()
#
#   if(response$status_code!=200){
#     stop("Error in resumable request")
#   }
#
#   upload_url <- resp_header(response, "X-Goog-Upload-URL")
#   upload_response <- request(upload_url) |>
#     req_method("POST") |>
#     req_headers(
#       `Content-Length` = as.character(NUM_BYTES),
#       `X-Goog-Upload-Offset` = "0",
#       `X-Goog-Upload-Command` = "upload, finalize"
#     ) |>
#     req_body_file(AUDIO_PATH) |> # 바이너리 데이터 업로드
#     req_perform()
#
#   if(response$status_code!=200){
#     stop("Error in upload request")
#   }
#
#   file_info <- upload_response |>
#     resp_body_json()
#   file_uri <- file_info$file$uri
#
#   ##
#
#   model_query <- paste0("gemini-", "1.5-flash", "-latest:generateContent")
#   url <- paste0("https://generativelanguage.googleapis.com/v1beta/models/", model_query)
#
#   generate_response <- request(url) |>
#     req_url_query(key = api_key) |>
#     req_method("POST") |>
#     req_headers("Content-Type" = "application/json") |>
#     req_body_json(list(
#       contents = list(
#         parts = list(
#           list(text = "
#              - Organize the recipes introduced in the audio in order.
#              - For each step, list the ingredients used and how to cook them.
#              - Starts with the first step, do not introduce answer it self.
#              - Before every recipe start, summarize all ingredients included in recipe
#              - After recipe finished, summarize possible allergy with those: egg, milk, soy, buckwheat, wheat, crab, shrimp, peanut, walnut, pine nuts, mackerel, ham, squid, clam, chicken, pork, beef
#              - If instruction or ingredient are not available, skip that recipe.
#              - Result should be format like:
#                 ## (NAME of FOOD) ...
#                 - Ingredients: ...
#                 - Instructions:
#                   1. ...
#                   2. ...
#                   ...
#                 - Possible allergy: ...
#             "),
#           list(file_data = list(mime_type = "audio/mpeg", file_uri = file_uri))
#         )
#       )
#     )) |>
#     req_perform()
#
#   if(generate_response$status_code!=200){
#     stop("Error in generate request")
#   }
#
#   response_json <- generate_response |>
#     resp_body_json()
#
#   recipe <- response_json$candidates[[1]]$content$parts[[1]]$text
#
#   # split by \n and remove empty lines
#   recipe2 <- strsplit(recipe, '\n')[[1]]
#   recipe2 <- recipe2[recipe2!='']
#
#   # render quarto document
#   quarto::quarto_render(
#     input = 'inst/quarto/recipe.qmd',
#     quiet = TRUE, # hide log pandoc / metadata ...
#     execute_params = list(
#       recipe = paste0(recipe2, collapse = '\n'),
#       videoid = videoid
#     ), # pass parameters to quarto document
#   )
#
#   cli::cli_text('finished !')
# }
#
#
# library(shiny)
#
# ui <- fluidPage(
#   fileInput("file", "Choose an audio file", accept = '.mp3'),
#   textInput("videoid", "Enter the youtube videoid"),
#   downloadButton("download", "Download")
# )
#
# server <- function(input, output, session) {
#   output$download <- downloadHandler(
#     filename = function() {
#       paste0("recipe-", Sys.Date(), ".html")
#     },
#     content = function(file) {
#
#       AUDIO_PATH <- input$file$datapath
#       videoid <- input$videoid
#       print('start !')
#       Urrecipe(AUDIO_PATH, videoid)
#       print('finished !')
#       file.copy("inst/quarto/recipe.html", file)
#     }
#   )
#
# }
#
# shinyApp(ui, server)
