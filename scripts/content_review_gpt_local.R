library(ellmer)
library(readr)
library(fs)

# Set credentials
# Sys.setenv(ELLMER_API_KEY = "insert_your_key")

# Get API key
api_key <- Sys.getenv("OPENAI_API_KEY")

# Function to get all .qmd files from a local directory
get_local_qmd_files <- function(folder_path) {
  # Convert ~ to home directory
  folder_path <- path_expand(folder_path)
  
  # Get all .qmd files
  qmd_files <- dir_ls(folder_path, regexp = "\\.qmd$")
  
  # Return list of file paths and names
  list(
    paths = qmd_files,
    names = path_file(qmd_files)
  )
}

# Function to read .qmd file content
read_qmd_content <- function(file_paths) {
  sapply(file_paths, function(path) {
    read_file(path)
  })
}

# Set up GPT prompts
system_prompt <- "You are a content reviewer specializing in technical documentation. Your task is to identify typos and ambiguities in the provided content. Provide your feedback in a clear, bullet-point format."

user_prompt_template <- "Please review the following .qmd teaching content and output an edited, improved version. 
Pay particular attention to:
1. Any typos or grammatical errors
2. Any ambiguous statements or unclear explanations
3. Any technical inconsistencies

Note that there are some placeholders for learners to input their answers.

Content to review:
"

# Get list of .qmd files from local directory
folder_path <- "~/Documents/GitHub/epiverse-trace/tutorials/instructors/" # Default path, can be changed
qmd_files_info <- get_local_qmd_files(folder_path)

# Read .qmd file contents
qmd_contents <- read_qmd_content(qmd_files_info$paths)

# Create output directory
output_dir <- paste0(folder_path,"content_reviews")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Process each file
for (ii in seq_along(qmd_contents)) {
  # Define variables
  tutorial_name <- sub("\\.qmd$", "", qmd_files_info$names[ii])
  tutorial_content <- qmd_contents[ii]
  
  # Create user prompt
  user_prompt <- paste0(user_prompt_template, tutorial_content)
  
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
    file.path(output_dir, paste0("review_", tutorial_name, ".md"))
  )
  
  # Print progress
  cat("Processed:", tutorial_name, "\n")
}





