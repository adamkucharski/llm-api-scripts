library(gh)
library(openai)
library(readr)

# Set credentials
# Sys.setenv(GITHUB_PAT = "GITHUB_PAT")
# Sys.setenv(OPENAI_API_KEY = "insert_your_key")

openai_api_key <- Sys.getenv("OPENAI_API_KEY")

# Define repo and PR number
owner_repo <- "epiverse-trace/simulist"
pull_number <- 73 

# Fetch files changed in the pull request
pr_changed_files <- gh::gh(
  "GET /repos/:owner/:repo/pulls/:pull_number/files",
  owner = strsplit(owner_repo, "/")[[1]][1],
  repo = strsplit(owner_repo, "/")[[1]][2],
  pull_number = pull_number
)

# Extract filename and changes summary
# extract_file_changes <- function(file) {
#   sprintf("File: %s, Additions: %d, Deletions: %d", file$filename, file$additions, file$deletions)
# }
# 
# # Extract changes from PR changed files
# extracted_file_changes <- sapply(pr_changed_files, extract_file_changes)

# Combine all file changes into string
all_file_changes_string <- paste(pr_changed_files, collapse = "\n")

# Set up GPT prompt for expert review and run model
review_prompt <- "You are an expert epidemiologist and research software engineer who builds R packages for outbreak analysis.
Provide an expert review on the following changes made in a GitHub pull request. 
Highlight the significance of each change, suggest potential improvements, and summarise the overall impact on the project."

llm_completion <- create_chat_completion(
  model = "gpt-4-0125-preview", # Adjust model as necessary
  messages = list(list("role"="user","content" = paste0(review_prompt, all_file_changes_string))),
  temperature = 0.7, # Adjust for creativity in response
  openai_api_key = openai_api_key,
  max_tokens = 1000 # Adjust based on expected output length
)

llm_completion_content <- llm_completion$choices[[1]]$message$content

# Write markdown file with the review
writeLines(llm_completion_content, paste0("outputs/review_output_",owner_repo,"_",pull_number,".md"))

