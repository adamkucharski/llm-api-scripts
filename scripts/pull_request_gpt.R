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

# Fetch pull request comments
pr_comments <- gh::gh(
  "GET /repos/:owner/:repo/pulls/:pull_number/comments",
  owner = strsplit(owner_repo, "/")[[1]][1],
  repo = strsplit(owner_repo, "/")[[1]][2],
  pull_number = pull_number
)

# Fetch review comments on the pull request
pr_review_comments <- gh::gh(
  "GET /repos/:owner/:repo/pulls/:pull_number/reviews",
  owner = strsplit(owner_repo, "/")[[1]][1],
  repo = strsplit(owner_repo, "/")[[1]][2],
  pull_number = pull_number
)

# Extract comment text and author
extract_comment_and_author <- function(comment) {
  sprintf("%s: %s", comment$user$login, comment$body)
}

# Extract comments and authors from pull request comments
extracted_pr_comments <- sapply(pr_comments, extract_comment_and_author)
extracted_pr_review_comments <- sapply(pr_review_comments, extract_comment_and_author)

# Combine both types of comments
all_comments <- list(extracted_pr_comments, extracted_pr_review_comments)

# Combine all comments into string
all_comments_string <- paste(all_comments, collapse = "\n")

# Set up GPT prompt and run model
user_prompt <- "Summarise the below GitHub pull request comments and reviews, and output in markdown format. 
Briefly explain who made suggestions, what the conclusion was, and any actions resulting."

llm_completion <- create_chat_completion(
  model = "gpt-4", #gpt-3.5-turbo-0125
  messages = list(list("role"="user","content" = paste0(user_prompt,all_comments_string))
  ),
  temperature = 0.1, # level of randomness in response
  openai_api_key = openai_api_key,
  max_tokens = 800 # number of tokens (and hence $) used
)

llm_completion_content <- llm_completion$choices$message.content

# Write markdown file
write_lines(llm_completion_content,"llm_output.md")

