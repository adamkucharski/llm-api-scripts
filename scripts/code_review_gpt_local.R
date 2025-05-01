library(ellmer)
library(readr)
library(fs)
library(officer)
library(stringr)
library(purrr)


# Set up local paths and keys ---------------------------------------------
api_key <- Sys.getenv("OPENAI_API_KEY")
folder_path <- "~/Dropbox/LSHTM/TRACE_project/Training/practicals_2025_04_16/"

# Set up file names -------------------------------------------------------
file_names <- c("01-practical-early",
                "02-practical-delays",
                "03-practical-chains",
                "04-practical-late"
                )

file_ii <- 3
git_url <- "https://raw.githubusercontent.com/epiverse-trace/tutorials/add-practicals-sc/instructors/"

# Create output directory
output_dir <- paste0(folder_path,"content_reviews")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Define matching between code chunks -------------------------------------
# NOTE: Add for 1,2,4
learner_pick <-  list(c(1),c(1),c(1,2))
solution_pick <- list(c(1),c(1),c(1,3))

# Extract main solutions --------------------------------------------------

# Read the Markdown file
md_lines <- readLines(paste0(git_url,file_names[file_ii],".md"))

# Identify lines with triple backticks
tick_lines <- which(str_detect(md_lines, "^```"))

# Ensure even number of backtick lines for pairing
if (length(tick_lines) %% 2 != 0) stop("Unmatched code block delimiters found.")

# Pair start and end of each code block
code_chunks_solution <- map2(
  tick_lines[seq(1, length(tick_lines), by = 2)],
  tick_lines[seq(2, length(tick_lines), by = 2)],
  function(start, end) md_lines[(start + 1):(end - 1)]
)


# Extract word content ----------------------------------------------------

# Load the Word document
doc <- read_docx(paste0(folder_path,file_names[file_ii],".docx"))

# Extract text from the Word document
doc_text <- docx_summary(doc)$text

# Identify positions of "Code chunk" headers
code_starts <- which(str_detect(doc_text, "^Code chunk"))

# Identify lines that are likely R code based on indentation or presence of R syntax
is_r_code_line <- function(line) {
  str_detect(line, "^\\s*#|^\\s*library\\(|<-|\\|>|%>%|^\\s*\\w+\\s*<-|^\\s*\\w+\\s*\\(|\\(|\\)|\\{|\\}")
}

# Extract all code blocks following "Code chunk" markers
extract_code_chunks <- function(text, starts) {
  map(starts, function(start) {
    chunk <- character()
    for (i in (start + 1):length(text)) {
      line <- text[i]
      if (line == "" || str_detect(line, "^\\S") && !is_r_code_line(line)) break
      chunk <- c(chunk, line)
    }
    paste(chunk, collapse = "\n")
  })
}

# Run extraction
code_chunks_learner <- extract_code_chunks(doc_text, code_starts)



# Match code entries ------------------------------------------------------

code_learner_ii <- paste(unlist(code_chunks_learner[learner_pick[[file_ii]]]), collapse = "\n")
code_solution_ii <- paste(unlist(code_chunks[solution_pick[[file_ii]]]), collapse = "\n")



# Run GPT comparison ------------------------------------------------------

# Set up GPT prompts
system_prompt <- "You are a teacher specialised in outbreak analysis and modelling in R. 
Your task is to identify errors, ambiguities, inconsistencies and bad practice in the provided content. 
Provide your feedback in a clear, bullet-point format."

user_prompt_template <- "Please review the following code chunk from a student and compare with the 
correct solution code. Output a summary list of personalised feedback.
Pay particular attention to:
1. Any major mismatches with the solution code
2. Any ambiguous statements or unclear explanations
3. Any technical inconsistencies or bad practice
4. Any epidemiological inaccuracies or imprecision
5. Broad feedback on how efficiency and stability of code could be improve

Use a neutral but constructive and supportive tone. Address the response directly to the student, 
i.e. 'you' and 'your code'. But you don't have to open or close with formalities like 'Dear Student'.
Also avoid simulated personal statements like 'I appreciate your effort' - it should focus on content.
"

# Create user prompt
user_prompt <- paste0(user_prompt_template, 
                      "\n\nStudent's code:\n\n", code_learner_ii,
                      "\n\nSolution code:\n\n", code_solution_ii)

# Call GPT via ellmer
set_chat <- chat_openai(
  model = "gpt-4o-mini",
  system_prompt = system_prompt,
  api_args = list(temperature = 0,
                  max_tokens = 5000),
  api_key = api_key,
  echo = "none"
)

out <- set_chat$chat(user_prompt)

# Write review to file
write_lines(
  out,
  file.path(output_dir, paste0("review_", file_ii, ".md"))
)

# Print progress
cat("Processed:", file_ii, "\n")





